import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intro_mobile_flutter/entities/apparaat.dart';
import 'package:intro_mobile_flutter/services/database_service.dart';

class WijzigenScherm extends StatefulWidget {
  final Apparaat apparaat;

  const WijzigenScherm({super.key, required this.apparaat});

  @override
  State<WijzigenScherm> createState() => _WijzigenSchermState();
}

class _WijzigenSchermState extends State<WijzigenScherm> {
  final _formKey = GlobalKey<FormState>();
  final String _apiKey = 'AIzaSyD-UXMLZF7E41-t-TXdT5g-wU1CEnGsYDM';

  late String _naam;
  late String _beschrijving;
  late double _prijs;
  late Categorie _geselecteerdeCategorie;

  final _adresController = TextEditingController();

  XFile? _nieuweFoto;
  bool _isAanHetOpslaan = false;

  late LatLng _gekozenLocatie;
  GoogleMapController? _mapController;
  bool _isLocatieAanHetOphalen = false;

  @override
  void initState() {
    super.initState();
    _naam = widget.apparaat.naam;
    _beschrijving = widget.apparaat.beschrijving;
    _prijs = widget.apparaat.prijsPerDag;
    _geselecteerdeCategorie = widget.apparaat.categorie;
    _adresController.text = widget.apparaat.locatie.adres;
    _gekozenLocatie = LatLng(
      widget.apparaat.locatie.latitude,
      widget.apparaat.locatie.longitude,
    );
  }

  @override
  void dispose() {
    _adresController.dispose();
    super.dispose();
  }

  Future<void> _updateKaartVanafAdres(String ingetyptAdres) async {
    if (ingetyptAdres.isEmpty) return;
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(ingetyptAdres)}&key=$_apiKey',
      );
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final loc = data['results'][0]['geometry']['location'];
        LatLng nieuwePositie = LatLng(loc['lat'], loc['lng']);

        setState(() {
          _gekozenLocatie = nieuwePositie;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(nieuwePositie));
      } else {
        print("Adres niet gevonden: ${data['status']}");
      }
    } catch (e) {
      print("Geocoding HTTP fout: $e");
    }
  }

  Future<void> _updateAdresVanafKaart(LatLng positie) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${positie.latitude},${positie.longitude}&key=$_apiKey',
      );
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        setState(() {
          _adresController.text = data['results'][0]['formatted_address'];
        });
      } else {
        print("Coördinaten niet gevonden: ${data['status']}");
      }
    } catch (e) {
      print("Reverse geocoding HTTP fout: $e");
    }
  }

  Future<void> _gebruikHuidigeLocatie() async {
    setState(() {
      _isLocatieAanHetOphalen = true;
    });
    try {
      bool serviceAan = await Geolocator.isLocationServiceEnabled();
      if (!serviceAan) throw 'Locatieservice staat uit';

      LocationPermission permissie = await Geolocator.checkPermission();
      if (permissie == LocationPermission.denied) {
        permissie = await Geolocator.requestPermission();
      }
      if (permissie == LocationPermission.denied ||
          permissie == LocationPermission.deniedForever) {
        throw 'Geen toestemming voor locatie';
      }

      Position positie = await Geolocator.getCurrentPosition();
      LatLng nieuwePositie = LatLng(positie.latitude, positie.longitude);

      setState(() {
        _gekozenLocatie = nieuwePositie;
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(nieuwePositie));
      await _updateAdresVanafKaart(nieuwePositie);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kon locatie niet ophalen: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLocatieAanHetOphalen = false;
        });
      }
    }
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
          latitude: _gekozenLocatie.latitude,
          longitude: _gekozenLocatie.longitude,
          adres: _adresController.text,
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
                  controller: _adresController,
                  decoration: const InputDecoration(
                    labelText: 'Adres (Straat en Woonplaats)',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  onFieldSubmitted: (waarde) {
                    _updateKaartVanafAdres(waarde);
                  },
                  validator: (ingevuldeTekst) {
                    if (ingevuldeTekst == null || ingevuldeTekst.isEmpty) {
                      return 'Vul a.u.b. een adres in';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Locatie op de kaart',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 250,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _gekozenLocatie,
                        zoom: 14,
                      ),
                      onMapCreated: (controller) =>
                          _mapController = controller,
                      markers: {
                        Marker(
                          markerId: const MarkerId('gekozen'),
                          position: _gekozenLocatie,
                          draggable: true,
                          onDragEnd: (nieuwePositie) async {
                            setState(() {
                              _gekozenLocatie = nieuwePositie;
                            });
                            await _updateAdresVanafKaart(nieuwePositie);
                          },
                        ),
                      },
                      onTap: (positie) async {
                        setState(() {
                          _gekozenLocatie = positie;
                        });
                        await _updateAdresVanafKaart(positie);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isLocatieAanHetOphalen
                      ? null
                      : _gebruikHuidigeLocatie,
                  icon: _isLocatieAanHetOphalen
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: const Text('Gebruik mijn huidige locatie'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
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
