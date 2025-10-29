import 'dart:math';

import '../../models/all_distribution_parameters.dart';
import '../../models/distribution_parameters.dart';
import '../../models/generation_result.dart';
import '../../models/parameter_estimates.dart';
import '../../repositories/distribution_repository.dart';

/// {@template estimation_calculator}
/// Калькулятор для вычисления оценок параметров распределений.
/// {@endtemplate}
class EstimationCalculator {
  final DistributionRepository _repository;

  /// {@macro estimation_calculator}
  EstimationCalculator(this._repository);

  /// Вычисляет оценки параметров для всех распределений.
  /// Принимает:
  /// - [parameters] - параметры всех распределений
  /// Возвращает:
  /// - [AllParameterEstimates] - рассчитанные оценки параметров
  Future<AllParameterEstimates> calculateAllEstimates(
      AllDistributionParameters parameters) async {
    // Генерируем данные для всех распределений
    final binomialResult = await _repository.generateResults(
      parameters: parameters.binomial,
      sampleSize: parameters.binomialSampleSize,
    );

    final uniformResult = await _repository.generateResults(
      parameters: parameters.uniform,
      sampleSize: parameters.uniformSampleSize,
    );

    final normalResult = await _repository.generateResults(
      parameters: parameters.normal,
      sampleSize: parameters.normalSampleSize,
    );

    // Вычисляем оценки для каждого распределения
    final binomialEstimate = _calculateSingleEstimate(
      binomialResult,
      'Биномиальное',
    );

    final uniformEstimate = _calculateSingleEstimate(
      uniformResult,
      'Равномерное',
    );

    final normalEstimate = _calculateSingleEstimate(
      normalResult,
      'Нормальное',
    );

    final totalSampleSize = parameters.binomialSampleSize +
        parameters.uniformSampleSize +
        parameters.normalSampleSize;

    return AllParameterEstimates(
      binomial: binomialEstimate,
      uniform: uniformEstimate,
      normal: normalEstimate,
      totalSampleSize: totalSampleSize,
    );
  }

  /// Вычисляет оценки параметров для одного распределения.
  DistributionEstimate _calculateSingleEstimate(
    GenerationResult result,
    String distributionName,
  ) {
    final values = result.results.map((v) => v.value.toDouble()).toList();
    final parameters = result.parameters;
    final sampleSize = result.sampleSize;

    // Выборочное среднее
    final sampleMean = _calculateSampleMean(values);

    // Выборочная дисперсия
    final sampleVariance = _calculateSampleVariance(values, sampleMean);

    // Исправленная выборочная дисперсия
    final correctedSampleVariance =
        _calculateCorrectedSampleVariance(sampleVariance, sampleSize);

    // Выборочное стандартное отклонение
    final sampleSigma = _calculateSampleSigma(sampleVariance);

    // Теоретические значения
    final (theoreticalMean, theoreticalVariance, theoreticalSigma) =
        _calculateTheoreticalValues(parameters);

    return DistributionEstimate(
      distributionName: distributionName,
      sampleMean: sampleMean,
      theoreticalMean: theoreticalMean,
      sampleVariance: sampleVariance,
      correctedSampleVariance: correctedSampleVariance,
      theoreticalVariance: theoreticalVariance,
      sampleSigma: sampleSigma,
      theoreticalSigma: theoreticalSigma,
      sampleSize: sampleSize,
    );
  }

  /// Вычисляет выборочное среднее.
  double _calculateSampleMean(List<double> values) {
    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }

  /// Вычисляет выборочную дисперсию.
  double _calculateSampleVariance(List<double> values, double sampleMean) {
    final squaredDeviations =
        values.map((x) => (x - sampleMean) * (x - sampleMean));
    final sumSquaredDeviations = squaredDeviations.reduce((a, b) => a + b);
    return sumSquaredDeviations / values.length;
  }

  /// Вычисляет исправленную выборочную дисперсию.
  double _calculateCorrectedSampleVariance(
      double sampleVariance, int sampleSize) {
    return (sampleSize * sampleVariance) / (sampleSize - 1);
  }

  /// Вычисляет выборочное стандартное отклонение.
  double _calculateSampleSigma(double sampleVariance) {
    return sqrt(sampleVariance);
  }

  /// Вычисляет теоретические значения параметров.
  (double, double, double) _calculateTheoreticalValues(
      DistributionParameters parameters) {
    return switch (parameters) {
      BinomialParameters p => (
          p.n * p.p, // μ = n * p
          p.n * p.p * (1 - p.p), // σ² = n * p * (1 - p)
          sqrt(p.n * p.p * (1 - p.p)) // σ = √(n * p * (1 - p))
        ),
      UniformParameters p => (
          (p.a + p.b) / 2, // μ = (a + b) / 2
          (p.b - p.a) * (p.b - p.a) / 12, // σ² = (b - a)² / 12
          (p.b - p.a) / sqrt(12) // σ = (b - a) / √12
        ),
      NormalParameters p => (
          p.m, // μ = m
          p.sigma * p.sigma, // σ² = sigma²
          p.sigma // σ = sigma
        ),
      _ => throw ArgumentError('Неизвестный тип параметров'),
    };
  }
}