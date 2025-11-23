
import 'dart:math' as math;

import '../../models/distribution_parameters.dart';

/// {@template distribution_calculator}
/// Калькулятор для теоретических значений статистических распределений.
/// Предоставляет методы для расчета теоретических характеристик
/// биномиального, равномерного и нормального распределений.
/// {@endtemplate}
class DistributionCalculator {
  /// {@macro distribution_calculator}
  const DistributionCalculator();

  /// Вычисляет теоретическое математическое ожидание распределения.
  /// Принимает:
  /// - [parameters] - параметры распределения
  /// Возвращает:
  /// - [double] - теоретическое математическое ожидание
  /// Для неизвестных типов распределений возвращает 0.0
  static double calculateTheoreticalMean(DistributionParameters parameters) {
    return switch (parameters) {
      BinomialParameters p => p.n * p.p,
      UniformParameters p => (p.a + p.b) / 2,
      NormalParameters p => p.m,
      _ => 0.0,
    };
  }

  /// Вычисляет теоретическую дисперсию распределения.
  /// Принимает:
  /// - [parameters] - параметры распределения
  /// Возвращает:
  /// - [double] - теоретическая дисперсия
  /// Для неизвестных типов распределений возвращает 0.0
  static double calculateTheoreticalVariance(DistributionParameters parameters) {
    return switch (parameters) {
      BinomialParameters p => p.n * p.p * (1 - p.p),
      UniformParameters p => (p.b - p.a) * (p.b - p.a) / 12,
      NormalParameters p => p.sigma * p.sigma,
      _ => 0.0,
    };
  }

  /// Вычисляет теоретическое стандартное отклонение распределения.
  /// Использует формулу: σ = √D
  /// Принимает:
  /// - [parameters] - параметры распределения
  /// Возвращает:
  /// - [double] - теоретическое стандартное отклонение
  static double calculateTheoreticalSigma(DistributionParameters parameters) {
    return math.sqrt(calculateTheoreticalVariance(parameters));
  }

  /// Вычисляет теоретическую асимметрию распределения.
  /// Принимает:
  /// - [parameters] - параметры распределения
  /// Возвращает:
  /// - [double] - коэффициент асимметрии
  static double calculateTheoreticalSkewness(DistributionParameters parameters) {
    return switch (parameters) {
      BinomialParameters p => (1 - 2 * p.p) / math.sqrt(p.n * p.p * (1 - p.p)),
      UniformParameters p => 0.0, // равномерное распределение симметрично
      NormalParameters p => 0.0, // нормальное распределение симметрично
      _ => 0.0,
    };
  }

  
  /// Вычисляет теоретическую функцию плотности вероятности в точке x.
  /// Принимает:
  /// - [parameters] - параметры распределения
  /// - [x] - точка для вычисления плотности
  /// Возвращает:
  /// - [double] - значение плотности вероятности в точке x
  static double calculateProbabilityDensity(DistributionParameters parameters, double x) {
    return switch (parameters) {
      BinomialParameters p => _binomialDensity(p, x),
      UniformParameters p => _uniformDensity(p, x),
      NormalParameters p => _normalDensity(p, x),
      _ => 0.0,
    };
  }

  /// Вычисляет плотность биномиального распределения в точке x.
  /// Принимает:
  /// - [parameters] - параметры биномиального распределения
  /// - [x] - точка для вычисления плотности
  /// Возвращает:
  /// - [double] - вероятность P(X = x)
  static double _binomialDensity(BinomialParameters parameters, double x) {
    final k = x.round();
    if (k < 0 || k > parameters.n) return 0.0;
    
    final coefficient = _binomialCoefficient(parameters.n, k);
    return coefficient *
        math.pow(parameters.p, k) *
        math.pow(1 - parameters.p, parameters.n - k);
  }

  /// Вычисляет плотность равномерного распределения в точке x.
  /// Принимает:
  /// - [parameters] - параметры равномерного распределения
  /// - [x] - точка для вычисления плотности
  /// Возвращает:
  /// - [double] - значение плотности в точке x
  static double _uniformDensity(UniformParameters parameters, double x) {
    if (x < parameters.a || x > parameters.b) return 0.0;
    return 1.0 / (parameters.b - parameters.a);
  }

  /// Вычисляет плотность нормального распределения в точке x.
  /// Использует формулу нормальной плотности.
  /// Принимает:
  /// - [parameters] - параметры нормального распределения
  /// - [x] - точка для вычисления плотности
  /// Возвращает:
  /// - [double] - значение плотности в точке x
  static double _normalDensity(NormalParameters parameters, double x) {
    final variance = parameters.sigma * parameters.sigma;
    final exponent = -math.pow(x - parameters.m, 2) / (2 * variance);
    return math.exp(exponent) / math.sqrt(2 * math.pi * variance);
  }

  /// Вычисляет биномиальный коэффициент C(n, k).
  /// Принимает:
  /// - [n] - общее количество элементов
  /// - [k] - количество выбираемых элементов
  /// Возвращает:
  /// - [double] - биномиальный коэффициент
  static double _binomialCoefficient(int n, int k) {
    if (k < 0 || k > n) return 0.0;
    if (k == 0 || k == n) return 1.0;
    
    // Используем свойство симметрии для уменьшения количества итераций
    if (k > n - k) {
      k = n - k;
    }
    
    double result = 1.0;
    for (int i = 1; i <= k; i++) {
      result = result * (n - i + 1) / i;
    }
    return result;
  }
}