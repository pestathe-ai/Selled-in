import 'package:flutter/material.dart';

import 'screens/articoli_screen.dart';
import 'screens/rivedere_screen.dart';
import 'screens/statistiche_screen.dart';
import 'screens/impostazioni_screen.dart';
import 'logic.dart';
import 'store.dart';

final archivio = Archivio();

class Colori {
  static const blu = Color(0xFF1D3A8A);
  static const arancio = Color(0xFFF28C38);
  static const carta = Color(0xFFFFF8F0);
  static const inchiostro = Color(0xFF14213D);
}

/// Stile del marchio (Sora, variabile).
TextStyle marchio(double size, {double peso = 800, Color? colore}) => TextStyle(
      fontFamily: 'Sora',
      fontSize: size,
      fontVariations: [FontVariation('wght', peso)],
      color: colore,
    );

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  archivio.carica();
  runApp(const SelledInApp());
}

class SelledInApp extends StatelessWidget {
  const SelledInApp({super.key});

  @override
  Widget build(BuildContext context) {
    final schema = ColorScheme.fromSeed(
      seedColor: Colori.blu,
      primary: Colori.blu,
      secondary: Colori.arancio,
      surface: Colori.carta,
      onSurface: Colori.inchiostro,
    );
    return MaterialApp(
      title: 'Selled-in',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: schema,
        useMaterial3: true,
        scaffoldBackgroundColor: Colori.carta,
        appBarTheme: AppBarTheme(
          backgroundColor: Colori.carta,
          foregroundColor: Colori.inchiostro,
          titleTextStyle: marchio(20, peso: 700, colore: Colori.inchiostro),
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colori.inchiostro.withValues(alpha: 0.08)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const Guscio(),
    );
  }
}

class Guscio extends StatefulWidget {
  const Guscio({super.key});

  @override
  State<Guscio> createState() => _GuscioState();
}

class _GuscioState extends State<Guscio> {
  int scheda = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: archivio,
      builder: (context, _) {
        if (!archivio.pronto) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final oggi = DateTime.now();
        final fermi = archivio.articoli.where((a) => isFermo(a, archivio.impostazioni, oggi)).length;
        // Istanze non const: si ricostruiscono a ogni modifica dell'archivio.
        // ignore_for_file: prefer_const_constructors
        final pagine = <Widget>[
          ArticoliScreen(onVaiARivedere: () => setState(() => scheda = 1)),
          RivedereScreen(),
          StatisticheScreen(),
          ImpostazioniScreen(),
        ];
        return Scaffold(
          body: pagine[scheda],
          bottomNavigationBar: NavigationBar(
            selectedIndex: scheda,
            onDestinationSelected: (i) => setState(() => scheda = i),
            destinations: [
              const NavigationDestination(icon: Icon(Icons.checkroom_outlined), label: 'Articoli'),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: fermi > 0,
                  label: Text('$fermi'),
                  backgroundColor: Colori.arancio,
                  child: const Icon(Icons.trending_down),
                ),
                label: 'Da rivedere',
              ),
              const NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Statistiche'),
              const NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Impostazioni'),
            ],
          ),
        );
      },
    );
  }
}

/// Firma del marchio, in fondo alla home.
class Firma extends StatelessWidget {
  const Firma({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text("un'app Dom Studio",
              style: marchio(12, peso: 400, colore: Colori.inchiostro.withValues(alpha: 0.5))),
        ),
      );
}
