enum Categorie { keuken, tuin, gereedschap, schoonmaak }

class Apparaat {
  final String id;
  final String naam;
  final String imageUrl;
  final String eigenaar;
  final String eigenaarNaam;
  final String beschrijving;
  final double prijsPerDag;
  final Categorie categorie;
  final Locatie locatie;

  Apparaat({
    required this.id,
    required this.naam,
    required this.imageUrl,
    required this.eigenaar,
    required this.eigenaarNaam,
    required this.beschrijving,
    required this.prijsPerDag,
    required this.categorie,
    required this.locatie,
  });

  Map<String, dynamic> toMap() {
    return {
      'naam': naam,
      'beschrijving': beschrijving,
      'imageUrl': imageUrl,
      'eigenaar': eigenaar,
      'eigenaarNaam': eigenaarNaam,
      'prijsPerDag': prijsPerDag,
      'categorie': categorie.name, // we slaan de naam van de Enum op in de DB
      'locatie': locatie.toMap(),
    };
  }

  factory Apparaat.fromFirestore(String id, Map<String, dynamic> data) {
    return Apparaat(
      id: id,
      naam: data['naam'] ?? '',
      beschrijving: data['beschrijving'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      eigenaar: data['eigenaar'] ?? '',
      eigenaarNaam: data['eigenaarNaam'] ?? 'Onbekend',
      prijsPerDag: (data['prijsPerDag'] ?? 0).toDouble(),
      // Vertaal de string uit de DB terug naar de Enum:
      categorie: Categorie.values.byName(data['categorie']),
      locatie: Locatie.fromMap(data['locatie']),
    );
  }
}

class Locatie {
  final double latitude;
  final double longitude;
  final String adres;

  Locatie({
    required this.latitude,
    required this.longitude,
    required this.adres,
  });

  Map<String, dynamic> toMap() {
    return {'latitude': latitude, 'longitude': longitude, 'adres': adres};
  }

  factory Locatie.fromMap(Map<String, dynamic> map) {
    return Locatie(
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      adres: map['adres'] ?? '',
    );
  }
}
