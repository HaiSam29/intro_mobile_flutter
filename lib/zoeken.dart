import 'package:flutter/material.dart';
import 'package:intro_mobile_flutter/apparaat.dart';
import 'package:intro_mobile_flutter/services/database_service.dart';

// Dit is een StatelessWidget, want de lijst zelf heeft (nu nog) geen interne state nodig
class ZoekScherm extends StatefulWidget {
  const ZoekScherm({super.key});

  @override
  State<ZoekScherm> createState() => _ZoekSchermState();
}

class _ZoekSchermState extends State<ZoekScherm> {
  Categorie? _geselecteerdeCategorie; // State variabele voor de dropdown
  String _zoekTerm = ''; // State variabele voor de zoekterm (optioneel)


  @override
  Widget build(BuildContext context) {
    
    // 2. Column om de dropdown en de lijst onder elkaar te zetten
    return Column(
      children: [
        Padding(
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

        // 3. De Dropdown (Vergelijkbaar met <select> in HTML)
        DropdownButton<Categorie?>(
          value: _geselecteerdeCategorie,
          hint: const Text('Kies een categorie'),
          items: const [
            DropdownMenuItem(value: null, child: Text('Alle')),
            DropdownMenuItem(value: Categorie.tuin, child: Text('Tuin')),
            DropdownMenuItem(value: Categorie.keuken, child: Text('Keuken')),
            DropdownMenuItem(
              value: Categorie.gereedschap,
              child: Text('Gereedschap'),
            ),
            DropdownMenuItem(
              value: Categorie.schoonmaak,
              child: Text('Schoonmaak'),
            ),
          ],
          onChanged: (nieuweWaarde) {
            // Dit is jouw onClick/onChange event. Update de state!
            setState(() {
              _geselecteerdeCategorie = nieuweWaarde;
            });
          },
        ),

        // 4. Expanded dwingt de lijst om de overgebleven ruimte te vullen
        Expanded(
          child: StreamBuilder<List<Apparaat>>(
            stream: DatabaseService().getApparatenStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final alleApparatenUitDb = snapshot.data ?? [];

              final gefilterdeApparaten = alleApparatenUitDb.where((apparaat) {
                final naamMatch = apparaat.naam.toLowerCase().contains(
                  _zoekTerm.toLowerCase(),
                );
                final categorieMatch =
                    _geselecteerdeCategorie == null ||
                    apparaat.categorie == _geselecteerdeCategorie;
                return naamMatch && categorieMatch;
              }).toList();

              if (gefilterdeApparaten.isEmpty) {
                return const Center(
                  child: Text(
                    "Geen apparaten gevonden.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                itemCount: gefilterdeApparaten.length,
                itemBuilder: (context, index) {
                  final apparaat = gefilterdeApparaten[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
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
                                  '${apparaat.naam} (${apparaat.eigenaar})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text('1.5 km'),
                                const SizedBox(height: 8),
                                Text(
                                  '€${apparaat.prijsPerDag} / dag',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
