import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intro_mobile_flutter/apparaat.dart'; 
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  // Een vaste referentie naar Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Haal de live-stream van alle apparaten op
  Stream<List<Apparaat>> getApparatenStream() {
    return _db.collection('apparaten').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Apparaat.fromFirestore(
          doc.id, 
          doc.data() as Map<String, dynamic>
        );
      }).toList();
    });
  }

  Future<void> voegApparaatToe(Apparaat apparaat) async {
    await _db.collection('apparaten').add(apparaat.toMap());
  }

  // --- NIEUW: Functie om de foto te uploaden en de link terug te geven ---
  Future<String> uploadFoto(XFile foto) async {
    String uniekeNaam = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';

    Reference opslagPlek = _storage.ref().child('apparaat_fotos').child(uniekeNaam);

    await opslagPlek.putData(await foto.readAsBytes());

    String downloadUrl = await opslagPlek.getDownloadURL();
    return downloadUrl;
  }
}