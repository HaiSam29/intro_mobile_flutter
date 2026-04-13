import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_scherm.dart';

class ProfielScherm extends StatelessWidget {
  const ProfielScherm({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScherm()),
          );
        },
        child: const Text('Uitloggen'),
      ),
    );
  }
}
