import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import '../../models/classification_models.dart';
import '../../models/distribution_parameters.dart';
import 'bayesian_calculator.dart';

class ChartDataCalculator {
  /// Генерирует точки для графика на основе типа распределения.
  /// Принимает:
  /// - [params] - параметры распределения
  /// - [probability] - априорная вероятность
  /// Возвращает:
  /// - [List<FlSpot>] - список точек для построения графика
  static List<FlSpot> generateSpotsForClass(
    DistributionParameters params, 
    double probability,
    double minX,
    double maxX
  ) {
    if (params is NormalParameters) {
      return _generateNormalPoints(params, probability, minX, maxX);
    } else if (params is UniformParameters) {
      return _generateUniformPoints(params, probability, minX, maxX);
    } else if (params is BinomialParameters) {
      return _generateBinomialPoints(params, probability, minX, maxX);
    }
    return [];
  }

  /// Генерирует точки для нормального распределения.
  /// Принимает:
  /// - [params] - параметры нормального распределения
  /// - [probability] - априорная вероятность
  /// Возвращает:
  /// - [List<FlSpot>] - список точек нормального распределения
  static List<FlSpot> _generateNormalPoints(
    NormalParameters params, 
    double probability, 
    double minX, 
    double maxX
  ) {
    final spots = <FlSpot>[];
    const steps = 150;
    
    for (int i = 0; i <= steps; i++) {
      final x = minX + (maxX - minX) * i / steps;
      final density = BayesianCalculator.calculateDensity(params, x) * probability;
      spots.add(FlSpot(x, density));
    }
    
    return spots;
  }

  /// Генерирует точки для равномерного распределения.
  /// Принимает:
  /// - [params] - параметры равномерного распределения
  /// - [probability] - априорная вероятность
  /// Возвращает:
  /// - [List<FlSpot>] - список точек равномерного распределения
  static List<FlSpot> _generateUniformPoints(
    UniformParameters params, 
    double probability, 
    double minX, 
    double maxX
  ) {
    final density = BayesianCalculator.calculateDensity(params, params.a) * probability;
    
    return [
      FlSpot(minX, 0),
      FlSpot(params.a, 0),
      FlSpot(params.a, density),
      FlSpot(params.b, density),
      FlSpot(params.b, 0),
      FlSpot(maxX, 0),
    ];
  }

  /// Генерирует точки для биномиального распределения.
  /// Принимает:
  /// - [params] - параметры биномиального распределения
  /// - [probability] - априорная вероятность
  /// Возвращает:
  /// - [List<FlSpot>] - список точек биномиального распределения
  static List<FlSpot> _generateBinomialPoints(
    BinomialParameters params, 
    double probability, 
    double minX, 
    double maxX
  ) {
    final spots = <FlSpot>[];
    
    for (int k = 0; k <= params.n; k++) {
      final x = k.toDouble();
      final density = BayesianCalculator.calculateDensity(params, x) * probability;
      spots.add(FlSpot(x, density));
      
      if (k < params.n) {
        spots.add(FlSpot(x + 0.999, density));
      }
    }
    
    spots.insert(0, FlSpot(minX, 0));
    spots.add(FlSpot(maxX, 0));
    
    return spots;
  }

  /// Вычисляет границы для графика
  static ({double minX, double maxX, double maxY}) calculateChartBounds(
    DistributionParameters class1,
    DistributionParameters class2,
    List<DetailedClassifiedSample>? samples,
  ) {
    final minX = min(
      BayesianCalculator.getDistributionMin(class1),
      BayesianCalculator.getDistributionMin(class2),
    );
    final maxX = max(
      BayesianCalculator.getDistributionMax(class1),
      BayesianCalculator.getDistributionMax(class2),
    );
    
    double maxY = 0;
    const steps = 100;
    
    for (int i = 0; i <= steps; i++) {
      final x = minX + (maxX - minX) * i / steps;
      final density1 = BayesianCalculator.calculateDensity(class1, x);
      final density2 = BayesianCalculator.calculateDensity(class2, x);
      maxY = max(maxY, max(density1, density2));
    }
    
    // Учитываем образцы если есть
    if (samples != null && samples.isNotEmpty) {
      for (final sample in samples) {
        maxY = max(maxY, max(sample.density1, sample.density2));
      }
    }
    
    return (
      minX: (minX - 1).clamp(-5.0, 0.0),
      maxX: (maxX + 1).clamp(0.0, 50.0),
      maxY: max(maxY * 1.2, 0.1)
    );
  }

  /// Вычисляет интервал для оси X.
  /// Принимает:
  /// - [minX] - минимальное значение X
  /// - [maxX] - максимальное значение X
  /// Возвращает:
  /// - [double] - интервал для делений оси X
  static double calculateXInterval(double minX, double maxX) {
    final range = maxX - minX;
    if (range <= 5) return 0.5;
    if (range <= 10) return 1.0;
    if (range <= 20) return 2.0;
    return 5.0;
  }
}