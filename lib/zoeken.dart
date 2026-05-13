import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intro_mobile_flutter/entities/apparaat.dart';
import 'package:intro_mobile_flutter/details.dart';
import 'package:intro_mobile_flutter/services/database_service.dart';

class ZoekScherm extends StatefulWidget {
  const ZoekScherm({super.key});

  @override
  State<ZoekScherm> createState() => _ZoekSchermState();
}

class _ZoekSchermState extends State<ZoekScherm> {
  String _zoekTerm = '';
  Categorie? _geselecteerdeCategorie;
  double _maxAfstandInKm = 50.0;
  /// true = kaartweergave, false = lijstweergave
  bool _toonKaart = false;
  /// Het apparaat dat de gebruiker aanklikt op de kaart (voor de preview onderaan)
  Apparaat? _geselecteerdApparaat;

  Position? _mijnLocatie;
  bool _isLocatieAanHetLaden = true;

  @override
  void initState() {
    super.initState();
    _bepaalMijnLocatie();
  }

  /// Haalt de GPS-locatie op bij het opstarten.
  /// Als het mislukt, laadt het scherm toch verder zonder afstandsfilter.
  Future<void> _bepaalMijnLocatie() async {
    try {
      bool serviceAan = await Geolocator.isLocationServiceEnabled();
      if (!serviceAan) throw 'Locatieservice staat uit';

      LocationPermission permissie = await Geolocator.checkPermission();
      if (permissie == LocationPermission.denied) {
        permissie = await Geolocator.requestPermission();
      }
      if (permissie == LocationPermission.denied || permissie == LocationPermission.deniedForever) {
        throw 'Geen toestemming voor locatie';
      }

      Position positie = await Geolocator.getCurrentPosition();
      setState(() {
        _mijnLocatie = positie;
        _isLocatieAanHetLaden = false;
      });
    } catch (e) {
      setState(() {
        _isLocatieAanHetLaden = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocatieAanHetLaden) {
      return const Center(child: CircularProgressIndicator());
    }

    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [

        // ZOEKBALK + LIJST/KAART TOGGLE
        // De SegmentedButton laat de gebruiker wisselen tussen lijstweergave en kaartweergave.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Zoek een apparaat...",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (getypteTekst) {
                    setState(() {
                      _zoekTerm = getypteTekst;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              /// Wisselt tussen lijstweergave (false) en kaartweergave (true)
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, icon: Icon(Icons.list)),
                  ButtonSegment(value: true, icon: Icon(Icons.map)),
                ],
                selected: {_toonKaart},
                onSelectionChanged: (s) => setState(() {
                  _toonKaart = s.first;
                  _geselecteerdApparaat = null;
                }),
                showSelectedIcon: false,
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  if (_mijnLocatie != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune, size: 18, color: cs.primary),
                            const SizedBox(width: 8),
                            const Text('Maximale afstand'),
                          ],
                        ),
                        Text(
                          '${_maxAfstandInKm.round()} km',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _maxAfstandInKm,
                      min: 1,
                      max: 100,
                      divisions: 99,
                      label: '${_maxAfstandInKm.round()} km',
                      onChanged: (nieuweWaarde) {
                        setState(() {
                          _maxAfstandInKm = nieuweWaarde;
                        });
                      },
                    ),
                  ],
                  DropdownButtonFormField<Categorie?>(
                    initialValue: _geselecteerdeCategorie,
                    decoration: const InputDecoration(
                      labelText: 'Categorie',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Alle')),
                      DropdownMenuItem(value: Categorie.tuin, child: Text('Tuin')),
                      DropdownMenuItem(value: Categorie.keuken, child: Text('Keuken')),
                      DropdownMenuItem(value: Categorie.gereedschap, child: Text('Gereedschap')),
                      DropdownMenuItem(value: Categorie.schoonmaak, child: Text('Schoonmaak')),
                    ],
                    onChanged: (nieuweWaarde) {
                      setState(() {
                        _geselecteerdeCategorie = nieuweWaarde;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        /// StreamBuilder luistert real-time naar Firestore.
        /// Herbouwt de lijst automatisch bij elke wijziging in de database.
        Expanded(
          child: StreamBuilder<List<Apparaat>>(
            stream: DatabaseService().getApparatenStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final alleApparatenUitDb = snapshot.data ?? [];

              /// Filtert op naam, categorie én afstand tegelijk.
              final gefilterdeApparaten = alleApparatenUitDb.where((apparaat) {
                final naamMatch = apparaat.naam.toLowerCase().contains(_zoekTerm.toLowerCase());
                final categorieMatch = _geselecteerdeCategorie == null || apparaat.categorie == _geselecteerdeCategorie;

                /// Hemelsbreed afstand berekenen tussen gebruiker en apparaat
                bool afstandMatch = true;
                if (_mijnLocatie != null && apparaat.locatie.latitude != 0.0) {
                  double afstandInMeters = Geolocator.distanceBetween(
                    _mijnLocatie!.latitude,
                    _mijnLocatie!.longitude,
                    apparaat.locatie.latitude,
                    apparaat.locatie.longitude
                  );
                  afstandMatch = (afstandInMeters / 1000) <= _maxAfstandInKm;
                }

                return naamMatch && categorieMatch && afstandMatch;
              }).toList();

              if (_toonKaart) {
                return _bouwKaart(gefilterdeApparaten, cs);
              }

              if (gefilterdeApparaten.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Geen apparaten gevonden in de buurt.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: gefilterdeApparaten.length,
                itemBuilder: (context, index) {
                  final apparaat = gefilterdeApparaten[index];

                  String weergaveAfstand = 'Onbekend';
                  if (_mijnLocatie != null && apparaat.locatie.latitude != 0.0) {
                    double meters = Geolocator.distanceBetween(
                      _mijnLocatie!.latitude, _mijnLocatie!.longitude,
                      apparaat.locatie.latitude, apparaat.locatie.longitude
                    );
                    weergaveAfstand = '${(meters / 1000).toStringAsFixed(1)} km';
                  }

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsScherm(apparaat: apparaat),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    apparaat.naam,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'door ${apparaat.eigenaarNaam}',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: cs.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        weergaveAfstand,
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '€${apparaat.prijsPerDag} / dag',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: cs.onPrimaryContainer,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Toont alle gefilterde apparaten als markers op een Google Map.
  /// Tik op een marker → preview onderaan. Tik op preview → [DetailsScherm].
  Widget _bouwKaart(List<Apparaat> apparaten, ColorScheme cs) {
    /// Apparaten zonder locatie (lat = 0) worden uitgesloten van de kaart
    final metLocatie = apparaten.where((a) => a.locatie.latitude != 0.0).toList();

    /// Beginpunt: eigen locatie → eerste apparaat → Brussel als fallback
    final beginPunt = _mijnLocatie != null
        ? LatLng(_mijnLocatie!.latitude, _mijnLocatie!.longitude)
        : (metLocatie.isNotEmpty
            ? LatLng(metLocatie.first.locatie.latitude, metLocatie.first.locatie.longitude)
            : const LatLng(50.8503, 4.3517));

    /// Elk apparaat → Marker op de kaart met naam + prijs als InfoWindow
    final markers = metLocatie.map((a) {
      return Marker(
        markerId: MarkerId(a.id),
        position: LatLng(a.locatie.latitude, a.locatie.longitude),
        infoWindow: InfoWindow(title: a.naam, snippet: '€${a.prijsPerDag} / dag'),
        onTap: () => setState(() => _geselecteerdApparaat = a),
      );
    }).toSet();

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: beginPunt, zoom: 10),
          markers: markers,
          myLocationEnabled: _mijnLocatie != null,
          myLocationButtonEnabled: _mijnLocatie != null,
          onTap: (_) => setState(() => _geselecteerdApparaat = null),
        ),
        /// Stack legt het preview-kaartje over de kaart heen via [Positioned]
        if (_geselecteerdApparaat != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 6,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailsScherm(apparaat: _geselecteerdApparaat!),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _geselecteerdApparaat!.imageUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _geselecteerdApparaat!.naam,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'door ${_geselecteerdApparaat!.eigenaarNaam}',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '€${_geselecteerdApparaat!.prijsPerDag} / dag',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
