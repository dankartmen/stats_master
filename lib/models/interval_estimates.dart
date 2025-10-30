import 'package:equatable/equatable.dart';

/// {@template confidence_interval}
/// Доверительный интервал для параметра распределения.
/// {@endtemplate}
class ConfidenceInterval with EquatableMixin {
  /// {@macro confidence_interval}
  const ConfidenceInterval({
    required this.lowerBound,
    required this.upperBound,
    required this.confidenceLevel,
    required this.parameterName,
  });

  /// Нижняя граница интервала
  final double lowerBound;

  /// Верхняя граница интервала
  final double upperBound;

  /// Уровень доверия (0.95, 0.99 и т.д.)
  final double confidenceLevel;

  /// Название параметра
  final String parameterName;

  /// Ширина интервала
  double get width => upperBound - lowerBound;

  /// Центр интервала
  double get center => (lowerBound + upperBound) / 2;

  @override
  List<Object> get props => [
        lowerBound,
        upperBound,
        confidenceLevel,
        parameterName,
      ];

  @override
  String toString() {
    return '$parameterName: [$lowerBound, $upperBound] (уровень доверия: ${(confidenceLevel * 100).toInt()}%)';
  }
}

/// {@template normal_interval_estimates}
/// Интервальные оценки для нормального распределения.
/// {@endtemplate}
class NormalIntervalEstimates with EquatableMixin {
  /// {@macro normal_interval_estimates}
  const NormalIntervalEstimates({
    required this.sigmaKnown,
    required this.sigmaUnknown,
    required this.varianceInterval,
    required this.sampleSize,
    required this.sampleMean,
    required this.sampleSigma,
    required this.confidenceLevel,
  });

  /// Доверительный интервал для мат. ожидания (σ известна)
  final ConfidenceInterval sigmaKnown;

  /// Доверительный интервал для мат. ожидания (σ неизвестна)
  final ConfidenceInterval sigmaUnknown;

  /// Доверительный интервал для дисперсии
  final ConfidenceInterval varianceInterval;

  /// Размер выборки
  final int sampleSize;

  /// Выборочное среднее
  final double sampleMean;

  /// Выборочное стандартное отклонение
  final double sampleSigma;

  /// Уровень доверия
  final double confidenceLevel;

  @override
  List<Object> get props => [
        sigmaKnown,
        sigmaUnknown,
        varianceInterval,
        sampleSize,
        sampleMean,
        sampleSigma,
        confidenceLevel,
      ];
}