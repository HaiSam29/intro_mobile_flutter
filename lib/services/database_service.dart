import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intro_mobile_flutter/apparaat.dart';

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
}
