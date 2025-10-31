// Новый файл: lib/widgets/parameter_inputs.dart

import 'package:flutter/material.dart';
import '../models/distribution_parameters.dart';

/// {@template binomial_parameter_inputs}
/// Виджет для ввода параметров биномиального распределения.
/// {@endtemplate}
class BinomialParameterInputs extends StatelessWidget {
  /// {@macro binomial_parameter_inputs}
  /// Принимает:
  /// - [params] - текущие параметры
  /// - [onChanged] - callback для обновления параметров
  const BinomialParameterInputs({
    super.key,
    required this.params,
    required this.onChanged,
  });

  final BinomialParameters params;
  final ValueChanged<BinomialParameters> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          initialValue: params.n.toString(),
          decoration: const InputDecoration(
            labelText: 'Количество испытаний (n)',
            helperText: 'Целое положительное число',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            final n = int.tryParse(value ?? '');
            if (n == null || n <= 0) return 'n должно быть положительным';
            return null;
          },
          onChanged: (value) {
            final n = int.tryParse(value);
            if (n != null && n > 0) {
              onChanged(BinomialParameters(n: n, p: params.p));
            }
          },
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: params.p.toString(),
              decoration: const InputDecoration(
                labelText: 'Вероятность успеха (p)',
                helperText: 'Число от 0 до 1',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final p = double.tryParse(value ?? '');
                if (p == null || p < 0 || p > 1) return 'p должно быть от 0 до 1';
                return null;
              },
              onChanged: (value) {
                final p = double.tryParse(value);
                if (p != null && p >= 0 && p <= 1) {
                  onChanged(BinomialParameters(n: params.n, p: p));
                }
              },
            ),
            Slider(
              value: params.p,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: params.p.toStringAsFixed(2),
              onChanged: (value) => onChanged(BinomialParameters(n: params.n, p: value)),
            ),
          ],
        ),
      ],
    );
  }
}

/// {@template uniform_parameter_inputs}
/// Виджет для ввода параметров равномерного распределения.
/// {@endtemplate}
class UniformParameterInputs extends StatelessWidget {
  /// {@macro uniform_parameter_inputs}
  /// Принимает:
  /// - [params] - текущие параметры
  /// - [onChanged] - callback для обновления параметров
  const UniformParameterInputs({
    super.key,
    required this.params,
    required this.onChanged,
  });

  final UniformParameters params;
  final ValueChanged<UniformParameters> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          initialValue: params.a.toString(),
          decoration: const InputDecoration(
            labelText: 'Нижняя граница (a)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final a = double.tryParse(value);
            if (a != null && a < params.b) {
              onChanged(UniformParameters(a: a, b: params.b));
            }
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: params.b.toString(),
          decoration: const InputDecoration(
            labelText: 'Верхняя граница (b)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final b = double.tryParse(value);
            if (b != null && b > params.a) {
              onChanged(UniformParameters(a: params.a, b: b));
            }
          },
        ),
      ],
    );
  }
}

/// {@template normal_parameter_inputs}
/// Виджет для ввода параметров нормального распределения.
/// {@endtemplate}
class NormalParameterInputs extends StatelessWidget {
  /// {@macro normal_parameter_inputs}
  /// Принимает:
  /// - [params] - текущие параметры
  /// - [onChanged] - callback для обновления параметров
  const NormalParameterInputs({
    super.key,
    required this.params,
    required this.onChanged,
  });

  final NormalParameters params;
  final ValueChanged<NormalParameters> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          initialValue: params.m.toString(),
          decoration: const InputDecoration(
            labelText: 'Среднее значение (m)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final m = double.tryParse(value);
            if (m != null) {
              onChanged(NormalParameters(m: m, sigma: params.sigma));
            }
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: params.sigma.toString(),
          decoration: const InputDecoration(
            labelText: 'Стандартное отклонение σ',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            final sigma = double.tryParse(value ?? '');
            if (sigma == null || sigma <= 0) return 'σ должно быть положительным';
            return null;
          },
          onChanged: (value) {
            final sigma = double.tryParse(value);
            if (sigma != null && sigma > 0) {
              onChanged(NormalParameters(m: params.m, sigma: sigma));
            }
          },
        ),
      ],
    );
  }
}