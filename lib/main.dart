import 'package:flutter/material.dart';

import 'parameters_screen.dart.dart';
import 'results_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Распределения по мат. статистике',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const ParametersScreen(),
        '/results': (context) => const ResultsScreen(),
      },
    );
  }
}
