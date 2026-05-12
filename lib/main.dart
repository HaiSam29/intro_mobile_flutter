import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'dashboard_scherm.dart';
import 'package:intro_mobile_flutter/toevoegen.dart';
import 'package:intro_mobile_flutter/zoeken.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_scherm.dart';
import 'profiel_scherm.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'BuurShare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScherm(),
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
    ToevoegenScherm(),
    DashboardScherm(),
    ProfielScherm(),
  ];

  // Functie om de state te updaten als je op een knop klikt
  void _onItemTapped(int index) {
    setState(() {
      _geselecteerdeIndex = index;
    });
  }

  static const List<String> _titels = <String>[
    'Zoeken',
    'Apparaat aanbieden',
    'Mijn Dashboard',
    'Mijn Profiel',
  ];

  @override
  Widget build(BuildContext context) {
    // Scaffold is je hoofd-layout (de 'div' met vaste secties)
    return Scaffold(
      appBar: AppBar(title: Text(_titels[_geselecteerdeIndex])),
      // Body is je <RouterOutlet> of {children}. Het toont 1 item uit de array.
      body: _schermen.elementAt(_geselecteerdeIndex),

      // Dit bouwt de menubalk onderaan de app
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _geselecteerdeIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'ZOEKEN'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'VOEG TOE'),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'DASHBOARD',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFIEL'),
        ],
      ),
    );
  }
}
