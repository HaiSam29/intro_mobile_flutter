import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intro_mobile_flutter/apparaat.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intro_mobile_flutter/entities/gebruiker.dart';
import 'package:intro_mobile_flutter/huuraanvraag.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> slaNieuwAdresOpInProfiel(String uid, String nieuwAdres) async {
    await _db.collection('users').doc(uid).set({
      'adres': nieuwAdres,
    }, SetOptions(merge: true));
  }

  Future<void> maakGebruikerProfielAan({
    required String uid,
    required String naam,
    required String email,
    String? adres,
  }) async {
    await _db.collection('users').doc(uid).set({
      'naam': naam,
      'email': email,
      'adres': adres,
      'aangemaaktOp': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> haalGebruikerAdresOp(String uid) async {
    DocumentSnapshot docSnap = await _db.collection('users').doc(uid).get();

    if (docSnap.exists) {
      final data = docSnap.data() as Map<String, dynamic>?;
      return data?['adres'] as String?;
    }

    return null;
  }

  Future<void> updateGebruiker(Gebruiker gebruiker) async {
    await _db.collection('users').doc(gebruiker.uid).set({
      'naam': gebruiker.naam,
      'email': gebruiker.email,
      'adres': gebruiker.adres,
    }, SetOptions(merge: true));
  }

  Future<Gebruiker?> haalGebruikerGegevensOp(String uid) async {
    DocumentSnapshot docSnap = await _db.collection('users').doc(uid).get();

    if (docSnap.exists) {
      final data = docSnap.data() as Map<String, dynamic>;
      return Gebruiker.fromMap(uid, data);
    }

    return null;
  }

  Stream<List<Apparaat>> getApparatenStream() {
    return _db.collection('apparaten').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Apparaat.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  Stream<List<Apparaat>> getMijnApparatenStream(String userId) {
    return _db
        .collection('apparaten')
        .where('eigenaar', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Apparaat.fromFirestore(doc.id, doc.data());
          }).toList();
        });
  }

  Future<void> voegApparaatToe(Apparaat apparaat) async {
    await _db.collection('apparaten').add(apparaat.toMap());
  }

  Future<void> updateApparaat(Apparaat apparaat) async {
    await _db.collection('apparaten').doc(apparaat.id).update(apparaat.toMap());

    final aanvragenSnap = await _db
        .collection('huuraanvragen')
        .where('apparaatId', isEqualTo: apparaat.id)
        .get();

    final batch = _db.batch();
    for (final doc in aanvragenSnap.docs) {
      batch.update(doc.reference, {
        'apparaatNaam': apparaat.naam,
        'apparaatImageUrl': apparaat.imageUrl,
        'prijsPerDag': apparaat.prijsPerDag,
      });
    }
    await batch.commit();
  }

  Future<void> verwijderApparaat(String apparaatId) async {
    final aanvragenSnap = await _db
        .collection('huuraanvragen')
        .where('apparaatId', isEqualTo: apparaatId)
        .where(
          'status',
          whereIn: [
            HuurStatus.in_behandeling.name,
            HuurStatus.geaccepteerd.name,
          ],
        )
        .get();

    final batch = _db.batch();
    for (final doc in aanvragenSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('apparaten').doc(apparaatId));
    await batch.commit();
  }

  // --- Jouw uploadFoto functie ---
  Future<String> uploadFoto(XFile foto) async {
    String uniekeNaam =
        DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';

    Reference opslagPlek = _storage
        .ref()
        .child('apparaat_fotos')
        .child(uniekeNaam);

    await opslagPlek.putData(await foto.readAsBytes());

    String downloadUrl = await opslagPlek.getDownloadURL();
    return downloadUrl;
  }

  // --- De Huuraanvraag functies van je vriend ---
  Future<void> voegHuuraanvraagToe(Huuraanvraag aanvraag) async {
    await _db.collection('huuraanvragen').add(aanvraag.toMap());
  }

  Stream<List<Huuraanvraag>> getMijnHuurStream(String userId) {
    return _db
        .collection('huuraanvragen')
        .where('huurder', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Huuraanvraag.fromFirestore(doc.id, doc.data());
          }).toList();
        });
  }

  Stream<List<Huuraanvraag>> getMijnVerhuurStream(String userId) {
    return _db
        .collection('huuraanvragen')
        .where('verhuurder', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Huuraanvraag.fromFirestore(doc.id, doc.data());
          }).toList();
        });
  }

  Stream<List<Huuraanvraag>> getReserveringenVoorApparaat(String apparaatId) {
    return _db
        .collection('huuraanvragen')
        .where('apparaatId', isEqualTo: apparaatId)
        .where('status', whereIn: ['geaccepteerd', 'lopend'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Huuraanvraag.fromFirestore(doc.id, doc.data());
          }).toList();
        });
  }

  // Status veranderen (Accepteren/Weigeren)
  Future<void> updateHuurStatus(
    String aanvraagId,
    HuurStatus nieuweStatus,
  ) async {
    await _db.collection('huuraanvragen').doc(aanvraagId).update({
      'status': nieuweStatus.name,
    });

    if (nieuweStatus == HuurStatus.geaccepteerd) {
      final doc = await _db.collection('huuraanvragen').doc(aanvraagId).get();
      if (!doc.exists) return;
      final geaccepteerd = Huuraanvraag.fromFirestore(doc.id, doc.data()!);

      final overlappend = await _db
          .collection('huuraanvragen')
          .where('apparaatId', isEqualTo: geaccepteerd.apparaatId)
          .where('status', isEqualTo: HuurStatus.in_behandeling.name)
          .get();

      for (final ander in overlappend.docs) {
        if (ander.id == aanvraagId) continue;
        final aanvraag = Huuraanvraag.fromFirestore(ander.id, ander.data());
        final heeftOverlap =
            !aanvraag.startDatum.isAfter(geaccepteerd.eindDatum) &&
            !aanvraag.eindDatum.isBefore(geaccepteerd.startDatum);
        if (heeftOverlap) {
          await ander.reference.update({'status': HuurStatus.geweigerd.name});
        }
      }
    }
  }
}
