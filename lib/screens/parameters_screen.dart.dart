import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/distribution_bloc/distribution_event.dart';
import '../blocs/distribution_bloc/distribution_state.dart';
import 'results_screen.dart';
import '../blocs/distribution_bloc/distribution_bloc.dart';
import '../models/distribution_parameters.dart';
import 'saved_results_screen.dart';

/// {@template parameters_screen}
/// Экран для ввода параметров биномиального распределения.
/// Позволяет пользователю задать количество испытаний, вероятность успеха
/// и размер выборки для генерации случайных значений.
/// {@endtemplate}
class ParametersScreen extends StatefulWidget {
  /// Параметры распределения, которые можно отредактировать.
  final DistributionParameters parameters;
  
  /// {@macro parameters_screen}
  /// Принимает:
  /// - [parameters] - начальные параметры распределения
  const ParametersScreen({super.key, required this.parameters});

  @override
  State<StatefulWidget> createState() => _ParametersScreenState();
}

/// {@template _parameters_screen_state}
/// Состояние экрана ввода параметров распределения.
/// Управляет вводом параметров и взаимодействием с DistributionBloc.
/// {@endtemplate}
class _ParametersScreenState extends State<ParametersScreen>{
  /// Контроллер для ввода размера выборки
  final _sampleSizeController = TextEditingController(text: '200');

  /// Текущин параметры распределения
  DistributionParameters? _currentParameters;

  @override
  void initState() {
    super.initState();
    _currentParameters = widget.parameters;
  }

  @override
  void dispose(){
    _sampleSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DistributionBloc, DistributionState>(
      listener: (context,state){
        if (state is DistributionGenerationSuccess){
          _navigateToResultsScreen(context,state);
        }
        if (state is DistributionErrorState){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Параметры распределения'), 
          actions: [IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => _navigateToSavedResults(context),
            tooltip: 'Загрузить сохраненный результат',
          ),],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateBack(context),
          ),      
        ),
        body: Padding(padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildParameterInputs(_currentParameters!),
              const SizedBox(height: 20),
              _buildButtonForGeneration(),
            ],
          ),
        ),
      ),
    );
  }

  /// Переход к экрану сохраненных результатов.
  /// Принимает:
  /// - [context] - контекст построения виджета
  void _navigateToSavedResults(BuildContext context) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SavedResultsScreen(),
        ),
      );
    }

  /// Обработка возврата на предыдущий экран.
  /// Сбрасывает состояние DistributionBloc.
  /// Принимает:
  /// - [context] - контекст построения виджета
  void _navigateBack(BuildContext context) {
    // Сбрасываем состояние при возврате на предыдущий экран
    context.read<DistributionBloc>().add(DistributionReset());
    Navigator.of(context).pop();
  }

  /// Переход к экрану результатов генерации.
  /// Принимает:
  /// - [context] - контекст построения виджета
  /// - [state] - состояние успешной генерации
  void _navigateToResultsScreen(BuildContext context, DistributionGenerationSuccess state) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: context.read<DistributionBloc>(),
            child: ResultsScreen(
              generatedResult: state.generatedResult,
            ),
          ),
        ),
      ).then((_) {
        if(context.mounted) context.read<DistributionBloc>().add(DistributionResultsClosed());
      });
    }

  /// Строит кнопку для запуска генерации значений.
  /// Возвращает:
  /// - [Widget] - кнопку генерации с индикатором загрузки
  Widget _buildButtonForGeneration(){
    return Column(
      children: [
        BlocBuilder<DistributionBloc,DistributionState>(
          builder: (context,state){
            final isValid = _currentParameters != null && _sampleSizeController.text.isNotEmpty;
            return ElevatedButton(
              onPressed: (state is DistributionLoadInProgress || !isValid) ? null : (){
                  context.read<DistributionBloc>().add(
                    DistributionGenerateRequest(int.tryParse(_sampleSizeController.text)!),
                  );
              }, 
              child: state is DistributionLoadInProgress
                ? const Row(
                  crossAxisAlignment: CrossAxisAlignment.center, 
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 8,),
                    Text('Генерация...'),
                  ],
                )
                : const Text('Сгенерировать'),
            );
          },
        ),
      ],
    );
  }

  /// Строит поля ввода параметров распределения.
  /// Принимает:
  /// - [parameters] - параметры распределения
  /// Возвращает:
  /// - [Widget] - колонку с полями ввода
  Widget _buildParameterInputs(DistributionParameters parameters) {
      return Column(
        children: [
          _buildSpecificParameterInputs(parameters),
          _buildSimpleSizeInput(),
        ],
      );
    }

  /// Строит поле ввода размера выборки.
  /// Возвращает:
  /// - [Widget] - поле ввода размера выборки
  Widget _buildSimpleSizeInput(){
    return Column(
      children: [
        TextFormField(
          controller: _sampleSizeController,
          decoration: InputDecoration(labelText: 'Размер выборки', helperText: 'Количество генерируемых значений'),
          keyboardType: TextInputType.number,
          validator:(value) {
            if (value == null || value.isEmpty) return 'Введите размер выборки';
            final intValue = int.tryParse(value);
            if (intValue == null || intValue <= 0) return 'Размер должен быть положительным числом';
            return null;
          },
        )
      ],
    );
  }

  /// Строит специфические поля ввода для типа распределения.
  /// Принимает:
  /// - [parameters] - параметры распределения
  /// Возвращает:
  /// - [Widget] - соответствующие поля ввода параметров
  Widget _buildSpecificParameterInputs(DistributionParameters parameters) {
      return switch (parameters) {
        BinomialParameters p => _buildBinomialParameters(p),
        UniformParameters p => _buildUniformParameters(p),
        NormalParameters p => _buildNormalParameters(p),
        _ => const Text('Неизвестный тип параметров'),
      };
    }

  // Строит поля ввода для биномиального распределения.
  /// Принимает:
  /// - [parameters] - параметры биномиального распределения
  /// Возвращает:
  /// - [Widget] - поля ввода количества испытаний и вероятности успеха
  Widget _buildBinomialParameters(BinomialParameters parameters) {
    return Column(
      children: [
        TextFormField(
          initialValue: parameters.n.toString(),
          decoration: const InputDecoration(labelText: 'Количество испытаний (n)', helperText: 'Целое положительное число'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final n = int.tryParse(value);
            if (n != null ) {
              setState(() {
                _currentParameters = BinomialParameters(
                  n: n,
                  p: parameters.p,
                );
              });
              _dispatchParametersChange();
            }
          },
        ),
        TextFormField(
          initialValue: parameters.p.toString(),
          decoration: const InputDecoration(labelText: 'Вероятность успеха (p)', helperText: 'Число от 0 до 1'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final p = double.tryParse(value);
            if (p != null) {
              setState(() {
                _currentParameters = BinomialParameters(
                  n: parameters.n,
                  p: p,
                );
              });
              _dispatchParametersChange();
            }
          },
        ),
      ],
    );
  }

  /// Отправляет событие изменения параметров в DistributionBloc
  void _dispatchParametersChange(){
    if (_currentParameters != null){
      context.read<DistributionBloc>().add(DistributionParametersChanged(_currentParameters!));
    }
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
          decoration: const InputDecoration(labelText: 'Нижняя граница (a)'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final a = double.tryParse(value);
            if (a != null) {
              setState(() {
                _currentParameters = UniformParameters(
                  a: a,
                  b: parameters.b,
                );
              });
              _dispatchParametersChange();
            }
          },
        ),
        TextFormField(
          initialValue: parameters.b.toString(),
          decoration: const InputDecoration(labelText: 'Верхняя граница (b)'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final b = double.tryParse(value);
            if (b != null) {
              setState(() {
                _currentParameters = UniformParameters(
                  a: parameters.a,
                  b: b,
                );
              });
              _dispatchParametersChange();
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
  /// - [Widget] - поля ввода среднего значения и стандартного отклонения
  Widget _buildNormalParameters(NormalParameters parameters) {
    return Column(
      children: [
        TextFormField(
          initialValue: parameters.m.toString(),
          decoration: const InputDecoration(labelText: 'Среднее значение (m)'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final m = double.tryParse(value);
            if (m != null) {
              setState(() {
                _currentParameters = NormalParameters(
                  m: m,
                  sigma: parameters.sigma,
                );
              });
              _dispatchParametersChange();
            }
          },
        ),
        TextFormField(
          initialValue: parameters.sigma.toString(),
          decoration: const InputDecoration(labelText: 'Стандартное отклонение σ'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final sigma = double.tryParse(value);
            if (sigma != null) {
              setState(() {
                _currentParameters = NormalParameters(
                  m: parameters.m,
                  sigma: sigma,
                );
              });
              _dispatchParametersChange();
            }
          },
        ),
      ],
    );
  }
}

