import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/distribution_bloc/distribution_event.dart';
import '../blocs/distribution_bloc/distribution_state.dart';
import 'results_screen.dart';
import '../blocs/distribution_bloc/distribution_bloc.dart';
import '../models/distribution_parameters.dart';

/// {@template parameters_screen}
/// Экран для ввода параметров биномиального распределения.
/// Позволяет пользователю задать количество испытаний, вероятность успеха
/// и размер выборки для генерации случайных значений.
/// {@endtemplate}
class ParametersScreen extends StatefulWidget {
  final DistributionParameters parameters;
  
  const ParametersScreen({super.key, required this.parameters});

  @override
  State<StatefulWidget> createState() => _ParametersScreenState();
}
class _ParametersScreenState extends State<ParametersScreen>{
  /// размер выборки
  final _sampleSizeController = TextEditingController(text: '100');
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
          title: _currentParameters is BinomialParameters ? const Text('Параметры биноминального распределения')
                                                          : const Text('Параматры равномерного распределения'),
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

void _navigateBack(BuildContext context) {
    // Сбрасываем состояние при возврате на предыдущий экран
    context.read<DistributionBloc>().add(DistributionReset());
    Navigator.of(context).pop();
  }

void _navigateToResultsScreen(BuildContext context, DistributionGenerationSuccess state) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<DistributionBloc>(),
          child: ResultsScreen(
            parameters: state.parameters,
            generatedValues: state.generatedValues,
            sampleSize: state.sampleSize,
            cumulativeProbabilities: state.cumulativeProbabilities,
            frequencyDict: state.frequencyDict,
          ),
        ),
      ),
    ).then((_) {
      if(context.mounted) context.read<DistributionBloc>().add(DistributionResultsClosed());
    });
  }

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
Widget _buildParameterInputs(DistributionParameters parameters) {
    return Column(
      children: [
        _buildSpecificParameterInputs(parameters),
        _buildSimpleSizeInput(),
      ],
    );
  }

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
Widget _buildSpecificParameterInputs(DistributionParameters parameters) {
    return switch (parameters) {
      BinomialParameters p => _buildBinomialParameters(p),
      UniformParameters p => _buildUniformParameters(p),
      _ => const Text('Неизвестный тип параметров'),
    };
  }

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

  /// Отправляем блоку эвент о смене параметров
  void _dispatchParametersChange(){
    if (_currentParameters != null){
      context.read<DistributionBloc>().add(DistributionParametersChanged(_currentParameters!));
    }
  }

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
              // Dispatch parameter change event
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
              // Dispatch parameter change event
            }
          },
        ),
      ],
    );
  }
}

