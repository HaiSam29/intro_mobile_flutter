class Apparaat {
  final String id;
  final String naam;
  final String eigenaar;
  final double prijsPerDag;
  final String categorie;
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

// Dit is onze tijdelijke hardcoded array.
// Deze gebruiken we totdat we Firebase koppelen.
final List<Apparaat> dummyApparaten = [
  Apparaat(
    id: '1',
    naam: 'Grasmaaier',
    eigenaar: 'John',
    prijsPerDag: 12.00,
    categorie: 'Tuin',
    afstandKm: 0.5,
  ),
  Apparaat(
    id: '2',
    naam: 'Ladder',
    eigenaar: 'Henk',
    prijsPerDag: 10.00,
    categorie: 'Gereedschap',
    afstandKm: 1.5,
  ),
  Apparaat(
    id: '3',
    naam: 'Stofzuiger',
    eigenaar: 'Lisa',
    prijsPerDag: 8.00,
    categorie: 'Schoonmaak',
    afstandKm: 0.8,
  ),
  Apparaat(
    id: '4',
    naam: 'Keukenmixer',
    eigenaar: 'Tom',
    prijsPerDag: 5.00,
    categorie: 'Keuken',
    afstandKm: 2.1,
  ),
];
