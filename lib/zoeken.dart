import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // NIEUW: Voor locatie en afstandsmeting
import 'package:intro_mobile_flutter/apparaat.dart';
import 'package:intro_mobile_flutter/details.dart';
import 'package:intro_mobile_flutter/services/database_service.dart';

class ZoekScherm extends StatefulWidget {
  const ZoekScherm({super.key});

  @override
  State<ZoekScherm> createState() => _ZoekSchermState();
}

class _ZoekSchermState extends State<ZoekScherm> {
  Categorie? _geselecteerdeCategorie;
  String _zoekTerm = '';

  // NIEUW: Variabelen voor de afstand
  double _maxAfstandInKm = 50.0; // Standaard 50 km
  Position? _mijnLocatie;
  bool _isLocatieAanHetLaden = true;

  @override
  void initState() {
    super.initState();
    _bepaalMijnLocatie(); // Haal direct locatie op als het scherm opent
  }

  // NIEUW: Functie om jouw huidige locatie op te halen
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
      // Als het niet lukt (bijv. locatie uit), laten we het scherm toch inladen, 
      // maar het afstandsfilter zal niet werken.
      setState(() {
        _isLocatieAanHetLaden = false;
      });
      print("Kon locatie niet ophalen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wacht even tot we je locatie hebben
    if (_isLocatieAanHetLaden) {
      return const Center(child: CircularProgressIndicator());
    }

    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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

        Expanded(
          child: StreamBuilder<List<Apparaat>>(
            stream: DatabaseService().getApparatenStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final alleApparatenUitDb = snapshot.data ?? [];

              final gefilterdeApparaten = alleApparatenUitDb.where((apparaat) {
                final naamMatch = apparaat.naam.toLowerCase().contains(_zoekTerm.toLowerCase());
                final categorieMatch = _geselecteerdeCategorie == null || apparaat.categorie == _geselecteerdeCategorie;
                
                // NIEUW: Bereken afstand en check of het binnen de slider valt
                bool afstandMatch = true; // Standaard waar, voor het geval we geen locatie hebben
                
                if (_mijnLocatie != null && apparaat.locatie.latitude != 0.0) {
                  // Bereken afstand in meters
                  double afstandInMeters = Geolocator.distanceBetween(
                    _mijnLocatie!.latitude, 
                    _mijnLocatie!.longitude, 
                    apparaat.locatie.latitude, 
                    apparaat.locatie.longitude
                  );
                  // Zet om naar kilometers en vergelijk met de slider
                  double afstandInKm = afstandInMeters / 1000;
                  afstandMatch = afstandInKm <= _maxAfstandInKm;
                }

                return naamMatch && categorieMatch && afstandMatch; // Alle drie moeten kloppen
              }).toList();

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

                  // NIEUW: Bereken de afstand specifiek om te laten zien op het scherm
                  String weergaveAfstand = 'Onbekend';
                  if (_mijnLocatie != null && apparaat.locatie.latitude != 0.0) {
                    double meters = Geolocator.distanceBetween(
                      _mijnLocatie!.latitude, _mijnLocatie!.longitude, 
                      apparaat.locatie.latitude, apparaat.locatie.longitude
                    );
                    weergaveAfstand = '${(meters / 1000).toStringAsFixed(1)} km'; // Bijv: "4.2 km"
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
}