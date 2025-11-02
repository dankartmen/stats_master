import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/distribution_bloc/distribution_bloc.dart';
import 'repositories/distribution_repository.dart';
import 'repositories/saved_results_repository.dart';
import 'screens/distribution_selection_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => DistributionRepository()),
        RepositoryProvider(create: (context) => SavedResultsRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => DistributionBloc(
              repository: context.read<DistributionRepository>(),
              savedResultsRepository: context.read<SavedResultsRepository>()
            ),
          )
        ],
        child: MaterialApp(
          title: 'Мастер распределений',
          theme: _buildThemeData(),
          home: const DistributionSelectionScreen(),
          debugShowCheckedModeBanner: false,
        ),
      )
    );
  }

  /// Строит кастомную тему приложения с Material 3.
  /// Возвращает:
  /// - [ThemeData] - настроенная тема с цветами для распределений и улучшенной типографикой
  ThemeData _buildThemeData() {
    return ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.blue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        bodySmall: TextStyle(color: Colors.black54),
        labelLarge: TextStyle(color: Colors.black87),
        labelSmall: TextStyle(color: Colors.black54),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}