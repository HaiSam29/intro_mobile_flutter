import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_scherm.dart';
import 'mijn_gegevens_scherm.dart';
import 'mijn_toestellen_scherm.dart';

class ProfielScherm extends StatelessWidget {
  const ProfielScherm({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundImage: NetworkImage(
                user.photoURL ??
                    "https://www.gravatar.com/avatar/${user.email}?d=identicon",
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user.displayName ?? "Anonieme gebruiker",
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              user.email ?? "",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.edit, color: cs.primary),
                    title: const Text('Mijn gegevens bewerken'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MijnGegevensScherm(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.devices, color: cs.primary),
                    title: const Text('Mijn toestellen'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MijnToestellenScherm(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScherm()),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text("Uitloggen"),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
