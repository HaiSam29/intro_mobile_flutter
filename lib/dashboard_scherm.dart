import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intro_mobile_flutter/huuraanvraag.dart';
import 'package:intro_mobile_flutter/services/database_service.dart';

class DashboardScherm extends StatelessWidget {
  const DashboardScherm({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Titel van het scherm
          const Center(
            child: Text(
              'Mijn Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 16),

          // De 2 tabbladen
          const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'Ik huur'),
              Tab(text: 'Ik verhuur'),
            ],
          ),

          // De inhoud per tabblad
          Expanded(
            child: TabBarView(
              children: [
                _IkHuurTab(uid: uid),
                _IkVerhuurTab(uid: uid),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDatum(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

bool _isVandaagTussen(DateTime start, DateTime eind) {
  final nu = DateTime.now();
  final vandaag = DateTime(nu.year, nu.month, nu.day);
  final s = DateTime(start.year, start.month, start.day);
  final e = DateTime(eind.year, eind.month, eind.day);
  return !vandaag.isBefore(s) && !vandaag.isAfter(e);
}

bool _isVoorbij(DateTime eind) {
  final nu = DateTime.now();
  final vandaag = DateTime(nu.year, nu.month, nu.day);
  final e = DateTime(eind.year, eind.month, eind.day);
  return vandaag.isAfter(e);
}

bool _isToekomst(DateTime start) {
  final nu = DateTime.now();
  final vandaag = DateTime(nu.year, nu.month, nu.day);
  final s = DateTime(start.year, start.month, start.day);
  return vandaag.isBefore(s);
}

class _IkHuurTab extends StatelessWidget {
  final String uid;
  const _IkHuurTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Huuraanvraag>>(
      stream: DatabaseService().getMijnHuurStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final alle = snapshot.data ?? [];

        final aanvragen = alle.where((a) {
          if (a.status == HuurStatus.in_behandeling) return true;
          if (a.status == HuurStatus.geaccepteerd && _isToekomst(a.startDatum)) {
            return true;
          }
          return false;
        }).toList();

        final momenteel = alle
            .where(
              (a) =>
                  a.status == HuurStatus.geaccepteerd &&
                  _isVandaagTussen(a.startDatum, a.eindDatum),
            )
            .toList();

        final geschiedenis = alle.where((a) {
          if (a.status == HuurStatus.geweigerd) return true;
          if (a.status == HuurStatus.geaccepteerd && _isVoorbij(a.eindDatum)) {
            return true;
          }
          return false;
        }).toList();

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mijn huur aanvragen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (aanvragen.isEmpty)
                  const Text('Geen aanvragen.')
                else
                  ...aanvragen.map(
                    (a) => _HuurKaart(aanvraag: a, kantHuurder: true),
                  ),

                const SizedBox(height: 12),

                const Text(
                  'Ik huur momenteel',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (momenteel.isEmpty)
                  const Text('Niets lopend.')
                else
                  ...momenteel.map(
                    (a) => _HuurKaart(aanvraag: a, kantHuurder: true),
                  ),

                const SizedBox(height: 12),

                const Text(
                  'Geschiedenis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (geschiedenis.isEmpty)
                  const Text('Geen geschiedenis.')
                else
                  ...geschiedenis.map(
                    (a) => _HuurKaart(aanvraag: a, kantHuurder: true),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IkVerhuurTab extends StatelessWidget {
  final String uid;
  const _IkVerhuurTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Huuraanvraag>>(
      stream: DatabaseService().getMijnVerhuurStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final alle = snapshot.data ?? [];

        final actieveAanvragen = alle
            .where((a) => a.status == HuurStatus.in_behandeling)
            .toList();

        final lopendeVerhuur = alle
            .where(
              (a) =>
                  a.status == HuurStatus.geaccepteerd &&
                  !_isVoorbij(a.eindDatum),
            )
            .toList();

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actieve aanvragen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (actieveAanvragen.isEmpty)
                  const Text('Geen actieve aanvragen.')
                else
                  ...actieveAanvragen.map(
                    (a) => _HuurKaart(
                      aanvraag: a,
                      kantHuurder: false,
                      toonAccepteerKnoppen: true,
                    ),
                  ),

                const SizedBox(height: 12),

                const Text(
                  'Lopende verhuur',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (lopendeVerhuur.isEmpty)
                  const Text('Niets lopend.')
                else
                  ...lopendeVerhuur.map(
                    (a) => _HuurKaart(aanvraag: a, kantHuurder: false),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HuurKaart extends StatelessWidget {
  final Huuraanvraag aanvraag;
  final bool kantHuurder;
  final bool toonAccepteerKnoppen;

  const _HuurKaart({
    required this.aanvraag,
    required this.kantHuurder,
    this.toonAccepteerKnoppen = false,
  });

  String _statusTekst() {
    switch (aanvraag.status) {
      case HuurStatus.in_behandeling:
        return 'In behandeling';
      case HuurStatus.geaccepteerd:
        return 'Geaccepteerd';
      case HuurStatus.geweigerd:
        return 'Geweigerd';
      case HuurStatus.lopend:
        return 'Lopend';
      case HuurStatus.afgerond:
        return 'Afgerond';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tegenpartij = kantHuurder
        ? 'Bij verhuurder ${aanvraag.verhuurderNaam}'
        : 'Huurder: ${aanvraag.huurderNaam}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                aanvraag.apparaatImageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${aanvraag.apparaatNaam} ($tegenpartij)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatDatum(aanvraag.startDatum)} - ${_formatDatum(aanvraag.eindDatum)}',
                  ),
                  Text('Status: ${_statusTekst()}'),
                  if (toonAccepteerKnoppen) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            DatabaseService().updateHuurStatus(
                              aanvraag.id,
                              HuurStatus.geaccepteerd,
                            );
                          },
                          child: const Text('Accepteren'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            DatabaseService().updateHuurStatus(
                              aanvraag.id,
                              HuurStatus.geweigerd,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Weigeren'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
