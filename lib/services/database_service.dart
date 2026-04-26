import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intro_mobile_flutter/apparaat.dart';
import 'package:intro_mobile_flutter/huuraanvraag.dart';

class DatabaseService {
  // Een vaste referentie naar Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  // Huuraanvraag indienen
  Future<void> voegHuuraanvraagToe(Huuraanvraag aanvraag) async {
    await _db.collection('huuraanvragen').add(aanvraag.toMap());
  }

  // Aanvragen waarbij ik de huurder ben
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

  // Aanvragen waarbij ik de verhuurder ben
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

  // Bestaande reserveringen voor een apparaat (voor overlap-check)
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
  }
}
