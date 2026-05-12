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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.devices_other,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Je hebt nog geen toestellen.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            itemCount: apparaten.length,
            itemBuilder: (context, index) {
              final apparaat = apparaten[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          apparaat.imageUrl,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        apparaat.naam,
                        style: Theme.of(context).textTheme.titleMedium,
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
                          return Tooltip(
                            message: 'Niet mogelijk tijdens lopende verhuur',
                            child: Icon(
                              Icons.lock,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
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
                              icon: Icon(
                                Icons.delete,
                                color: Theme.of(context).colorScheme.error,
                              ),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
