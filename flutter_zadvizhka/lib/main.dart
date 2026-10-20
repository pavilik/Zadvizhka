import 'package:flutter/material.dart';
import 'widgets/simulation_screen.dart';

void main() {
  runApp(const ZadvizhkaApp());
}

class ZadvizhkaApp extends StatelessWidget {
  const ZadvizhkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Задвижка — Моделирование',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.indigoAccent,
          secondary: Colors.tealAccent,
          surface: const Color(0xFF1E1E2E),
        ),
        scaffoldBackgroundColor: const Color(0xFF1E1E2E),
        useMaterial3: true,
      ),
      home: const SimulationScreen(),
    );
  }
}