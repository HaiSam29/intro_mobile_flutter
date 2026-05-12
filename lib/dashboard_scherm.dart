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
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const TabBar(
              tabs: [
                Tab(text: 'Ik huur'),
                Tab(text: 'Ik verhuur'),
              ],
            ),
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

class _LegeStaat extends StatelessWidget {
  final IconData icoon;
  final String tekst;
  const _LegeStaat({required this.icoon, required this.tekst});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icoon, color: cs.onSurfaceVariant, size: 20),
          const SizedBox(width: 8),
          Text(
            tekst,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final HuurStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    late Color bg;
    late Color fg;
    late String tekst;
    switch (status) {
      case HuurStatus.in_behandeling:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
        tekst = 'In behandeling';
        break;
      case HuurStatus.geaccepteerd:
      case HuurStatus.lopend:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        tekst = status == HuurStatus.lopend ? 'Lopend' : 'Geaccepteerd';
        break;
      case HuurStatus.geweigerd:
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        tekst = 'Geweigerd';
        break;
      case HuurStatus.afgerond:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurfaceVariant;
        tekst = 'Afgerond';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tekst,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
                Text(
                  'Mijn huur aanvragen',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (aanvragen.isEmpty)
                  const _LegeStaat(icoon: Icons.inbox_outlined, tekst: 'Geen aanvragen.')
                else
                  ...aanvragen.map(
                    (a) => _HuurKaart(aanvraag: a, kantHuurder: true),
                  ),

                const SizedBox(height: 12),

                Text(
                  'Ik huur momenteel',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (momenteel.isEmpty)
                  const _LegeStaat(icoon: Icons.hourglass_empty, tekst: 'Niets lopend.')
                else
                  ...momenteel.map(
                    (a) => _HuurKaart(aanvraag: a, kantHuurder: true),
                  ),

                const SizedBox(height: 12),

                Text(
                  'Geschiedenis',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (geschiedenis.isEmpty)
                  const _LegeStaat(icoon: Icons.history, tekst: 'Geen geschiedenis.')
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
                Text(
                  'Actieve aanvragen',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (actieveAanvragen.isEmpty)
                  const _LegeStaat(icoon: Icons.inbox_outlined, tekst: 'Geen actieve aanvragen.')
                else
                  ...actieveAanvragen.map(
                    (a) => _HuurKaart(
                      aanvraag: a,
                      kantHuurder: false,
                      toonAccepteerKnoppen: true,
                    ),
                  ),

                const SizedBox(height: 12),

                Text(
                  'Lopende verhuur',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (lopendeVerhuur.isEmpty)
                  const _LegeStaat(icoon: Icons.hourglass_empty, tekst: 'Niets lopend.')
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tegenpartij = kantHuurder
        ? 'Bij verhuurder ${aanvraag.verhuurderNaam}'
        : 'Huurder: ${aanvraag.huurderNaam}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                aanvraag.apparaatImageUrl,
                width: 80,
                height: 80,
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_formatDatum(aanvraag.startDatum)} - ${_formatDatum(aanvraag.eindDatum)}',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _StatusBadge(status: aanvraag.status),
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
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor: Theme.of(context).colorScheme.onError,
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
