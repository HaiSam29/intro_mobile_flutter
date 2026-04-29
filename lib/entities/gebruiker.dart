class Gebruiker {
  final String uid;
  final String naam;
  final String email;
  final String? adres;

  Gebruiker({
    required this.uid,
    required this.naam,
    required this.email,
    this.adres,
  });

  factory Gebruiker.fromMap(String id, Map<String, dynamic> map) {
    return Gebruiker(
      uid: id,
      naam: map['naam'] ?? '',
      email: map['email'] ?? '',
      adres: map['adres'],
    );
  }
}
