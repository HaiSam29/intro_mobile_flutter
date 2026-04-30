import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intro_mobile_flutter/apparaat.dart';
import 'package:intro_mobile_flutter/huuraanvraag.dart';
import 'package:intro_mobile_flutter/services/database_service.dart';
import 'package:intro_mobile_flutter/wijzigen.dart';

class MijnToestellenScherm extends StatelessWidget {
  const MijnToestellenScherm({super.key});

  Future<void> _verwijderApparaat(
    BuildContext context,
    Apparaat apparaat,
  ) async {
    final bevestigd = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Toestel verwijderen?'),
        content: Text(
          'Weet je zeker dat je "${apparaat.naam}" wilt verwijderen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuleer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Verwijder'),
          ),
        ],
      ),
    );

    if (bevestigd != true) return;

    try {
      await DatabaseService().verwijderApparaat(apparaat.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Apparaat verwijderd.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Er ging iets mis: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mijn toestellen')),
      body: StreamBuilder<List<Apparaat>>(
        stream: DatabaseService().getMijnApparatenStream(
          FirebaseAuth.instance.currentUser!.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final apparaten = snapshot.data ?? [];
          if (apparaten.isEmpty) {
            return const Center(child: Text('Je hebt nog geen toestellen.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apparaten.length,
            itemBuilder: (context, index) {
              final apparaat = apparaten[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Image.network(
                      apparaat.imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        apparaat.naam,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StreamBuilder<List<Huuraanvraag>>(
                      stream: DatabaseService().getReserveringenVoorApparaat(
                        apparaat.id,
                      ),
                      builder: (context, resSnap) {
                        final reserveringen = resSnap.data ?? [];
                        final nu = DateTime.now();
                        final vandaag = DateTime(nu.year, nu.month, nu.day);
                        final isInVerhuur = reserveringen.any((r) {
                          if (r.status != HuurStatus.geaccepteerd) return false;
                          final s = DateTime(
                            r.startDatum.year,
                            r.startDatum.month,
                            r.startDatum.day,
                          );
                          final e = DateTime(
                            r.eindDatum.year,
                            r.eindDatum.month,
                            r.eindDatum.day,
                          );
                          return !vandaag.isBefore(s) && !vandaag.isAfter(e);
                        });

                        if (isInVerhuur) {
                          return const Tooltip(
                            message: 'Niet mogelijk tijdens lopende verhuur',
                            child: Icon(Icons.lock, color: Colors.grey),
                          );
                        }

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Wijzigen',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        WijzigenScherm(apparaat: apparaat),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Verwijderen',
                              onPressed: () =>
                                  _verwijderApparaat(context, apparaat),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
