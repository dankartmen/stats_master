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
        headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.grey),
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