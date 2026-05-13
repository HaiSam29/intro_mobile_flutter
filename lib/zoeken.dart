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
  /// De geselecteerde categorie uit de dropdown. Null betekent "alle categorieën".
  Categorie? _geselecteerdeCategorie;

  /// De tekst die de gebruiker intypt in de zoekbalk. Leeg betekent geen tekstfilter.
  String _zoekTerm = '';

  /// De maximale zoekafstand in kilometers, instelbaar via de slider in de UI.
  /// Standaard ingesteld op 50 km. Apparaten verder dan deze waarde worden uitgefilterd.
  double _maxAfstandInKm = 50.0;

  /// De huidige GPS-positie van de gebruiker, opgehaald bij het laden van het scherm.
  /// Null als de locatiedienst uitstaat of de toestemming geweigerd is.
  Position? _mijnLocatie;

  /// Geeft aan of de app momenteel de GPS-locatie aan het ophalen is.
  /// Zolang dit true is, wordt een laadscherm getoond.
  bool _isLocatieAanHetLaden = true;

  @override
  void initState() {
    super.initState();
    _bepaalMijnLocatie(); // Haal direct locatie op als het scherm opent
  }

  /// Haalt de huidige GPS-positie van de gebruiker op bij het laden van het scherm.
  /// Vraagt locatietoestemming aan als die nog niet gegeven is.
  /// De opgehaalde positie wordt gebruikt om de afstand tot elk apparaat te berekenen
  /// en om het afstandsfilter (de slider) te laten werken.
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

        // Slider is alleen zichtbaar als GPS beschikbaar is — anders heeft hij geen nut.
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

              // Pas de drie filters toe op elk apparaat. Alleen apparaten die door
              // alle drie filters passeren worden in de lijst getoond.
              final gefilterdeApparaten = alleApparatenUitDb.where((apparaat) {
                // Filter 1: naam moet de zoekterm bevatten (hoofdletterongevoelig)
                final naamMatch = apparaat.naam.toLowerCase().contains(_zoekTerm.toLowerCase());

                // Filter 2: categorie moet overeenkomen, of null (= toon alles)
                final categorieMatch = _geselecteerdeCategorie == null || apparaat.categorie == _geselecteerdeCategorie;
                
                // Filter 3: afstand mag niet groter zijn dan de sliderwaarde.
                // Standaard true zodat apparaten zonder GPS-coördinaten altijd getoond worden.
                bool afstandMatch = true;

                if (_mijnLocatie != null && apparaat.locatie.latitude != 0.0) {
                  double afstandInMeters = Geolocator.distanceBetween(
                    _mijnLocatie!.latitude,
                    _mijnLocatie!.longitude,
                    apparaat.locatie.latitude,
                    apparaat.locatie.longitude,
                  );
                  double afstandInKm = afstandInMeters / 1000;
                  afstandMatch = afstandInKm <= _maxAfstandInKm;
                }

                // Apparaat is zichtbaar als het door alle drie filters passeert
                return naamMatch && categorieMatch && afstandMatch;
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

                  // Bereken de afstand opnieuw puur voor weergave op de kaart (bijv. "4.2 km").
                  // Dit is los van het filter hierboven.
                  String weergaveAfstand = 'Onbekend';
                  if (_mijnLocatie != null && apparaat.locatie.latitude != 0.0) {
                    double meters = Geolocator.distanceBetween(
                      _mijnLocatie!.latitude, _mijnLocatie!.longitude, 
                      apparaat.locatie.latitude, apparaat.locatie.longitude
                    );
                    weergaveAfstand = '${(meters / 1000).toStringAsFixed(1)} km';
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
                                  Text(weergaveAfstand),
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