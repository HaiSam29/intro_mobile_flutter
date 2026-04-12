import 'package:flutter/material.dart';
import 'package:intro_mobile_flutter/zoeken.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuurShare',
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // State variabele: welke tab is momenteel geselecteerd? (Start op 0 = Home)
  int _geselecteerdeIndex = 0;

  // Een array met tijdelijke schermen. Later vervangen we deze teksten door je echte componenten.
  static const List<Widget> _schermen = <Widget>[
    ZoekScherm(),
    Center(child: Text('Hier komt later: Verhuren')),
    Center(child: Text('Hier komt later: Dashboard')),
    Center(child: Text('Hier komt later: Profiel')),
  ];

  // Functie om de state te updaten als je op een knop klikt
  void _onItemTapped(int index) {
    setState(() {
      _geselecteerdeIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold is je hoofd-layout (de 'div' met vaste secties)
    return Scaffold(
      // Body is je <RouterOutlet> of {children}. Het toont 1 item uit de array.
      body: _schermen.elementAt(_geselecteerdeIndex),

      // Dit bouwt de menubalk onderaan de app
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _geselecteerdeIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'ZOEKEN'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'VERHUREN'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'DASHBOARD'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFIEL'),
        ],
      ),
    );
  }
}
