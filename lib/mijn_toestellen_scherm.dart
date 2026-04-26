import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intro_mobile_flutter/apparaat.dart';
import 'package:intro_mobile_flutter/services/database_service.dart';

class MijnToestellenScherm extends StatelessWidget {
  const MijnToestellenScherm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mijn toestellen')),
      body: StreamBuilder<List<Apparaat>>(
        stream: DatabaseService().getMijnApparatenStream(
          FirebaseAuth.instance.currentUser!.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final apparaten = snapshot.data ?? [];
          if (apparaten.isEmpty) {
            return const Center(child: Text('Je hebt nog geen toestellen.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apparaten.length,
            itemBuilder: (context, index) {
              final apparaat = apparaten[index];
              // hier je bestaande Container, met apparaat.imageUrl en apparaat.naam
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Image.network(
                      apparaat.imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        apparaat.naam,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
