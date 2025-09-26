import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stats_master/blocs/distribution_bloc/distribution_state.dart';
import 'repositories/distribution_repository.dart';
import 'blocs/distribution_bloc/distribution_bloc.dart';
import 'screens/distribution_selection_screen.dart';
import 'screens/parameters_screen.dart.dart';
import 'screens/results_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => DistributionRepository(),
      child: BlocProvider(
        create: (context) => DistributionBloc(
          repository: context.read<DistributionRepository>()
        ),
        child: MaterialApp(
          title: 'Мастер распределений',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: const DistributionSelectionScreen(),
        ),
      )
    );
  }
}
