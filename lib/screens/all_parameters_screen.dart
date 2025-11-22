import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/distribution_bloc/distribution_bloc.dart';
import '../blocs/distribution_bloc/distribution_event.dart';
import '../blocs/distribution_bloc/distribution_state.dart';
import '../models/all_distribution_parameters.dart';
import '../models/distribution_parameters.dart';
import 'all_parameter_estimation_screen.dart';

/// {@template all_parameters_screen}
/// Экран для ввода параметров всех распределений.
/// Позволяет пользователю задать параметры биномиального, равномерного
/// и нормального распределений, а также размеры выборок для каждого из них.
/// {@endtemplate}
class AllParametersScreen extends StatefulWidget {
  /// {@macro all_parameters_screen}
  const AllParametersScreen({super.key});

  @override
  State<AllParametersScreen> createState() => _AllParametersScreenState();
}

/// {@template _all_parameters_screen_state}
/// Состояние экрана ввода параметров всех распределений.
/// Управляет вводом параметров распределений и взаимодействием с DistributionBloc.
/// {@endtemplate}
class _AllParametersScreenState extends State<AllParametersScreen> {
  /// Контроллер для ввода размера выборки биномиального распределения
  final _binomialSampleSizeController = TextEditingController(text: '100');

  /// Контроллер для ввода размера выборки равномерного распределения
  final _uniformSampleSizeController = TextEditingController(text: '200');

  /// Контроллер для ввода размера выборки нормального распределения
  final _normalSampleSizeController = TextEditingController(text: '200');

  /// Текущие параметры всех распределений
  late AllDistributionParameters _currentParameters;

  @override
  void initState() {
    super.initState();
    _currentParameters = AllDistributionParameters.defaultParameters;
  }

  @override
  void dispose() {
    _binomialSampleSizeController.dispose();
    _uniformSampleSizeController.dispose();
    _normalSampleSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DistributionBloc, DistributionState>(
      listener: (context, state) {
        if (state is AllEstimationSuccess) {
          _navigateToAllEstimationScreen(context, state);
        }
        if (state is DistributionErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        }
      },
      child:  Scaffold(
        appBar: AppBar(
          title: const Text('Параметры распределений'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Биномиальное распределение
                _buildDistributionCard(
                  title: 'Биномиальное распределение',
                  icon: Icons.bar_chart,
                  color: Colors.blue,
                  children: [
                    _buildBinomialParameters(_currentParameters.binomial),
                    const SizedBox(height: 16),
                    _buildSampleSizeInput(
                      controller: _binomialSampleSizeController,
                      label: 'Размер выборки для биномиального распределения',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Равномерное распределение
                _buildDistributionCard(
                  title: 'Равномерное распределение',
                  icon: Icons.show_chart,
                  color: Colors.green,
                  children: [
                    _buildUniformParameters(_currentParameters.uniform),
                    const SizedBox(height: 16),
                    _buildSampleSizeInput(
                      controller: _uniformSampleSizeController,
                      label: 'Размер выборки для равномерного распределения',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Нормальное распределение
                _buildDistributionCard(
                  title: 'Нормальное распределение',
                  icon: Icons.show_chart,
                  color: Colors.orange,
                  children: [
                    _buildNormalParameters(_currentParameters.normal),
                    const SizedBox(height: 16),
                    _buildSampleSizeInput(
                      controller: _normalSampleSizeController,
                      label: 'Размер выборки для нормального распределения',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Кнопка оценки
                _buildEstimateButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Переход к экрану оценки параметров.
  /// Принимает:
  /// - [context] - контекст построения виджета
  /// - [state] - состояние успешной оценки параметров
  void _navigateToAllEstimationScreen(BuildContext context, AllEstimationSuccess state) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<DistributionBloc>(),
          child: const AllParameterEstimationScreen(),
        ),
      ),
    );
  }

  /// Строит карточку распределения.
  /// Принимает:
  /// - [title] - заголовок карточки
  /// - [icon] - иконка распределения
  /// - [color] - цвет акцента
  /// - [children] - дочерние виджеты
  /// Возвращает:
  /// - [Widget] - карточку распределения
  Widget _buildDistributionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Строит поле ввода размера выборки.
  /// Принимает:
  /// - [controller] - контроллер текстового поля
  /// - [label] - метка поля
  /// Возвращает:
  /// - [Widget] - поле ввода размера выборки
  Widget _buildSampleSizeInput({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final sampleSize = int.tryParse(value);
        if (sampleSize != null && sampleSize > 0) {
          _updateParameters();
        }
      },
    );
  }

  /// Строит поля ввода для биномиального распределения.
  /// Принимает:
  /// - [parameters] - параметры биномиального распределения
  /// Возвращает:
  /// - [Widget] - поля ввода количества испытаний и вероятности успеха
  Widget _buildBinomialParameters(BinomialParameters parameters) {
    return Column(
      children: [
        TextFormField(
          initialValue: parameters.n.toString(),
          decoration: const InputDecoration(
            labelText: 'Количество испытаний (n)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final n = int.tryParse(value);
            if (n != null && n > 0) {
              setState(() {
                _currentParameters = _currentParameters.copyWith(
                  binomial: BinomialParameters(n: n, p: parameters.p),
                );
              });
              _updateParameters();
            }
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: parameters.p.toString(),
          decoration: const InputDecoration(
            labelText: 'Вероятность успеха (p)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final p = double.tryParse(value);
            if (p != null && p >= 0 && p <= 1) {
              setState(() {
                _currentParameters = _currentParameters.copyWith(
                  binomial: BinomialParameters(n: parameters.n, p: p),
                );
              });
              _updateParameters();
            }
          },
        ),
      ],
    );
  }

  /// Строит поля ввода для равномерного распределения.
  /// Принимает:
  /// - [parameters] - параметры равномерного распределения
  /// Возвращает:
  /// - [Widget] - поля ввода нижней и верхней границ
  Widget _buildUniformParameters(UniformParameters parameters) {
    return Column(
      children: [
        TextFormField(
          initialValue: parameters.a.toString(),
          decoration: const InputDecoration(
            labelText: 'Нижняя граница (a)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final a = double.tryParse(value);
            if (a != null) {
              setState(() {
                _currentParameters = _currentParameters.copyWith(
                  uniform: UniformParameters(a: a, b: parameters.b),
                );
              });
              _updateParameters();
            }
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: parameters.b.toString(),
          decoration: const InputDecoration(
            labelText: 'Верхняя граница (b)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final b = double.tryParse(value);
            if (b != null && b > parameters.a) {
              setState(() {
                _currentParameters = _currentParameters.copyWith(
                  uniform: UniformParameters(a: parameters.a, b: b),
                );
              });
              _updateParameters();
            }
          },
        ),
      ],
    );
  }

  /// Строит поля ввода для нормального распределения.
  /// Принимает:
  /// - [parameters] - параметры нормального распределения
  /// Возвращает:
  /// - [Widget] - поля ввода математического ожидания и стандартного отклонения
  Widget _buildNormalParameters(NormalParameters parameters) {
    return Column(
      children: [
        TextFormField(
          initialValue: parameters.m.toString(),
          decoration: const InputDecoration(
            labelText: 'Математическое ожидание (m)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final m = double.tryParse(value);
            if (m != null) {
              setState(() {
                _currentParameters = _currentParameters.copyWith(
                  normal: NormalParameters(m: m, sigma: parameters.sigma),
                );
              });
              _updateParameters();
            }
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: parameters.sigma.toString(),
          decoration: const InputDecoration(
            labelText: 'Стандартное отклонение (σ)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final sigma = double.tryParse(value);
            if (sigma != null && sigma > 0) {
              setState(() {
                _currentParameters = _currentParameters.copyWith(
                  normal: NormalParameters(m: parameters.m, sigma: sigma),
                );
              });
              _updateParameters();
            }
          },
        ),
      ],
    );
  }

  /// Строит кнопку для запуска оценки параметров.
  /// Возвращает:
  /// - [Widget] - кнопку оценки с индикатором загрузки
  Widget _buildEstimateButton() {
    return BlocBuilder<DistributionBloc, DistributionState>(
      builder: (context, state) {
        final isValid = _binomialSampleSizeController.text.isNotEmpty &&
            _uniformSampleSizeController.text.isNotEmpty &&
            _normalSampleSizeController.text.isNotEmpty;

        final binomialSampleSize = int.tryParse(_binomialSampleSizeController.text);
        final uniformSampleSize = int.tryParse(_uniformSampleSizeController.text);
        final normalSampleSize = int.tryParse(_normalSampleSizeController.text);

        final areSampleSizesValid = binomialSampleSize != null && 
            binomialSampleSize > 0 &&
            uniformSampleSize != null && 
            uniformSampleSize > 0 &&
            normalSampleSize != null && 
            normalSampleSize > 0;

        final isButtonEnabled = state is! DistributionLoadInProgress && 
            isValid && 
            areSampleSizesValid;

        return ElevatedButton(
          onPressed: isButtonEnabled ? () {
            print('Кнопка: Нажата оценка параметров');
            
            // ВАЖНО: Сначала обновляем параметры, чтобы установить состояние AllParametersInput
            _updateParameters();
            
            // Даем время BLoC обновиться
            Future.delayed(const Duration(milliseconds: 100), () {
              // Теперь запускаем оценку
              context.read<DistributionBloc>().add(
                EstimateAllParametersRequest(),
              );
            });
          } : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: state is DistributionLoadInProgress
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 8),
                    Text('Вычисление оценок...'),
                  ],
                )
              : const Text(
                  'Оценить параметры всех распределений',
                  style: TextStyle(fontSize: 16),
                ),
        );
      },
    );
  }

  /// Обновляет параметры в DistributionBloc.
  void _updateParameters() {
    final binomialSampleSize = int.tryParse(_binomialSampleSizeController.text);
    final uniformSampleSize = int.tryParse(_uniformSampleSizeController.text);
    final normalSampleSize = int.tryParse(_normalSampleSizeController.text);

    if (binomialSampleSize != null &&
        uniformSampleSize != null &&
        normalSampleSize != null) {
      final updatedParameters = _currentParameters.copyWith(
        binomialSampleSize: binomialSampleSize,
        uniformSampleSize: uniformSampleSize,
        normalSampleSize: normalSampleSize,
      );

      context.read<DistributionBloc>().add(
            AllParametersChanged(updatedParameters),
          );
    }
  }
}