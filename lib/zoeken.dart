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

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Apparaat zoeken",
            style: TextStyle(fontSize: 20, color: Colors.black),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: "Zoek een apparaat...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (getypteTekst) {
              setState(() {
                _zoekTerm = getypteTekst;
              });
            },
          ),
        ),

        // NIEUW: De afstand slider (alleen zichtbaar als we je locatie weten)
        if (_mijnLocatie != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Maximale afstand:'),
                    Text('${_maxAfstandInKm.round()} km', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _maxAfstandInKm,
                  min: 1,
                  max: 100, // Tot maximaal 100km zoeken
                  divisions: 99,
                  label: '${_maxAfstandInKm.round()} km',
                  onChanged: (nieuweWaarde) {
                    setState(() {
                      _maxAfstandInKm = nieuweWaarde;
                    });
                  },
                ),
              ],
            ),
          ),

        DropdownButton<Categorie?>(
          value: _geselecteerdeCategorie,
          hint: const Text('Kies een categorie'),
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
                return const Center(
                  child: Text(
                    "Geen apparaten gevonden in de buurt.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                        padding: const EdgeInsets.all(15.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                apparaat.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${apparaat.naam} (${apparaat.eigenaarNaam})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(weergaveAfstand), // NIEUW: Hier tonen we de echte berekende afstand!
                                  const SizedBox(height: 8),
                                  Text(
                                    '€${apparaat.prijsPerDag} / dag',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
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