import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intro_mobile_flutter/apparaat.dart';
import 'package:intro_mobile_flutter/services/database_service.dart';

class ToevoegenScherm extends StatefulWidget {
  const ToevoegenScherm({super.key});

  @override
  State<ToevoegenScherm> createState() => _ToevoegenSchermState();
}

class _ToevoegenSchermState extends State<ToevoegenScherm> {
  final _formKey = GlobalKey<FormState>();
  final String _apiKey = 'AIzaSyD-UXMLZF7E41-t-TXdT5g-wU1CEnGsYDM';

  String _naam = '';
  String _beschrijving = '';
  double _prijs = 0.0;
  Categorie? _geselecteerdeCategorie;

  final _adresController = TextEditingController();

  XFile? _geselecteerdeFoto;
  bool _isFotoAanHetLaden = false;

  String _oorspronkelijkAdres = '';
  bool _isSchermAanHetLaden = true;

  /// De geselecteerde locatie op de kaart als breedte- en lengtegraad.
  /// Standaard ingesteld op Brussel (50.8503, 4.3517).
  LatLng _gekozenLocatie = const LatLng(50.8503, 4.3517);

  /// Controller voor de Google Map widget, gebruikt om de camera programmatisch te bewegen.
  GoogleMapController? _mapController;

  /// Geeft aan of de app momenteel de GPS-locatie van het toestel aan het ophalen is.
  bool _isLocatieAanHetOphalen = false;

  @override
  void initState() {
    super.initState();
    _laadAdresGebruiker();
  }

  @override
  void dispose() {
    _adresController.dispose();
    super.dispose();
  }

  Future<void> _laadAdresGebruiker() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      String? opgevraagdAdres = await DatabaseService().haalGebruikerAdresOp(
        uid,
      );

      setState(() {
        _oorspronkelijkAdres = opgevraagdAdres ?? '';
        _adresController.text = _oorspronkelijkAdres;
        _isSchermAanHetLaden = false;
      });

      // NIEUW 1: Update de kaart direct als de gebruiker al een adres in zijn profiel had
      if (_oorspronkelijkAdres.isNotEmpty) {
        _updateKaartVanafAdres(_oorspronkelijkAdres);
      }
    } else {
      setState(() {
        _isSchermAanHetLaden = false;
      });
    }
  }

  /// Zet een tekstadres om naar GPS-coördinaten via de Google Geocoding API
  /// en verplaatst de kaartcamera naar die positie.
  ///
  /// [ingetyptAdres] Het adres dat omgezet moet worden naar coördinaten.
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

  /// Zet GPS-coördinaten om naar een leesbaar adres via de Google Reverse Geocoding API
  /// en toont dat adres in het adresveld.
  ///
  /// [positie] De coördinaten (breedte- en lengtegraad) die omgezet worden naar een adres.
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

  /// Haalt de huidige GPS-positie van het toestel op via de Geolocator package.
  /// Vraagt locatietoestemming aan de gebruiker als die nog niet gegeven is.
  /// Bij succes worden de kaart en het adresveld bijgewerkt met de huidige locatie.
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
        final String cloudUrl = await DatabaseService().uploadFoto(
          _geselecteerdeFoto!,
        );

        Locatie nieuweLocatie = Locatie(
          latitude: _gekozenLocatie.latitude,
          longitude: _gekozenLocatie.longitude,
          adres: _adresController.text,
        );

        final nieuwApparaat = Apparaat(
          id: '123',
          naam: _naam,
          beschrijving: _beschrijving,
          imageUrl: cloudUrl,
          eigenaar: FirebaseAuth.instance.currentUser!.uid,
          eigenaarNaam:
              FirebaseAuth.instance.currentUser!.displayName ?? 'Onbekend',
          prijsPerDag: _prijs,
          categorie: _geselecteerdeCategorie!,
          locatie: nieuweLocatie,
        );

        await DatabaseService().voegApparaatToe(nieuwApparaat);

        String? uid = FirebaseAuth.instance.currentUser?.uid;

        // Sla het nieuwe adres op in het profiel, maar alleen als het effectief gewijzigd is
        // om onnodige schrijfoperaties naar de database te vermijden.
        if (uid != null && _adresController.text != _oorspronkelijkAdres) {
          await DatabaseService().slaNieuwAdresOpInProfiel(
            uid,
            _adresController.text,
          );
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Apparaat succesvol opgeslagen!")),
        );

        _formKey.currentState!.reset();
        _adresController.text = '';

        setState(() {
          _geselecteerdeFoto = null;
          _gekozenLocatie = const LatLng(50.8503, 4.3517);
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
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Naam van het apparaat',
                        ),
                        validator: (ingevuldeTekst) {
                          if (ingevuldeTekst == null || ingevuldeTekst.isEmpty)
                            return 'Vul a.u.b. een naam in';
                          return null;
                        },
                        onSaved: (waarde) => _naam = waarde!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Beschrijving',
                        ),
                        maxLines: 3,
                        validator: (ingevuldeTekst) {
                          if (ingevuldeTekst == null ||
                              ingevuldeTekst.length < 10)
                            return 'De beschrijving moet minimaal 10 tekens zijn';
                          return null;
                        },
                        onSaved: (waarde) => _beschrijving = waarde!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Prijs per dag (€)',
                          prefixText: '€ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (ingevuldeTekst) {
                          if (ingevuldeTekst == null || ingevuldeTekst.isEmpty)
                            return 'Vul een prijs in';
                          if (double.tryParse(ingevuldeTekst) == null)
                            return 'Vul een geldig getal in (bijv. 12.50)';
                          return null;
                        },
                        onSaved: (waarde) => _prijs = double.parse(waarde!),
                      ),
                      const SizedBox(height: 16),
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
                        onChanged: (waarde) {},
                        validator: (waarde) {
                          if (waarde == null) return 'Kies een categorie';
                          return null;
                        },
                        onSaved: (waarde) => _geselecteerdeCategorie = waarde,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _adresController,
                        decoration: const InputDecoration(
                          labelText: 'Adres (Straat en Woonplaats)',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        // NIEUW 3: Dit triggert _updateKaartVanafAdres zodra je op Enter drukt in het toetsenbord
                        onFieldSubmitted: (waarde) {
                          _updateKaartVanafAdres(waarde);
                        },
                        validator: (ingevuldeTekst) {
                          if (ingevuldeTekst == null || ingevuldeTekst.isEmpty)
                            return 'Vul a.u.b. een adres in';
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _geselecteerdeFoto != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _geselecteerdeFoto!.path,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Center(child: Text('Geen foto')),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _kiesFoto,
                              icon: const Icon(Icons.image),
                              label: const Text('Kies een foto'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _isFotoAanHetLaden
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
