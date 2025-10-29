import 'package:equatable/equatable.dart';

/// {@template distribution_estimate}
/// Оценки параметров для одного распределения.
/// {@endtemplate}
class DistributionEstimate with EquatableMixin {
  /// {@macro distribution_estimate}
  const DistributionEstimate({
    required this.distributionName,
    required this.sampleMean,
    required this.theoreticalMean,
    required this.sampleVariance,
    required this.correctedSampleVariance,
    required this.theoreticalVariance,
    required this.sampleSigma,
    required this.theoreticalSigma,
    required this.sampleSize,
  });

  /// Название распределения
  final String distributionName;

  /// Выборочное среднее (оценка мат. ожидания)
  final double sampleMean;

  /// Теоретическое мат. ожидание
  final double theoreticalMean;

  /// Выборочная дисперсия
  final double sampleVariance;

  /// Исправленная выборочная дисперсия
  final double correctedSampleVariance;

  /// Теоретическая дисперсия
  final double theoreticalVariance;

  /// Выборочное стандартное отклонение
  final double sampleSigma;

  /// Теоретическое стандартное отклонение
  final double theoreticalSigma;

  /// Размер выборки
  final int sampleSize;

  @override
  List<Object> get props => [
        distributionName,
        sampleMean,
        theoreticalMean,
        sampleVariance,
        correctedSampleVariance,
        theoreticalVariance,
        sampleSigma,
        theoreticalSigma,
        sampleSize,
      ];
}

/// {@template all_parameter_estimates}
/// Оценки параметров для всех распределений.
/// {@endtemplate}
class AllParameterEstimates with EquatableMixin {
  /// {@macro all_parameter_estimates}
  const AllParameterEstimates({
    required this.binomial,
    required this.uniform,
    required this.normal,
    required this.totalSampleSize,
  });

  /// Оценки для биномиального распределения
  final DistributionEstimate binomial;

  /// Оценки для равномерного распределения
  final DistributionEstimate uniform;

  /// Оценки для нормального распределения
  final DistributionEstimate normal;

  /// Общий размер всех выборок
  final int totalSampleSize;

  @override
  List<Object> get props => [binomial, uniform, normal, totalSampleSize];
}