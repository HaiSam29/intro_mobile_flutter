class Apparaat {
  final String id;
  final String naam;
  final String eigenaar;
  final double prijsPerDag;
  final String categorie;
  final double afstandKm;
  final String afbeelding;

  Apparaat({
    required this.id,
    required this.naam,
    required this.eigenaar,
    required this.prijsPerDag,
    required this.categorie,
    required this.afstandKm,
    required this.afbeelding,
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
    afbeelding: 'https://tuinwebshop.be/wp-content/uploads/2020/03/60-volt-accu-grasmaaier-gd60lm51sp.jpg',
  ),
  Apparaat(
    id: '2',
    naam: 'Ladder',
    eigenaar: 'Henk',
    prijsPerDag: 10.00,
    categorie: 'Gereedschap',
    afstandKm: 1.5,
    afbeelding: 'https://www.badgerladder.com/wp-content/uploads/magictoolbox_cache/ad391aebc1f9913654f3f7c70f89e9ae/5/9/590/original/1160400600/type-1aa-extra-heavy-duty-fiberglass-double-step-ladder-375-pound-capacity-1.jpg',
  ),
  Apparaat(
    id: '3',
    naam: 'Stofzuiger',
    eigenaar: 'Lisa',
    prijsPerDag: 8.00,
    categorie: 'Schoonmaak',
    afstandKm: 0.8,
    afbeelding: 'https://static.gamma.be/dam/574691/123',
  ),
  Apparaat(
    id: '4',
    naam: 'Keukenmixer',
    eigenaar: 'Tom',
    prijsPerDag: 5.00,
    categorie: 'Keuken',
    afstandKm: 2.1,
    afbeelding: 'https://www.like2cook.nl/media/catalog/product/cache/3243bb42d756c8fd12c0aea11994f95b/5/k/5ksm175pser_r_2.webp',
  ),
];
