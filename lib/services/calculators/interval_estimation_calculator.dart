import 'dart:math';

import '../../models/interval_estimates.dart';


/// {@template interval_estimation_calculator}
/// Калькулятор для вычисления интервальных оценок нормального распределения.
/// {@endtemplate}
class IntervalEstimationCalculator {
  /// {@macro interval_estimation_calculator}
  const IntervalEstimationCalculator();

  /// Вычисляет интервальные оценки для нормального распределения.
  /// Принимает:
  /// - [sampleMean] - выборочное среднее
  /// - [sampleSigma] - выборочное стандартное отклонение
  /// - [sampleSize] - размер выборки
  /// - [theoreticalSigma] - теоретическое стандартное отклонение (если известно)
  /// - [confidenceLevel] - уровень доверия (по умолчанию 0.95)
  /// Возвращает:
  /// - [NormalIntervalEstimates] - интервальные оценки
  NormalIntervalEstimates calculateNormalIntervals({
    required double sampleMean,
    required double sampleSigma,
    required int sampleSize,
    double? theoreticalSigma,
    double confidenceLevel = 0.95,
  }) {
    // Крит. точки распределений(табличные)
    final uAlpha = _getStandardNormalQuantile(confidenceLevel);
    final tAlpha = _getStudentQuantile(confidenceLevel, sampleSize - 1);
    final chi2Alpha2 = _getChiSquaredQuantile(1 + confidenceLevel, sampleSize - 1);
    final chi2Alpha1 = _getChiSquaredQuantile(0.05, sampleSize - 1);

    // 1. Доверительный интервал для мат. ожидания (σ известна)
    final sigmaKnownInterval = _calculateSigmaKnownInterval(
      sampleMean,
      theoreticalSigma ?? sampleSigma,
      sampleSize,
      uAlpha,
      confidenceLevel,
    );

    // 2. Доверительный интервал для мат. ожидания (σ неизвестна)
    final sigmaUnknownInterval = _calculateSigmaUnknownInterval(
      sampleMean,
      sampleSigma,
      sampleSize,
      tAlpha,
      confidenceLevel,
    );

    // 3. Доверительный интервал для дисперсии
    final varianceInterval = _calculateVarianceInterval(
      sampleSigma,
      sampleSize,
      chi2Alpha1,
      chi2Alpha2,
      confidenceLevel,
    );

    return NormalIntervalEstimates(
      sigmaKnown: sigmaKnownInterval,
      sigmaUnknown: sigmaUnknownInterval,
      varianceInterval: varianceInterval,
      sampleSize: sampleSize,
      sampleMean: sampleMean,
      sampleSigma: sampleSigma,
      confidenceLevel: confidenceLevel,
    );
  }

  /// Вычисляет доверительный интервал для математического ожидания при известной σ.
  /// Принимает:
  /// - [sampleMean] - выборочное среднее
  /// - [sigma] - известное стандартное отклонение
  /// - [sampleSize] - размер выборки
  /// - [uAlpha] - критическая точка стандартного нормального распределения
  /// - [confidenceLevel] - уровень доверия
  /// Возвращает:
  /// - [ConfidenceInterval] - доверительный интервал для M
  ConfidenceInterval _calculateSigmaKnownInterval(
    double sampleMean,
    double sigma,
    int sampleSize,
    double uAlpha,
    double confidenceLevel,
  ) {
    final margin = uAlpha * sigma / sqrt(sampleSize);
    final lowerBound = sampleMean - margin;
    final upperBound = sampleMean + margin;

    return ConfidenceInterval(
      lowerBound: lowerBound,
      upperBound: upperBound,
      confidenceLevel: confidenceLevel,
      parameterName: 'M (σ известна)',
    );
  }

  /// Вычисляет доверительный интервал для математического ожидания при неизвестной σ.
  /// Принимает:
  /// - [sampleMean] - выборочное среднее
  /// - [sampleSigma] - выборочное стандартное отклонение
  /// - [sampleSize] - размер выборки
  /// - [tAlpha] - критическая точка распределения Стьюдента
  /// - [confidenceLevel] - уровень доверия
  /// Возвращает:
  /// - [ConfidenceInterval] - доверительный интервал для M
  ConfidenceInterval _calculateSigmaUnknownInterval(
    double sampleMean,
    double sampleSigma,
    int sampleSize,
    double tAlpha,
    double confidenceLevel,
  ) {
    final margin = tAlpha * sampleSigma / sqrt(sampleSize);
    final lowerBound = sampleMean - margin;
    final upperBound = sampleMean + margin;

    return ConfidenceInterval(
      lowerBound: lowerBound,
      upperBound: upperBound,
      confidenceLevel: confidenceLevel,
      parameterName: 'M (σ неизвестна)',
    );
  }

  /// Вычисляет доверительный интервал для дисперсии нормального распределения.
  /// Принимает:
  /// - [sampleSigma] - выборочное стандартное отклонение
  /// - [sampleSize] - размер выборки
  /// - [chi2Alpha1] - верхняя критическая точка распределения хи-квадрат
  /// - [chi2Alpha2] - нижняя критическая точка распределения хи-квадрат
  /// - [confidenceLevel] - уровень доверия
  /// Возвращает:
  /// - [ConfidenceInterval] - доверительный интервал для σ²
  ConfidenceInterval _calculateVarianceInterval(
    double sampleSigma,
    int sampleSize,
    double chi2Alpha1,
    double chi2Alpha2,
    double confidenceLevel,
  ) {
    final sampleVariance = sampleSigma * sampleSigma;
    final n = sampleSize.toDouble();
    
    final lowerBound = (n - 1) * sampleVariance / chi2Alpha1;
    final upperBound = (n - 1) * sampleVariance / chi2Alpha2;

    return ConfidenceInterval(
      lowerBound: lowerBound,
      upperBound: upperBound,
      confidenceLevel: confidenceLevel,
      parameterName: 'σ² (дисперсия)',
    );
  }

  /// Получает критическую точку стандартного нормального распределения.
  /// Принимает:
  /// - [confidenceLevel] - уровень доверия
  /// Возвращает:
  /// - [double] - критическая точка стандартного нормального распределения
  double _getStandardNormalQuantile(double confidenceLevel) {
    final t = confidenceLevel / 2;
    return switch (t) {
      0.45 => 0.1736,
      0.90 => 1.645,
      0.95 => 1.960,
      0.99 => 2.576,
      0.999 => 3.291,
      _ => _approximateNormalQuantile(1 - t / 2),
    };
  }

  /// Получает критическую точку распределения Стьюдента.
  /// Принимает:
  /// - [confidenceLevel] - уровень доверия
  /// - [degreesOfFreedom] - число степеней свободы
  /// Возвращает:
  /// - [double] - критическая точка распределения Стьюдента
  double _getStudentQuantile(double confidenceLevel, int degreesOfFreedom) {
    // Для больших степеней свободы (>30) приближаем к нормальному распределению
    if (degreesOfFreedom >= 300) {
      return _getStandardNormalQuantile(confidenceLevel);
    }
    
    // Табличные значения для малых степеней свободы
    final table = {
      1: {0.90: 6.314, 0.95: 12.706, 0.99: 63.657},
      2: {0.90: 2.920, 0.95: 4.303, 0.99: 9.925},
      3: {0.90: 2.353, 0.95: 3.182, 0.99: 5.841},
      4: {0.90: 2.132, 0.95: 2.776, 0.99: 4.604},
      5: {0.90: 2.015, 0.95: 2.571, 0.99: 4.032},
      10: {0.90: 1.812, 0.95: 2.228, 0.99: 3.169},
      20: {0.90: 1.725, 0.95: 2.086, 0.99: 2.845},
      30: {0.90: 1.697, 0.95: 2.042, 0.99: 2.750},
      99: {0.90: 1.6603911559963895, 0.95: 1.9842169515086827, 0.99: 2.6264054572808275},
      199: {0.90: 1.652546746165939,0.95: 1.971956544249395, 0.99: 2.600760216031323}
    };
    
    return table[degreesOfFreedom]?[confidenceLevel] ?? 
           _getStandardNormalQuantile(confidenceLevel);
  }

  /// Получает критическую точку распределения хи-квадрат.
  /// Принимает:
  /// - [probability] - вероятность
  /// - [degreesOfFreedom] - число степеней свободы
  /// Возвращает:
  /// - [double] - критическая точка распределения хи-квадрат
  double _getChiSquaredQuantile(double probability, int degreesOfFreedom) {
    final t = (probability / 2);
    // Табличные значения χ²-распределения
    final table = {
      1: {0.025: 0.001, 0.05: 0.004, 0.95: 3.841, 0.975: 5.024, 0.99: 6.635, 0.995: 7.879},
      2: {0.025: 0.051, 0.05: 0.103, 0.95: 5.991, 0.975: 7.378, 0.99: 9.210, 0.995: 10.597},
      5: {0.025: 0.831, 0.05: 1.145, 0.95: 11.070, 0.975: 12.833, 0.99: 15.086, 0.995: 16.750},
      10: {0.025: 3.247, 0.05: 3.940, 0.95: 18.307, 0.975: 20.483, 0.99: 23.209, 0.995: 25.188},
      20: {0.025: 9.591, 0.05: 10.851, 0.95: 31.410, 0.975: 34.170, 0.99: 37.566, 0.995: 39.997},
      29: {0.025: 16.791, 0.05: 18.493, 0.95: 43.773, 0.975: 46.979, 0.99: 50.892, 0.995: 53.672},
      199: {0.025: 239.9597, 0.90: 174.835273, 0.975: 161.8262, 0.99: 156.431966}
    };
    
    // Для больших степеней свободы используем приближение
    if (degreesOfFreedom > 300) {
      final u = _getStandardNormalQuantile(t);
      return degreesOfFreedom * pow(1 - 2/(9*degreesOfFreedom) + u * sqrt(2/(9*degreesOfFreedom)), 3).toDouble();
    }
    
    return table[degreesOfFreedom]?[t] ?? 
           degreesOfFreedom.toDouble();
  }

  /// Аппроксимирует критическую точку стандартного нормального распределения.
  /// Принимает:
  /// - [p] - вероятность (0 < p < 1)
  /// Возвращает:
  /// - [double] - аппроксимированное значение квантиля
  double _approximateNormalQuantile(double p) {
    // Approximation from Peter J. Acklam
    if (p <= 0 || p >= 1) return double.nan;
    
    final a1 = -3.969683028665376e+01;
    final a2 =  2.209460984245205e+02;
    final a3 = -2.759285104469687e+02;
    final a4 =  1.383577518672690e+02;
    final a5 = -3.066479806614716e+01;
    final a6 =  2.506628277459239e+00;

    final b1 = -5.447609879822406e+01;
    final b2 =  1.615858368580409e+02;
    final b3 = -1.556989798598866e+02;
    final b4 =  6.680131188771972e+01;
    final b5 = -1.328068155288572e+01;

    final c1 = -7.784894002430293e-03;
    final c2 = -3.223964580411365e-01;
    final c3 = -2.400758277161838e+00;
    final c4 = -2.549732539343734e+00;
    final c5 =  4.374664141464968e+00;
    final c6 =  2.938163982698783e+00;

    final d1 =  7.784695709041462e-03;
    final d2 =  3.224671290700398e-01;
    final d3 =  2.445134137142996e+00;
    final d4 =  3.754408661907416e+00;

    double q;

    if (p < 0.02425) {
      q = sqrt(-2 * log(p));
      q = (((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
          ((((d1 * q + d2) * q + d3) * q + d4) * q + 1);
    } else if (p > 0.97575) {
      q = sqrt(-2 * log(1 - p));
      q = -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
          ((((d1 * q + d2) * q + d3) * q + d4) * q + 1);
    } else {
      q = p - 0.5;
      final r = q * q;
      q = (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) * q /
          (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1);
    }

    return q;
  }
}