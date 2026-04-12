enum Categorie { keuken, tuin, gereedschap, schoonmaak }

class Apparaat {
  final String id;
  final String naam;
  final String eigenaar;
  final double prijsPerDag;
  final Categorie categorie;
  final double afstandKm;

  Apparaat({
    required this.id,
    required this.naam,
    required this.eigenaar,
    required this.prijsPerDag,
    required this.categorie,
    required this.afstandKm,
  });
}

// Dummy data om te testen. Later vervangen door echte data uit een database of API.
final List<Apparaat> dummyApparaten = [
  Apparaat(
    id: '1',
    naam: 'Grasmaaier',
    eigenaar: 'John',
    prijsPerDag: 12.00,
    categorie: Categorie.tuin,
    afstandKm: 0.5,
  ),
  Apparaat(
    id: '2',
    naam: 'Ladder',
    eigenaar: 'Henk',
    prijsPerDag: 10.00,
    categorie: Categorie.gereedschap,
    afstandKm: 1.5,
  ),
  Apparaat(
    id: '3',
    naam: 'Stofzuiger',
    eigenaar: 'Lisa',
    prijsPerDag: 8.00,
    categorie: Categorie.schoonmaak,
    afstandKm: 0.8,
  ),
  Apparaat(
    id: '4',
    naam: 'Keukenmixer',
    eigenaar: 'Tom',
    prijsPerDag: 5.00,
    categorie: Categorie.keuken,
    afstandKm: 2.1,
  ),
];
