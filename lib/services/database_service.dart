import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intro_mobile_flutter/apparaat.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intro_mobile_flutter/entities/gebruiker.dart';

class DatabaseService {
  // Een vaste referentie naar Firestore
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

  // Functie om het adres van een specifieke gebruiker op te halen
  Future<String?> haalGebruikerAdresOp(String uid) async {
    DocumentSnapshot docSnap = await _db.collection('users').doc(uid).get();

    // 2. Controleer of het document bestaat en of het veld 'adres' erin zit
    if (docSnap.exists) {
      final data = docSnap.data() as Map<String, dynamic>?;
      return data?['adres'] as String?;
    }

    // 3. Als er niks is gevonden, geef leeg (null) terug
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

    // 2. Controleer of het document bestaat en of het veld 'adres' erin zit
    if (docSnap.exists) {
      final data = docSnap.data() as Map<String, dynamic>;
      return Gebruiker.fromMap(uid, data);
    }

    // 3. Als er niks is gevonden, geef leeg (null) terug
    return null;
  }

  // Haal de live-stream van alle apparaten op
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

  Future<void> voegApparaatToe(Apparaat apparaat) async {
    await _db.collection('apparaten').add(apparaat.toMap());
  }

  // --- NIEUW: Functie om de foto te uploaden en de link terug te geven ---
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
}
