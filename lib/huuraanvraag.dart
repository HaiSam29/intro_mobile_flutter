import 'package:cloud_firestore/cloud_firestore.dart';

enum HuurStatus { in_behandeling, geaccepteerd, geweigerd, lopend, afgerond }

class Huuraanvraag {
  final String id;
  final String apparaatId;
  final String apparaatNaam;
  final String apparaatImageUrl;
  final double prijsPerDag;
  final String huurder;
  final String huurderNaam;
  final String verhuurder;
  final String verhuurderNaam;
  final DateTime startDatum;
  final DateTime eindDatum;
  final HuurStatus status;
  final DateTime aangemaakt;

  Huuraanvraag({
    required this.id,
    required this.apparaatId,
    required this.apparaatNaam,
    required this.apparaatImageUrl,
    required this.prijsPerDag,
    required this.huurder,
    required this.huurderNaam,
    required this.verhuurder,
    required this.verhuurderNaam,
    required this.startDatum,
    required this.eindDatum,
    required this.status,
    required this.aangemaakt,
  });

  Map<String, dynamic> toMap() {
    return {
      'apparaatId': apparaatId,
      'apparaatNaam': apparaatNaam,
      'apparaatImageUrl': apparaatImageUrl,
      'prijsPerDag': prijsPerDag,
      'huurder': huurder,
      'huurderNaam': huurderNaam,
      'verhuurder': verhuurder,
      'verhuurderNaam': verhuurderNaam,
      'startDatum': Timestamp.fromDate(startDatum),
      'eindDatum': Timestamp.fromDate(eindDatum),
      'status': status.name,
      'aangemaakt': Timestamp.fromDate(aangemaakt),
    };
  }

  factory Huuraanvraag.fromFirestore(String id, Map<String, dynamic> data) {
    return Huuraanvraag(
      id: id,
      apparaatId: data['apparaatId'] ?? '',
      apparaatNaam: data['apparaatNaam'] ?? '',
      apparaatImageUrl: data['apparaatImageUrl'] ?? '',
      prijsPerDag: (data['prijsPerDag'] ?? 0).toDouble(),
      huurder: data['huurder'] ?? '',
      huurderNaam: data['huurderNaam'] ?? 'Onbekend',
      verhuurder: data['verhuurder'] ?? '',
      verhuurderNaam: data['verhuurderNaam'] ?? 'Onbekend',
      startDatum: (data['startDatum'] as Timestamp).toDate(),
      eindDatum: (data['eindDatum'] as Timestamp).toDate(),
      status: HuurStatus.values.byName(data['status'] ?? 'in_behandeling'),
      aangemaakt: (data['aangemaakt'] as Timestamp).toDate(),
    );
  }
}
