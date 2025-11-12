import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/distribution_bloc/distribution_bloc.dart';
import '../blocs/distribution_bloc/distribution_event.dart';
import '../blocs/distribution_bloc/distribution_state.dart';
import '../models/bayesian_classifier.dart';
import '../models/distribution_parameters.dart';
import '../models/distribution_type.dart';
import 'bayesian_results_screen.dart';

/// {@template bayesian_classifier_screen}
/// Экран для настройки байесовского классификатора
/// {@endtemplate}
class BayesianClassifierScreen extends StatefulWidget {
  /// {@macro bayesian_classifier_screen}
  const BayesianClassifierScreen({super.key});

  @override
  State<BayesianClassifierScreen> createState() => _BayesianClassifierScreenState();
}

class _BayesianClassifierScreenState extends State<BayesianClassifierScreen> {
  final _p1Controller = TextEditingController(text: '0.5');
  final _class1NameController = TextEditingController(text: 'Равномерный класс');
  final _class2NameController = TextEditingController(text: 'Нормальный класс');
  
  late BayesianClassifier _classifier;

  @override
  void initState() {
    super.initState();
    _classifier = BayesianClassifier.defaultParameters;
    _updateControllers();
  }

  @override
  void dispose() {
    _p1Controller.dispose();
    _class1NameController.dispose();
    _class2NameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DistributionBloc, DistributionState>(
      listener: (context, state) {
        if (state is BayesianClassificationSuccess) {
          _navigateToResultsScreen(context, state.classifier);
        }
        if (state is DistributionErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: ${state.error}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Байесовский классификатор'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildPriorProbabilities(),
                const SizedBox(height: 20),
                _buildClassParameters(1),
                const SizedBox(height: 20),
                _buildClassParameters(2),
                const SizedBox(height: 30),
                _buildClassifyButton(),
                _buildResetButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToResultsScreen(BuildContext context, BayesianClassifier classifier) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BayesianResultsScreen(classifier: classifier),
      ),
    );
  }
  
  /// Обновляет контроллеры значениями из классификатора
  void _updateControllers() {
    _p1Controller.text = _classifier.p1.toString();
    _class1NameController.text = _classifier.class1Name;
    _class2NameController.text = _classifier.class2Name;
  }

  Widget _buildPriorProbabilities() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Априорные вероятности',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _class1NameController,
                    decoration: const InputDecoration(
                      labelText: 'Название класса 1',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _classifier = _classifier.copyWith(class1Name: value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _p1Controller,
                    decoration: const InputDecoration(
                      labelText: 'Вероятность P(ω₁)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final p1 = double.tryParse(value);
                      if (p1 != null && p1 >= 0 && p1 <= 1) {
                        setState(() {
                          _classifier = _classifier.copyWith(
                            p1: p1,
                            p2: 1 - p1,
                          );
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _class2NameController,
              decoration: const InputDecoration(
                labelText: 'Название класса 2',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _classifier = _classifier.copyWith(class2Name: value);
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              'P(ω₂) = ${_classifier.p2.toStringAsFixed(3)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (!_classifier.isValid)
              Text(
                'Сумма вероятностей должна быть равна 1',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassParameters(int classNumber) {
    final isClass1 = classNumber == 1;
    final currentParams = isClass1 ? _classifier.class1 : _classifier.class2;
    final className = isClass1 ? _classifier.class1Name : _classifier.class2Name;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Параметры $className',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDistributionTypeDropdown(currentParams, isClass1),
            const SizedBox(height: 16),
            _buildSpecificParameters(currentParams, isClass1),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionTypeDropdown(DistributionParameters currentParams, bool isClass1) {
    return DropdownButton<DistributionType>(
      value: currentParams.type,
      isExpanded: true,
      items: const [
        DropdownMenuItem(
          value: DistributionType.normal,
          child: Text('Нормальное распределение'),
        ),
        DropdownMenuItem(
          value: DistributionType.uniform,
          child: Text('Равномерное распределение'),
        ),
      ],
      onChanged: (DistributionType? newType) {
        if (newType != null) {
          setState(() {
            final newParams = _createDefaultParameters(newType);
            _classifier = isClass1 
                ? _classifier.copyWith(class1: newParams)
                : _classifier.copyWith(class2: newParams);
            _updateControllers();
          });
        }
      },
    );
  }

  Widget _buildSpecificParameters(DistributionParameters parameters, bool isClass1) {
    return switch (parameters) {
      NormalParameters p => _buildNormalParameters(p, isClass1),
      UniformParameters p => _buildUniformParameters(p, isClass1),
      _ => const Text('Неизвестный тип распределения'),
    };
  }

  Widget _buildNormalParameters(NormalParameters parameters, bool isClass1) {
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
                final newParams = NormalParameters(m: m, sigma: parameters.sigma);
                _classifier = isClass1 
                    ? _classifier.copyWith(class1: newParams)
                    : _classifier.copyWith(class2: newParams);
              });
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
                final newParams = NormalParameters(m: parameters.m, sigma: sigma);
                _classifier = isClass1 
                    ? _classifier.copyWith(class1: newParams)
                    : _classifier.copyWith(class2: newParams);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildUniformParameters(UniformParameters parameters, bool isClass1) {
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
                final newParams = UniformParameters(a: a, b: parameters.b);
                _classifier = isClass1 
                    ? _classifier.copyWith(class1: newParams)
                    : _classifier.copyWith(class2: newParams);
              });
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
                final newParams = UniformParameters(a: parameters.a, b: b);
                _classifier = isClass1 
                    ? _classifier.copyWith(class1: newParams)
                    : _classifier.copyWith(class2: newParams);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildClassifyButton() {
    return ElevatedButton(
      onPressed: _classifier.isValid ? () {
        context.read<DistributionBloc>().add(
          BayesianClassificationRequest(_classifier),
        );
      } : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text(
        'Запустить классификацию',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  DistributionParameters _createDefaultParameters(DistributionType type) {
    return switch (type) {
      DistributionType.normal => const NormalParameters(m: 5.0, sigma: 1),
      DistributionType.uniform => const UniformParameters(a: 3.0, b: 5.0),
      _ => throw ArgumentError('Unsupported distribution type'),
    };
  }
  Widget _buildResetButton() {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _classifier = BayesianClassifier.defaultParameters;
          _updateControllers();
        });
      },
      child: const Text('Сбросить к значениям по умолчанию'),
    );
  }
}