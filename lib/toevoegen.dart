import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intro_mobile_flutter/apparaat.dart';
import 'package:intro_mobile_flutter/services/database_service.dart';

class ToevoegenScherm extends StatefulWidget {
  const ToevoegenScherm({super.key});

  @override
  State<ToevoegenScherm> createState() => _ToevoegenSchermState();
}

class _ToevoegenSchermState extends State<ToevoegenScherm> {
  final _formKey = GlobalKey<FormState>();

  String _naam = '';
  String _beschrijving = '';
  double _prijs = 0.0;
  Categorie? _geselecteerdeCategorie;
  String _adres = '';
  XFile? _geselecteerdeFoto;
  bool _isFotoAanHetLaden = false;

  String _oorspronkelijkAdres = '';
  bool _isSchermAanHetLaden = true;

  initState() {
    super.initState();
    _laadAdresGebruiker();
  }

  Future<void> _laadAdresGebruiker() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      String? opgevraagdAdres = await DatabaseService().haalGebruikerAdresOp(
        uid,
      );

      setState(() {
        _oorspronkelijkAdres = opgevraagdAdres ?? '';
        _adres = _oorspronkelijkAdres;
        _isSchermAanHetLaden = false;
      });
    } else {
      setState(() {
        _isSchermAanHetLaden = false;
      });
    }
  }

  // De functie om de galerij te openen en een foto te kiezen
  Future<void> _kiesFoto() async {
    final picker = ImagePicker();

    // Vraag de telefoon om de galerij te openen
    final gekozenBestand = await picker.pickImage(source: ImageSource.gallery);

    if (gekozenBestand != null) {
      // Als de gebruiker een foto kiest, sla deze op en herlaad de UI
      setState(() {
        _geselecteerdeFoto = gekozenBestand;
      });
    }
  }

  void _opslaan() async {
    if (_geselecteerdeFoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kies a.u.b eerst een foto!")),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isFotoAanHetLaden = true;
      });

      try {
        // Jouw originele manier om de foto te uploaden
        final String cloudUrl = await DatabaseService().uploadFoto(
          _geselecteerdeFoto!,
        );

        Locatie nieuweLocatie = Locatie(
          latitude: 0.0,
          longitude: 0.0,
          adres: _adres,
        );

        final nieuwApparaat = Apparaat(
          id: '123', // Let op: overweeg hier een uniek ID te genereren (bijv. via uuid package)
          naam: _naam,
          beschrijving: _beschrijving,
          imageUrl: cloudUrl, // Gebruikt de URL van jouw upload functie
          // De aanpassing van je vriend voor de eigenaar:
          eigenaar: FirebaseAuth.instance.currentUser!.uid,
          eigenaarNaam:
              FirebaseAuth.instance.currentUser!.displayName ?? 'Onbekend',
          prijsPerDag: _prijs,
          categorie: _geselecteerdeCategorie!,
          locatie: nieuweLocatie,
        );

        await DatabaseService().voegApparaatToe(nieuwApparaat);

        String? uid = FirebaseAuth.instance.currentUser?.uid;

        if (uid != null && _adres != _oorspronkelijkAdres) {
          await DatabaseService().slaNieuwAdresOpInProfiel(uid, _adres);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Apparaat succesvol opgeslagen!")),
        );

        _formKey.currentState!.reset();

        setState(() {
          _geselecteerdeFoto = null;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Er ging iets mis: $e')));
      } finally {
        if (mounted) {
          setState(() {
            _isFotoAanHetLaden = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Apparaat Aanbieden")),
      body: _isSchermAanHetLaden
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // VELD 1: NAAM
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Naam van het apparaat',
                        ),
                        // Dit is jouw Validators.required
                        validator: (ingevuldeTekst) {
                          if (ingevuldeTekst == null ||
                              ingevuldeTekst.isEmpty) {
                            return 'Vul a.u.b. een naam in'; // Rode foutmelding
                          }
                          return null; // Null betekent: Geen fouten, alles is geldig!
                        },
                        // sla de waarde van dit veld op in de _naam variabele zodra .save() wordt aangeroepen
                        onSaved: (waarde) {
                          _naam = waarde!;
                        },
                      ),

                      const SizedBox(height: 16), // Ruimte tussen de velden
                      // VELD 2: BESCHRIJVING
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Beschrijving',
                        ),
                        maxLines: 3, // Maakt er een <textarea> van

                        validator: (ingevuldeTekst) {
                          if (ingevuldeTekst == null ||
                              ingevuldeTekst.length < 10) {
                            return 'De beschrijving moet minimaal 10 tekens zijn';
                          }
                          return null;
                        },
                        onSaved: (waarde) {
                          _beschrijving = waarde!;
                        },
                      ),

                      const SizedBox(height: 16),

                      // VELD 3: PRIJS
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Prijs per dag (€)',
                          prefixText: '€ ', // voor een mooi euroteken
                        ),
                        keyboardType: TextInputType
                            .number, // zorgt ervoor dat op mobiel een numeriek toetsenbord verschijnt

                        validator: (ingevuldeTekst) {
                          if (ingevuldeTekst == null ||
                              ingevuldeTekst.isEmpty) {
                            return 'Vul een prijs in';
                          }
                          // Check of het wel echt een getal is (geen letters getypt)
                          if (double.tryParse(ingevuldeTekst) == null) {
                            return 'Vul een geldig getal in (bijv. 12.50)';
                          }
                          return null;
                        },
                        onSaved: (waarde) {
                          // Zet de String ("12.50") om naar een double (12.5)
                          _prijs = double.parse(waarde!);
                        },
                      ),

                      const SizedBox(height: 16),

                      // VELD 4: CATEGORIE
                      DropdownButtonFormField<Categorie>(
                        decoration: const InputDecoration(
                          labelText: 'Categorie',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: Categorie.tuin,
                            child: Text('Tuin'),
                          ),
                          DropdownMenuItem(
                            value: Categorie.keuken,
                            child: Text('Keuken'),
                          ),
                          DropdownMenuItem(
                            value: Categorie.gereedschap,
                            child: Text('Gereedschap'),
                          ),
                          DropdownMenuItem(
                            value: Categorie.schoonmaak,
                            child: Text('Schoonmaak'),
                          ),
                        ],
                        // onChanged is verplicht, maar doet hier niks omdat onSaved het werk doet
                        onChanged: (waarde) {},

                        validator: (waarde) {
                          if (waarde == null) return 'Kies een categorie';
                          return null;
                        },
                        onSaved: (waarde) {
                          _geselecteerdeCategorie = waarde;
                        },
                      ),

                      const SizedBox(height: 16),

                      // --- VELD 5: LOCATIE (SIMPEL) ---
                      TextFormField(
                        initialValue: _adres,
                        decoration: const InputDecoration(
                          labelText: 'Adres (Straat en Woonplaats)',
                          prefixIcon: Icon(Icons.location_on),
                        ),

                        validator: (ingevuldeTekst) {
                          if (ingevuldeTekst == null ||
                              ingevuldeTekst.isEmpty) {
                            return 'Vul a.u.b. een adres in';
                          }
                          return null;
                        },
                        onSaved: (waarde) {
                          _adres = waarde!;
                        },
                      ),

                      const SizedBox(height: 16),

                      // NIEUW 3: FOTO PREVIEW & KNOP
                      Row(
                        children: [
                          // Het preview doosje
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            // Als _geselecteerdeFoto leeg is tonen we tekst, anders de Image
                            child: _geselecteerdeFoto != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      8,
                                    ), // Maakt de foto ook rond
                                    child: Image.network(
                                      _geselecteerdeFoto!.path,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Center(child: Text('Geen foto')),
                          ),

                          const SizedBox(width: 16),

                          // De knop om de galerij te openen
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _kiesFoto, // Koppel de functie!
                              icon: const Icon(Icons.image),
                              label: const Text('Kies een foto'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // --- DE VERZEND KNOP ---
                      _isFotoAanHetLaden
                          ? const CircularProgressIndicator() // Laat een laad-icoon zien terwijl de foto aan het uploaden is
                          : ElevatedButton(
                              onPressed:
                                  _opslaan, // Koppel de opslaan-functie aan de klik
                              child: const Text('Opslaan'),
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
