enum Categorie { keuken, tuin, gereedschap, schoonmaak }

class Apparaat {
  final String id;
  final String naam;
  final String imageUrl;
  final String eigenaar;
  final String beschrijving;
  final double prijsPerDag;
  final Categorie categorie;
  final Locatie locatie;

  Apparaat({
    required this.id,
    required this.naam,
    required this.imageUrl,
    required this.eigenaar,
    required this.beschrijving,
    required this.prijsPerDag,
    required this.categorie,
    required this.locatie,
  });
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
}

// Dummy data om te testen. Later vervangen door echte data uit een database of API.
final List<Apparaat> dummyApparaten = [
  Apparaat(
    id: '1',
    naam: 'Grasmaaier',
    eigenaar: 'John',
    beschrijving: "beschrijving",
    prijsPerDag: 12.00,
    categorie: Categorie.tuin,
    locatie: Locatie(latitude: 0, longitude: 0, adres: "adres"),
    imageUrl: "",
  ),
  Apparaat(
    id: '2',
    naam: 'Ladder',
    eigenaar: 'Henk',
    beschrijving: "beschrijving",
    prijsPerDag: 10.00,
    categorie: Categorie.gereedschap,
    locatie: Locatie(latitude: 0, longitude: 0, adres: "adres"),
    imageUrl: "",
  ),
  Apparaat(
    id: '3',
    naam: 'Stofzuiger',
    eigenaar: 'Lisa',
    beschrijving: "beschrijving",
    prijsPerDag: 8.00,
    categorie: Categorie.schoonmaak,
    locatie: Locatie(latitude: 0, longitude: 0, adres: "adres"),
    imageUrl: "",
  ),
  Apparaat(
    id: '4',
    naam: 'Keukenmixer',
    eigenaar: 'Tom',
    beschrijving: "beschrijving",
    prijsPerDag: 5.00,
    categorie: Categorie.keuken,
    locatie: Locatie(latitude: 0, longitude: 0, adres: "adres"),
    imageUrl: "",
  ),
];
