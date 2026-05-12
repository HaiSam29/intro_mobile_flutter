import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intro_mobile_flutter/entities/gebruiker.dart';
import 'package:intro_mobile_flutter/services/database_service.dart';

class MijnGegevensScherm extends StatefulWidget {
  const MijnGegevensScherm({super.key});

  @override
  State<MijnGegevensScherm> createState() => _MijnGegevensSchermState();
}

class _MijnGegevensSchermState extends State<MijnGegevensScherm> {
  final adresController = TextEditingController();
  final naamController = TextEditingController();
  final emailController = TextEditingController();
  XFile? _geselecteerdeFoto;

  initState() {
    super.initState();
    _laadAdresGebruiker();
  }

  Future<void> _kiesFoto() async {
    final picker = ImagePicker();
    final gekozenBestand = await picker.pickImage(source: ImageSource.gallery);

    if (gekozenBestand != null) {
      setState(() {
        _geselecteerdeFoto = XFile(gekozenBestand.path);
      });
    }
  }

  Future<void> _laadAdresGebruiker() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      Gebruiker? gebruiker = await DatabaseService().haalGebruikerGegevensOp(
        uid,
      );

      setState(() {
        adresController.text = gebruiker?.adres ?? '';
        naamController.text = gebruiker?.naam ?? '';
        emailController.text = gebruiker?.email ?? '';
      });
    }
  }

  void _opslaan() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    if (uid.isEmpty) return;

    Gebruiker gewijzigdeGebruiker = Gebruiker(
      uid: uid,
      naam: naamController.text,
      email: emailController.text,
      adres: adresController.text,
    );

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      if (_geselecteerdeFoto != null) {
        final bytes = await _geselecteerdeFoto!.readAsBytes();
        final ref = FirebaseStorage.instance.ref().child(
          'profiel_fotos/$uid.jpg',
        );
        await ref.putData(bytes);
        final downloadUrl = await ref.getDownloadURL();
        await FirebaseAuth.instance.currentUser!.updatePhotoURL(downloadUrl);
      }

      await DatabaseService().updateGebruiker(gewijzigdeGebruiker);

      if (!mounted) return;

      navigator.pop(context);

      messenger.showSnackBar(
        const SnackBar(content: Text("Gegevens succesvol opgeslagen!")),
      );
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Fout bij opslaan gegevens!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gebruiker = FirebaseAuth.instance.currentUser;

    ImageProvider avatarImage;
    if (_geselecteerdeFoto != null) {
      avatarImage = NetworkImage(_geselecteerdeFoto!.path);
    } else if (gebruiker?.photoURL != null) {
      avatarImage = NetworkImage(gebruiker!.photoURL!);
    } else {
      avatarImage = NetworkImage(
        "https://www.gravatar.com/avatar/${gebruiker?.email}?d=identicon",
      );
    }

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mijn gegevens')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(radius: 50, backgroundImage: avatarImage),
                Material(
                  color: cs.primary,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _kiesFoto,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.camera_alt, size: 18, color: cs.onPrimary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tik op het camera-icoon om je foto te wijzigen',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextFormField(
                    controller: naamController,
                    decoration: const InputDecoration(
                      labelText: 'Naam',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: adresController,
                    decoration: const InputDecoration(
                      labelText: 'Adres',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    keyboardType: TextInputType.streetAddress,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _opslaan,
                      icon: const Icon(Icons.save),
                      label: const Text('Opslaan'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
