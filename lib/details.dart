import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // NIEUW: Import voor Google Maps
import 'package:intro_mobile_flutter/apparaat.dart';
import 'package:intro_mobile_flutter/huuraanvraag.dart';
import 'package:intro_mobile_flutter/services/database_service.dart';

class DetailsScherm extends StatelessWidget {
  final Apparaat apparaat;

  const DetailsScherm({super.key, required this.apparaat});

  @override
  Widget build(BuildContext context) {
    final huidigeUid = FirebaseAuth.instance.currentUser?.uid;
    final isEigenaar = huidigeUid == apparaat.eigenaar;
    
    // NIEUW: Haal de opgeslagen coördinaten van het apparaat op
    final apparaatLocatie = LatLng(apparaat.locatie.latitude, apparaat.locatie.longitude);

    return Scaffold(
      appBar: AppBar(title: Text(apparaat.naam)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                apparaat.imageUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            if (!isEigenaar)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ReserveerDialog(apparaat: apparaat),
                    );
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Reserveer'),
                ),
              ),

            const SizedBox(height: 16),

            Text(
              apparaat.naam,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              '€${apparaat.prijsPerDag} / dag',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.category, size: 18),
                const SizedBox(width: 6),
                Text('Categorie: ${apparaat.categorie.name}'),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.location_on, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(apparaat.locatie.adres)),
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 6),
                Text('Eigenaar: ${apparaat.eigenaarNaam}'),
              ],
            ),

            const Divider(height: 32),

            // NIEUW: De Google Map widget in het detailscherm
            const Text(
              'Ophaallocatie',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (apparaat.locatie.latitude != 0.0)
              SizedBox(
                height: 200,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: apparaatLocatie,
                      zoom: 14,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId(apparaat.id),
                        position: apparaatLocatie,
                      ),
                    },
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),
              )
            else
              const Text('Geen exacte locatie beschikbaar voor dit apparaat.', style: TextStyle(color: Colors.grey)),

            const Divider(height: 32),

            const Text(
              'Beschrijving',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(apparaat.beschrijving),
          ],
        ),
      ),
    );
  }
}

class ReserveerDialog extends StatefulWidget {
  final Apparaat apparaat;

  const ReserveerDialog({super.key, required this.apparaat});

  @override
  State<ReserveerDialog> createState() => _ReserveerDialogState();
}

class _ReserveerDialogState extends State<ReserveerDialog> {
  DateTime? _startDatum;
  DateTime? _eindDatum;
  bool _isBezig = false;

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _kiesStart() async {
    final gekozen = await showDatePicker(
      context: context,
      initialDate: _startDatum ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (gekozen != null) {
      setState(() {
        _startDatum = gekozen;
        if (_eindDatum != null && _eindDatum!.isBefore(gekozen)) {
          _eindDatum = null;
        }
      });
    }
  }

  Future<void> _kiesEind() async {
    final gekozen = await showDatePicker(
      context: context,
      initialDate: _eindDatum ?? _startDatum ?? DateTime.now(),
      firstDate: _startDatum ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (gekozen != null) {
      setState(() => _eindDatum = gekozen);
    }
  }

  bool _overlaptMet(List<Huuraanvraag> bestaande) {
    for (final r in bestaande) {
      if (!_eindDatum!.isBefore(r.startDatum) &&
          !_startDatum!.isAfter(r.eindDatum)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _bevestig(List<Huuraanvraag> bestaande) async {
    if (_startDatum == null || _eindDatum == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kies een start- en einddatum.')),
      );
      return;
    }
    if (_overlaptMet(bestaande)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deze periode overlapt met een bestaande reservering.'),
        ),
      );
      return;
    }

    setState(() => _isBezig = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final aanvraag = Huuraanvraag(
        id: '',
        apparaatId: widget.apparaat.id,
        apparaatNaam: widget.apparaat.naam,
        apparaatImageUrl: widget.apparaat.imageUrl,
        prijsPerDag: widget.apparaat.prijsPerDag,
        huurder: user.uid,
        huurderNaam: user.displayName ?? 'Onbekend',
        verhuurder: widget.apparaat.eigenaar,
        verhuurderNaam: widget.apparaat.eigenaarNaam,
        startDatum: _startDatum!,
        eindDatum: _eindDatum!,
        status: HuurStatus.in_behandeling,
        aangemaakt: DateTime.now(),
      );
      await DatabaseService().voegHuuraanvraagToe(aanvraag);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aanvraag verstuurd!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Er ging iets mis: $e')));
    } finally {
      if (mounted) setState(() => _isBezig = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reserveer ${widget.apparaat.naam}'),
      content: StreamBuilder<List<Huuraanvraag>>(
        stream: DatabaseService().getReserveringenVoorApparaat(
          widget.apparaat.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final bestaande = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Reeds gereserveerd:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (bestaande.isEmpty)
                  const Text('Geen reserveringen.')
                else
                  ...bestaande.map(
                    (r) => Text(
                      '• ${_formatDate(r.startDatum)} - ${_formatDate(r.eindDatum)}',
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Vanaf: '),
                    TextButton(
                      onPressed: _kiesStart,
                      child: Text(
                        _startDatum == null
                            ? 'Kies datum'
                            : _formatDate(_startDatum!),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Tot:    '),
                    TextButton(
                      onPressed: _startDatum == null ? null : _kiesEind,
                      child: Text(
                        _eindDatum == null
                            ? 'Kies datum'
                            : _formatDate(_eindDatum!),
                      ),
                    ),
                  ],
                ),
                if (_startDatum != null && _eindDatum != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Totaal: €${(widget.apparaat.prijsPerDag * (_eindDatum!.difference(_startDatum!).inDays + 1)).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isBezig
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Annuleer'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isBezig ? null : () => _bevestig(bestaande),
                      child: _isBezig
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Bevestigen'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}