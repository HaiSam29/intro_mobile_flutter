import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  initState() {
    super.initState();
    _laadAdresGebruiker();
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

    return Scaffold(
      appBar: AppBar(title: const Text('Mijn gegevens')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  "https://www.gravatar.com/avatar/${gebruiker?.email}?d=identicon",
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () {}, child: const Text('Foto wijzigen')),
            const SizedBox(height: 16),
            TextFormField(
              controller: naamController,
              decoration: const InputDecoration(labelText: 'Naam'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: adresController,
              decoration: const InputDecoration(labelText: 'Adres'),
              keyboardType: TextInputType.streetAddress,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _opslaan,
                child: const Text('Opslaan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
