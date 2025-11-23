import 'dart:math' as math;

/// {@template statistical_calculator}
/// Калькулятор для базовых статистических вычислений.
/// Предоставляет методы для расчета выборочных характеристик:
/// среднего, дисперсии, стандартного отклонения и других статистических мер.
/// {@endtemplate}
class StatisticalCalculator {
  /// {@macro statistical_calculator}
  const StatisticalCalculator();

  /// Вычисляет выборочное среднее значение.
  /// Принимает:
  /// - [values] - список числовых значений выборки
  /// Возвращает:
  /// - [double] - выборочное среднее
  /// В случае пустой выборки возвращает 0.0
  static double calculateSampleMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Вычисляет выборочную дисперсию.
  /// Использует формулу: σ² = Σ(xᵢ - μ)² / n
  /// Принимает:
  /// - [values] - список числовых значений выборки
  /// Возвращает:
  /// - [double] - выборочную дисперсию
  /// В случае пустой выборки возвращает 0.0
  static double calculateSampleVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = calculateSampleMean(values);
    final sumSquares = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b);
    return sumSquares / values.length;
  }

  /// Вычисляет исправленную (несмещенную) дисперсию.
  /// Использует формулу: s² = Σ(xᵢ - μ)² / (n - 1)
  /// Принимает:
  /// - [values] - список числовых значений выборки
  /// Возвращает:
  /// - [double] - исправленную дисперсию
  /// В случае выборки размером менее 2 элементов возвращает 0.0
  static double calculateCorrectedVariance(List<double> values) {
    if (values.length < 2) return 0.0;
    final mean = calculateSampleMean(values);
    final sumSquares = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b);
    return sumSquares / (values.length - 1);
  }

  /// Вычисляет выборочное стандартное отклонение.
  /// Использует формулу: σ = √σ²
  /// Принимает:
  /// - [values] - список числовых значений выборки
  /// Возвращает:
  /// - [double] - стандартное отклонение
  static double calculateStandardDeviation(List<double> values) {
    return math.sqrt(calculateSampleVariance(values));
  }

  /// Вычисляет исправленное стандартное отклонение.
  /// Использует формулу: s = √s²
  /// Принимает:
  /// - [values] - список числовых значений выборки
  /// Возвращает:
  /// - [double] - исправленное стандартное отклонение
  static double calculateCorrectedStandardDeviation(List<double> values) {
    return math.sqrt(calculateCorrectedVariance(values));
  }

  /// Вычисляет моду выборки - наиболее часто встречающееся значение.
  /// Принимает:
  /// - [values] - список числовых значений выборки
  /// Возвращает:
  /// - [double] - моду выборки
  /// В случае нескольких мод возвращает первую найденную
  static double calculateMode(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final frequencyMap = <double, int>{};
    for (final value in values) {
      frequencyMap[value] = (frequencyMap[value] ?? 0) + 1;
    }
    
    var mode = values[0];
    var maxFrequency = 0;
    
    frequencyMap.forEach((value, frequency) {
      if (frequency > maxFrequency) {
        maxFrequency = frequency;
        mode = value;
      }
    });
    
    return mode;
  }

  /// Вычисляет медиану выборки.
  /// Принимает:
  /// - [values] - список числовых значений выборки
  /// Возвращает:
  /// - [double] - медиану выборки
  static double calculateMedian(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final sortedValues = List<double>.from(values)..sort();
    final middle = sortedValues.length ~/ 2;
    
    if (sortedValues.length.isOdd) {
      return sortedValues[middle];
    } else {
      return (sortedValues[middle - 1] + sortedValues[middle]) / 2;
    }
  }

  /// Вычисляет коэффициент вариации.
  /// Использует формулу: CV = σ / μ * 100%
  /// Принимает:
  /// - [values] - список числовых значений выборки
  /// Возвращает:
  /// - [double] - коэффициент вариации в процентах
  static double calculateCoefficientOfVariation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = calculateSampleMean(values);
    if (mean == 0) return 0.0;
    
    final standardDeviation = calculateStandardDeviation(values);
    return (standardDeviation / mean) * 100;
  }
}