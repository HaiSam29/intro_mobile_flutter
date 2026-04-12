import 'package:flutter/material.dart';
import 'package:intro_mobile_flutter/apparaat.dart';

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
    // 1. Jouw bestaande filter logica
    final gefilterdeApparaten = dummyApparaten.where((apparaat) {
      final naamMatch = apparaat.naam.toLowerCase().contains(
        _zoekTerm.toLowerCase(),
      );
      final categorieMatch =
          _geselecteerdeCategorie == null ||
          apparaat.categorie == _geselecteerdeCategorie;
      return naamMatch && categorieMatch;
    }).toList();

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
          child: gefilterdeApparaten.isEmpty
              ? const Center(
                  child: Text(
                    "Geen apparaten gevonden.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: gefilterdeApparaten.length,
                  itemBuilder: (context, index) {
                    final apparaat = gefilterdeApparaten[index];

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      // Padding toegevoegd in de Card zodat de tekst niet tegen de rand plakt
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('${apparaat.naam} - ${apparaat.eigenaar}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
