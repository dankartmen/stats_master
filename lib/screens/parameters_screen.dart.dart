import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stats_master/blocs/distribution_bloc/distribution_event.dart';
import 'package:stats_master/blocs/distribution_bloc/distribution_state.dart';
import '../blocs/distribution_bloc/distribution_bloc.dart';
import '../models/distribution_parameters.dart';

/// {@template parameters_screen}
/// Экран для ввода параметров биномиального распределения.
/// Позволяет пользователю задать количество испытаний, вероятность успеха
/// и размер выборки для генерации случайных значений.
/// {@endtemplate}
class ParametersScreen extends StatelessWidget {
  final DistributionParameters parameters;
  
  const ParametersScreen({super.key, required this.parameters});

  @override
  Widget build(BuildContext context) {
    return BlocListener<DistributionBloc, DistributionState>(
      listener: (context,state){
        if (state is DistributionErrorState){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Параметры распределений'),),
        body: Padding(padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildParameterInputs(parameters),
            const SizedBox(height: 20),
            BlocBuilder<DistributionBloc,DistributionState>(
              builder: (context,state){
                return ElevatedButton(
                  onPressed: state is DistributionLoadInProgress ? null : (){
                      context.read<DistributionBloc>().add(
                        DistributionGenerateRequest(100),
                      );
                  }, 
                  child: state is DistributionLoadInProgress ? const CircularProgressIndicator()
                                                             : const Text('Сгенерировать'),
                );
              },
            ),
          ],
        ),),
      ),
    );
  }
Widget _buildParameterInputs(DistributionParameters parameters) {
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
          decoration: const InputDecoration(labelText: 'Количество испытаний (n)'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final n = int.tryParse(value);
            if (n != null) {
              // Dispatch parameter change event
            }
          },
        ),
        TextFormField(
          initialValue: parameters.p.toString(),
          decoration: const InputDecoration(labelText: 'Вероятность успеха (p)'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final p = double.tryParse(value);
            if (p != null) {
              // Dispatch parameter change event
            }
          },
        ),
      ],
    );
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

