import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MijnGegevensScherm extends StatelessWidget {
  const MijnGegevensScherm({super.key});

  @override
  Widget build(BuildContext context) {
    final gebruiker = FirebaseAuth.instance.currentUser;
    final naamController = TextEditingController(
      text: gebruiker?.displayName ?? '',
    );
    final emailController = TextEditingController(text: gebruiker?.email ?? '');

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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Opslaan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
