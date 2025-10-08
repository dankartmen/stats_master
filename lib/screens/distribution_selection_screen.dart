import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/distribution_bloc/distribution_state.dart';
import 'parameters_screen.dart.dart';
import '../blocs/distribution_bloc/distribution_bloc.dart';
import '../models/distribution_parameters.dart';
import '../models/distribution_type.dart';
import '../blocs/distribution_bloc/distribution_event.dart';

/// {@template distribution_selection_screen}
/// Экран выбора типа распределения.
/// {@endtemplate}
class DistributionSelectionScreen extends StatelessWidget {

  const DistributionSelectionScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<DistributionBloc,DistributionState>(
      listener: (context,state){
        if (state is DistributionErrorState){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: ${state.error}')));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Мастер распределений'),
          actions: [
            IconButton(onPressed: () => _showAppInfo(context), icon: const Icon(Icons.info_outline), tooltip: 'О приложении',)
          ],
        ),
        body: _DistributionSelectionContent(),
      ),
    );
  }

  
  void _showAppInfo(BuildContext context){
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('О приложении'),
        content: const Text(
          'Генератор статистических распределений \n\n'
          'Выберите тип распределения и задайте параметры для генерации случайных величин.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          )
        ],
      )
    );
  }
}

Widget? _DistributionSelectionContent(){
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment:  CrossAxisAlignment.start,
      children: [
        const Text(
          'Доступные распределения',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Выберите тип распределения для генерации случайных величин',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: _buildDistributionGrid(),
        ),
      ],
    ),
  );
}

Widget _buildDistributionGrid() {
  return GridView.count(
    crossAxisCount: 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    childAspectRatio: 1.2,
    children: [
      _DistributionCard(
        type: DistributionType.binomial,
        title: 'Биномиальное',
        subtitle: 'Дискретное',
        description: 'n испытаний, p вероятность',
        icon: Icons.bar_chart,
        color: Colors.blue,
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
      ),
      _DistributionCard(
        type: DistributionType.uniform,
        title: 'Равномерное',
        subtitle: 'Непрерывное',
        description: 'Интервал [a, b]',
        icon: Icons.show_chart,
        color: Colors.green,
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
      ),

    ],
  );
}


/// {@template _distribution_card}
/// Карточка распределения с анимированным взаимодействием.
/// {@endtemplate}
class _DistributionCard extends StatelessWidget {
  const _DistributionCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  final DistributionType type;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectDistribution(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: gradient,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha:0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectDistribution(BuildContext context) {
    final parameters = _createDefaultParameters(type);
    
    context.read<DistributionBloc>().add(
      DistributionParametersChanged(parameters),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<DistributionBloc>(),
          child: ParametersScreen(parameters: parameters),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  DistributionParameters _createDefaultParameters(DistributionType type) {
    return switch (type) {
      DistributionType.binomial => const BinomialParameters(n: 10, p: 0.5),
      DistributionType.uniform => const UniformParameters(a: 0.0, b: 1.0),
      DistributionType.normal => const NormalParameters(m: 0, sigma: 1)
    };
  }
}