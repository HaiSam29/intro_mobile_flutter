import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'signup_scherm.dart';

class LoginScherm extends StatefulWidget {
  const LoginScherm({super.key});

  @override
  State<LoginScherm> createState() => _LoginSchermState();
}

class _LoginSchermState extends State<LoginScherm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _wachtwoordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _wachtwoordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _wachtwoordController.text,
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
      ).showSnackBar(SnackBar(content: Text('Inloggen mislukt: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inloggen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Inloggen'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupScherm(),
                            ),
                          );
                        },
                  child: const Text('Account maken'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
