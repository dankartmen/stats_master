import 'package:equatable/equatable.dart';

import 'distribution_parameters.dart';
import 'generated_value.dart';

/// {@template generation_result}
/// Результат генерации с дополнительной метаинформацией.
/// {@endtemplate}
class GenerationResult with EquatableMixin {
  /// {@macro generation_result}
  const GenerationResult({
    required this.values,
    required this.parameters,
    required this.sampleSize,
    required this.frequencyDict,
    required this.cumulativeProbabilities,
  });

  /// Сгенерированные значения
  final List<GeneratedValue> values;

  /// Параметры распределения
  final DistributionParameters parameters;

  /// Размер выборки
  final int sampleSize;

  /// Словарь частот {значение: количество}
  final Map<int, int> frequencyDict;

  /// Кумулятивные вероятности [a_0, a_1, ..., a_n]
  final List<double> cumulativeProbabilities;

  @override
  List<Object> get props => [values, parameters, sampleSize, frequencyDict, cumulativeProbabilities];
}