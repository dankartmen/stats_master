import 'dart:math';
import '../../models/distribution_parameters.dart';

/// {@template bayesian_calculator}
/// Калькулятор для теоретических расчетов байесовского классификатора.
/// Использует табличные значения и аналитические методы для максимальной точности
/// вычислений плотностей распределений и интегралов.
/// {@endtemplate}
class BayesianCalculator {
  /// Табличные значения функции Лапласа (нормальное распределение)
  static final Map<double, double> _laplaceTable = {
    0.00: 0.0000, 0.05: 0.0199, 0.10: 0.0398, 0.15: 0.0596, 0.20: 0.0793,
    0.25: 0.0987, 0.30: 0.1179, 0.35: 0.1368, 0.40: 0.1554, 0.45: 0.1736,
    0.50: 0.1915, 0.55: 0.2088, 0.60: 0.2257, 0.65: 0.2422, 0.70: 0.2580,
    0.75: 0.2734, 0.80: 0.2881, 0.85: 0.3023, 0.90: 0.3159, 0.95: 0.3289,
    1.00: 0.3413, 1.05: 0.3531, 1.10: 0.3643, 1.15: 0.3749, 1.20: 0.3849,
    1.25: 0.3944, 1.30: 0.4032, 1.35: 0.4115, 1.40: 0.4192, 1.45: 0.4265,
    1.50: 0.4332, 1.55: 0.4394, 1.60: 0.4452, 1.65: 0.4505, 1.70: 0.4554,
    1.75: 0.4599, 1.80: 0.4641, 1.85: 0.4678, 1.90: 0.4713, 1.95: 0.4744,
    2.00: 0.4772, 2.05: 0.4798, 2.10: 0.4821, 2.15: 0.4842, 2.20: 0.4861,
    2.25: 0.4878, 2.30: 0.4893, 2.35: 0.4906, 2.40: 0.4918, 2.45: 0.4929,
    2.50: 0.4938, 2.55: 0.4946, 2.60: 0.4953, 2.65: 0.4960, 2.70: 0.4965,
    2.75: 0.4970, 2.80: 0.4974, 2.85: 0.4978, 2.90: 0.4981, 2.95: 0.4984,
    3.00: 0.4987, 3.05: 0.4989, 3.10: 0.4990, 3.15: 0.4992, 3.20: 0.4993,
    3.25: 0.4994, 3.30: 0.4995, 3.35: 0.4996, 3.40: 0.4997, 3.45: 0.4997,
    3.50: 0.4998, 3.55: 0.4998, 3.60: 0.4998, 3.65: 0.4999, 3.70: 0.4999,
    3.75: 0.4999, 3.80: 0.4999, 3.85: 0.4999, 3.90: 0.5000, 3.95: 0.5000,
    4.00: 0.5000
  };

  /// Получает значение функции Лапласа для x ≥ 0 с линейной интерполяцией.
  /// Принимает:
  /// - [x] - аргумент функции Лапласа
  /// Возвращает:
  /// - [double] - значение функции Лапласа в точке x
  static double _getLaplaceValue(double x) {
    x = x.abs();
    
    if (x >= 4.0) return 0.5;
    
    // Линейная интерполяция между табличными значениями
    final lowerKey = _laplaceTable.keys.where((key) => key <= x).last;
    final upperKey = _laplaceTable.keys.where((key) => key >= x).first;
    
    if (lowerKey == upperKey) return _laplaceTable[lowerKey]!;
    
    final t = (x - lowerKey) / (upperKey - lowerKey);
    return _laplaceTable[lowerKey]! + t * (_laplaceTable[upperKey]! - _laplaceTable[lowerKey]!);
  }

  /// Функция распределения нормальной величины.
  /// Принимает:
  /// - [x] - значение для вычисления функции распределения
  /// - [mean] - математическое ожидание (по умолчанию 0)
  /// - [stdDev] - стандартное отклонение (по умолчанию 1)
  /// Возвращает:
  /// - [double] - значение функции распределения в точке x
  static double _normalCDF(double x, {double mean = 0, double stdDev = 1}) {
    final z = (x - mean) / stdDev;  // Стандартизация
    if (z >= 0) {
      return 0.5 + _getLaplaceValue(z);  // Для положительных z
    } else {
      return 0.5 - _getLaplaceValue(-z); // Для отрицательных z (симметрия)
    }
  }

  /// Вычисляет плотность распределения в точке x.
  /// Принимает:
  /// - [params] - параметры распределения
  /// - [x] - точка для вычисления плотности
  /// Возвращает:
  /// - [double] - значение плотности распределения в точке x
  static double calculateDensity(DistributionParameters params, double x) {
    return switch (params) {
      NormalParameters p => _normalDensity(x, p.m, p.sigma),
      UniformParameters p => _uniformDensity(x, p.a, p.b),
      BinomialParameters p => _binomialProbability(p.n, p.p, x.round()),
      _ => 0,
    };
  }

  /// Плотность нормального распределения.
  /// Принимает:
  /// - [x] - точка для вычисления плотности
  /// - [m] - математическое ожидание
  /// - [sigma] - стандартное отклонение
  /// Возвращает:
  /// - [double] - значение плотности нормального распределения
  static double _normalDensity(double x, double m, double sigma) {
    final exponent = -0.5 * pow((x - m) / sigma, 2);
    return (1 / (sigma * sqrt(2 * pi))) * exp(exponent);
  }

  /// Плотность равномерного распределения.
  /// Принимает:
  /// - [x] - точка для вычисления плотности
  /// - [a] - нижняя граница распределения
  /// - [b] - верхняя граница распределения
  /// Возвращает:
  /// - [double] - значение плотности равномерного распределения
  static double _uniformDensity(double x, double a, double b) {
    return (x >= a && x <= b) ? 1 / (b - a) : 0;
  }

  /// Вероятность биномиального распределения.
  /// Принимает:
  /// - [n] - количество испытаний
  /// - [p] - вероятность успеха
  /// - [k] - количество успехов
  /// Возвращает:
  /// - [double] - вероятность P(X = k)
  static double _binomialProbability(int n, double p, int k) {
    if (k < 0 || k > n) return 0.0;
    if (p == 0.0) return (k == 0) ? 1.0 : 0.0; 
    if (p == 1.0) return (k == n) ? 1.0 : 0.0;
    
    final coefficient = _binomialCoefficient(n, k);
    return (coefficient * pow(p, k) * pow(1 - p, n - k)).toDouble();
  }

  /// Биномиальный коэффициент C(n, k).
  /// Принимает:
  /// - [n] - общее количество элементов
  /// - [k] - количество выбираемых элементов
  /// Возвращает:
  /// - [int] - биномиальный коэффициент
  static int _binomialCoefficient(int n, int k) {
    if (k < 0 || k > n) return 0;
    if (k == 0 || k == n) return 1;
    
    if (k > n - k) {
      k = n - k;
    }
    
    int result = 1;
    for (int i = 1; i <= k; i++) {
      result = result * (n - i + 1) ~/ i;
    }
    return result;
  }

  /// Интегрирование нормального распределения через таблицу Лапласа.
  /// Принимает:
  /// - [a] - нижний предел интегрирования
  /// - [b] - верхний предел интегрирования
  /// - [mean] - математическое ожидание
  /// - [stdDev] - стандартное отклонение
  /// - [probability] - априорная вероятность
  /// Возвращает:
  /// - [double] - результат интегрирования
  static double _integrateNormalWithTables(double a, double b, double mean, double stdDev, double probability) {
    final phiB = _normalCDF(b, mean: mean, stdDev: stdDev);
    final phiA = _normalCDF(a, mean: mean, stdDev: stdDev);
    return probability * (phiB - phiA);
  }

  /// Аналитическое интегрирование равномерного распределения.
  /// Принимает:
  /// - [a] - нижний предел интегрирования
  /// - [b] - верхний предел интегрирования
  /// - [uniformA] - нижняя граница равномерного распределения
  /// - [uniformB] - верхняя граница равномерного распределения
  /// - [probability] - априорная вероятность
  /// Возвращает:
  /// - [double] - результат интегрирования
  static double _integrateUniformAnalytical(double a, double b, double uniformA, double uniformB, double probability) {
    final effectiveA = max(a, uniformA);     // Начало пересечения
    final effectiveB = min(b, uniformB);     // Конец пересечения
    
    if (effectiveA >= effectiveB) return 0.0; // Нет пересечения
    
    final density = probability / (uniformB - uniformA);  // Высота прямоугольника
    return density * (effectiveB - effectiveA);           // Площадь = высота × ширина
  }

  /// Аналитическое интегрирование биномиального распределения.
  /// Принимает:
  /// - [a] - нижний предел интегрирования
  /// - [b] - верхний предел интегрирования
  /// - [n] - количество испытаний
  /// - [p] - вероятность успеха
  /// - [probability] - априорная вероятность
  /// Возвращает:
  /// - [double] - результат интегрирования
  static double _integrateBinomialAnalytical(double a, double b, int n, double p, double probability) {
    double sum = 0.0;
    final startK = max(0, a.ceil()).clamp(0, n);   // Первое целое в интервале
    final endK = min(n, b.floor()).clamp(0, n);    // Последнее целое в интервале
    
    for (int k = startK; k <= endK; k++) {
      if (k >= a && k <= b) {
        sum += _binomialProbability(n, p, k) * probability;  // Суммируем вероятности
      }
    }
    return sum;
  }

  /// Интегрирование произвольного распределения с использованием аналитических методов.
  /// Принимает:
  /// - [params] - параметры распределения
  /// - [a] - нижний предел интегрирования
  /// - [b] - верхний предел интегрирования
  /// - [probability] - априорная вероятность
  /// Возвращает:
  /// - [double] - результат интегрирования
  static double integrateDistribution(DistributionParameters params, double a, double b, double probability) {
    return switch (params) {
      NormalParameters p => _integrateNormalWithTables(a, b, p.m, p.sigma, probability),
      UniformParameters p => _integrateUniformAnalytical(a, b, p.a, p.b, probability),
      BinomialParameters p => _integrateBinomialAnalytical(a, b, p.n, p.p, probability),
      _ => _simpsonIntegration(a, b, (x) => calculateDensity(params, x) * probability, 100),
    };
  }

  /// Метод Симпсона для численного интегрирования (fallback).
  /// Принимает:
  /// - [a] - нижний предел интегрирования
  /// - [b] - верхний предел интегрирования
  /// - [f] - функция для интегрирования
  /// - [n] - количество шагов (должно быть четным)
  /// Возвращает:
  /// - [double] - результат интегрирования
  static double _simpsonIntegration(double a, double b, double Function(double) f, int n) {
    if (n % 2 != 0) n++; // n должно быть четным
    
    final h = (b - a) / n;
    double sum = f(a) + f(b);
    
    for (int i = 1; i < n; i++) {
      final x = a + i * h;
      final coefficient = (i % 2 == 0) ? 2.0 : 4.0;
      sum += coefficient * f(x);
    }
    
    return sum * h / 3;
  }

  /// Находит минимальное значение X для анализа распределения.
  /// Принимает:
  /// - [params] - параметры распределения
  /// Возвращает:
  /// - [double] - минимальное значение для анализа
  static double getDistributionMin(DistributionParameters params) {
    return switch (params) {
      NormalParameters p => p.m - 3 * p.sigma,
      UniformParameters p => p.a,
      BinomialParameters p => 0.0,
      _ => 0,
    };
  }

  /// Находит максимальное значение X для анализа распределения.
  /// Принимает:
  /// - [params] - параметры распределения
  /// Возвращает:
  /// - [double] - максимальное значение для анализа
  static double getDistributionMax(DistributionParameters params) {
    return switch (params) {
      NormalParameters p => p.m + 3 * p.sigma,
      UniformParameters p => p.b,
      BinomialParameters p => p.n.toDouble(),
      _ => 1,
    };
  }
}