import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intro_mobile_flutter/services/database_service.dart';
import 'main.dart';

class SignupScherm extends StatefulWidget {
  const SignupScherm({super.key});

  @override
  State<SignupScherm> createState() => _SignupSchermState();
}

class _SignupSchermState extends State<SignupScherm> {
  final _formKey = GlobalKey<FormState>();
  final _naamController = TextEditingController();
  final _emailController = TextEditingController();
  final _wachtwoordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _naamController.dispose();
    _emailController.dispose();
    _wachtwoordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _wachtwoordController.text,
          );
      final user = credential.user;
      if (user == null) {
        throw Exception('Gebruiker kon niet aangemaakt worden.');
      }

      await user.updateDisplayName(_naamController.text.trim());

      // Maak een gebruikersprofiel aan in Firestore, toegevoegd door vriend 
      await DatabaseService().maakGebruikerProfielAan(
        uid: user.uid,
        naam: _naamController.text.trim(),
        email: _emailController.text.trim(),
        adres: null, // Hier zou je een veld kunnen toevoegen in het formulier om dit in te vullen
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppShell()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registreren mislukt: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account maken')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _naamController,
                decoration: const InputDecoration(labelText: 'Naam'),
                validator: (waarde) {
                  if (waarde == null || waarde.trim().isEmpty) {
                    return 'Vul een naam in';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (waarde) {
                  if (waarde == null || waarde.trim().isEmpty) {
                    return 'Vul een e-mail in';
                  }
                  if (!waarde.contains('@')) {
                    return 'Geen geldig e-mailadres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _wachtwoordController,
                decoration: const InputDecoration(labelText: 'Wachtwoord'),
                obscureText: true,
                validator: (waarde) {
                  if (waarde == null || waarde.isEmpty) {
                    return 'Vul een wachtwoord in';
                  }
                  if (waarde.length < 6) {
                    return 'Minstens 6 tekens';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign up'),
                ),
              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
