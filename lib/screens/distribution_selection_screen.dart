import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/distribution_bloc/distribution_bloc.dart';
import '../blocs/distribution_bloc/distribution_event.dart';
import '../blocs/distribution_bloc/distribution_state.dart';
import '../models/distribution_parameters.dart';
import '../models/distribution_type.dart';
import 'parameters_screen.dart.dart';

/// {@template distribution_selection_screen}
/// Экран выбора типа распределения.
/// Предоставляет пользователю интерфейс для выбора одного из доступных
/// статистических распределений и перехода к вводу параметров.
/// {@endtemplate}
class DistributionSelectionScreen extends StatelessWidget {
  /// {@macro saved_results_repository}
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
        body: _distributionSelectionContent(),
      ),
    );
  }

  /// Показывает диалоговое окно с информацией о приложении.
  /// Принимает:
  /// - [context] - контекст построения виджета
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

/// {@template _distribution_selection_content}
/// Экран выбора распределения.
/// Содержит заголовок, описание и сетку карточек распределений.
/// {@endtemplate}
Widget? _distributionSelectionContent(){
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

/// Строит сетку карточек распределений.
/// Возвращает:
/// - [Widget] - сетку с карточками распределений
Widget _buildDistributionGrid() {
  return GridView.count(
    crossAxisCount: 3,
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
      _DistributionCard(
        type: DistributionType.normal,
        title: 'Нормальное',
        subtitle: 'Непрерывное',
        description: 'Среднее значение m, стандартное отклонение σ',
        icon: Icons.show_chart,
        color: Colors.blue,
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
      )
    ],
  );
}


/// {@template _distribution_card}
/// Карточка распределения.
/// Отображает информацию о типе распределения и позволяет перейти к вводу параметров.
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

  /// Тип распределения
  final DistributionType type;

  /// Заголовок карточки
  final String title;

  /// Подзаголовок
  final String subtitle;

  /// Описание
  final String description;

  /// Иконка
  final IconData icon;

  /// Основной цвет
  final Color color;

  /// Градиент фона
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

  // Обрабатывает выбор распределения и переход к экрану параметров.
  /// Принимает:
  /// - [context] - контекст построения виджета
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

  /// Создает параметры по умолчанию для выбранного типа распределения.
  /// Принимает:
  /// - [type] - тип распределения
  /// Возвращает:
  /// - [DistributionParameters] - параметры распределения по умолчанию
  DistributionParameters _createDefaultParameters(DistributionType type) {
    return switch (type) {
      DistributionType.binomial => const BinomialParameters(n: 10, p: 0.5),
      DistributionType.uniform => const UniformParameters(a: 0.0, b: 1.0),
      DistributionType.normal => const NormalParameters(m: 0, sigma: 1)
    };
  }
}