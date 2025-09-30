import 'package:equatable/equatable.dart';

import 'distribution_parameters.dart';
import 'generated_value.dart';
import 'interval.dart';

/// {@template generation_result}
/// Результат генерации с дополнительной метаинформацией.
/// {@endtemplate}
class GenerationResult with EquatableMixin {
  /// {@macro generation_result}
  const GenerationResult({
    required this.results,
    required this.parameters,
    required this.sampleSize,
    required this.frequencyDict,
    required this.cumulativeProbabilities,
    this.additionalInfo = const {}
  });

  /// Сгенерированные значения
  final List<GeneratedValue> results;

  /// Параметры распределения
  final DistributionParameters parameters;

  /// Размер выборки
  final int sampleSize;

  /// Словарь частот {значение: количество}
  final Map<int, int> frequencyDict;

  /// Кумулятивные вероятности [a_0, a_1, ..., a_n]
  final List<double> cumulativeProbabilities;

  /// Дополнительная информация
  final additionalInfo;

  /// Получает данные интервалов (для равномерного распределения)
  IntervalData? get intervalData {
    if (additionalInfo.containsKey('intervalData')) {
      return additionalInfo['intervalData'] as IntervalData;
    }
    return null;
  }

  /// Количество интервалов
  int? get numberOfIntervals {
    if (additionalInfo.containsKey('numberOfIntervals')) {
      return additionalInfo['numberOfIntervals'] as int;
    }
    return null;
  }

  /// Ширина интервала
  double? get intervalWidth {
    if (additionalInfo.containsKey('intervalWidth')) {
      return additionalInfo['intervalWidth'] as double;
    }
    return null;
  }
  
  @override
  List<Object> get props => [results, parameters, sampleSize, frequencyDict, cumulativeProbabilities, additionalInfo];
}