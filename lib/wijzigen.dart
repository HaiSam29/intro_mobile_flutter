import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intro_mobile_flutter/apparaat.dart';
import 'package:intro_mobile_flutter/services/database_service.dart';

class WijzigenScherm extends StatefulWidget {
  final Apparaat apparaat;

  const WijzigenScherm({super.key, required this.apparaat});

  @override
  State<WijzigenScherm> createState() => _WijzigenSchermState();
}

class _WijzigenSchermState extends State<WijzigenScherm> {
  final _formKey = GlobalKey<FormState>();

  late String _naam;
  late String _beschrijving;
  late double _prijs;
  late Categorie _geselecteerdeCategorie;
  late String _adres;

  XFile? _nieuweFoto;
  bool _isAanHetOpslaan = false;

  @override
  void initState() {
    super.initState();
    _naam = widget.apparaat.naam;
    _beschrijving = widget.apparaat.beschrijving;
    _prijs = widget.apparaat.prijsPerDag;
    _geselecteerdeCategorie = widget.apparaat.categorie;
    _adres = widget.apparaat.locatie.adres;
  }

  Future<void> _kiesFoto() async {
    final picker = ImagePicker();
    final gekozenBestand = await picker.pickImage(source: ImageSource.gallery);

    if (gekozenBestand != null) {
      setState(() {
        _nieuweFoto = gekozenBestand;
      });
    }
  }

  void _opslaan() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isAanHetOpslaan = true;
      });

      try {
        String fotoUrl = widget.apparaat.imageUrl;
        if (_nieuweFoto != null) {
          fotoUrl = await DatabaseService().uploadFoto(_nieuweFoto!);
        }

        Locatie nieuweLocatie = Locatie(
          latitude: widget.apparaat.locatie.latitude,
          longitude: widget.apparaat.locatie.longitude,
          adres: _adres,
        );

        final aangepastApparaat = Apparaat(
          id: widget.apparaat.id,
          naam: _naam,
          beschrijving: _beschrijving,
          imageUrl: fotoUrl,
          eigenaar: widget.apparaat.eigenaar,
          eigenaarNaam: widget.apparaat.eigenaarNaam,
          prijsPerDag: _prijs,
          categorie: _geselecteerdeCategorie,
          locatie: nieuweLocatie,
        );

        await DatabaseService().updateApparaat(aangepastApparaat);

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Apparaat aangepast!')));
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Er ging iets mis: $e')));
      } finally {
        if (mounted) {
          setState(() {
            _isAanHetOpslaan = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apparaat wijzigen')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  initialValue: _naam,
                  decoration: const InputDecoration(
                    labelText: 'Naam van het apparaat',
                  ),
                  validator: (ingevuldeTekst) {
                    if (ingevuldeTekst == null || ingevuldeTekst.isEmpty) {
                      return 'Vul a.u.b. een naam in';
                    }
                    return null;
                  },
                  onSaved: (waarde) {
                    _naam = waarde!;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _beschrijving,
                  decoration: const InputDecoration(labelText: 'Beschrijving'),
                  maxLines: 3,
                  validator: (ingevuldeTekst) {
                    if (ingevuldeTekst == null || ingevuldeTekst.length < 10) {
                      return 'De beschrijving moet minimaal 10 tekens zijn';
                    }
                    return null;
                  },
                  onSaved: (waarde) {
                    _beschrijving = waarde!;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _prijs.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Prijs per dag (€)',
                    prefixText: '€ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (ingevuldeTekst) {
                    if (ingevuldeTekst == null || ingevuldeTekst.isEmpty) {
                      return 'Vul een prijs in';
                    }
                    if (double.tryParse(ingevuldeTekst) == null) {
                      return 'Vul een geldig getal in (bijv. 12.50)';
                    }
                    return null;
                  },
                  onSaved: (waarde) {
                    _prijs = double.parse(waarde!);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Categorie>(
                  initialValue: _geselecteerdeCategorie,
                  decoration: const InputDecoration(labelText: 'Categorie'),
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
                  onChanged: (waarde) {},
                  validator: (waarde) {
                    if (waarde == null) return 'Kies een categorie';
                    return null;
                  },
                  onSaved: (waarde) {
                    _geselecteerdeCategorie = waarde!;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _adres,
                  decoration: const InputDecoration(
                    labelText: 'Adres (Straat en Woonplaats)',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (ingevuldeTekst) {
                    if (ingevuldeTekst == null || ingevuldeTekst.isEmpty) {
                      return 'Vul a.u.b. een adres in';
                    }
                    return null;
                  },
                  onSaved: (waarde) {
                    _adres = waarde!;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _nieuweFoto != null
                            ? Image.network(
                                _nieuweFoto!.path,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                widget.apparaat.imageUrl,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _kiesFoto,
                        icon: const Icon(Icons.image),
                        label: const Text('Andere foto kiezen'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _isAanHetOpslaan
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _opslaan,
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
