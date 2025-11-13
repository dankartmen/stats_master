import 'dart:math';

import 'package:equatable/equatable.dart';
import '../services/generators/test_data_generator.dart';
import 'classification_models.dart';
import 'distribution_parameters.dart';

/// {@template bayesian_classifier}
/// Модель байесовского классификатора для двух классов
/// {@endtemplate}
class BayesianClassifier with EquatableMixin {
  /// {@macro bayesian_classifier}
  const BayesianClassifier({
    required this.class1,
    required this.class2,
    required this.p1,
    required this.p2,
    this.class1Name = 'Класс 1',
    this.class2Name = 'Класс 2',
  });

  /// Параметры распределения для класса 1
  final DistributionParameters class1;

  /// Параметры распределения для класса 2
  final DistributionParameters class2;

  /// Априорная вероятность класса 1
  final double p1;

  /// Априорная вероятность класса 2
  final double p2;

  /// Название класса 1
  final String class1Name;

  /// Название класса 2
  final String class2Name;

  /// Проверяет валидность параметров
  bool get isValid => p1 + p2 == 1.0 && p1 >= 0 && p2 >= 0;

  /// Копирует объект с новыми значениями
  BayesianClassifier copyWith({
    DistributionParameters? class1,
    DistributionParameters? class2,
    double? p1,
    double? p2,
    String? class1Name,
    String? class2Name,
  }) {
    return BayesianClassifier(
      class1: class1 ?? this.class1,
      class2: class2 ?? this.class2,
      p1: p1 ?? this.p1,
      p2: p2 ?? this.p2,
      class1Name: class1Name ?? this.class1Name,
      class2Name: class2Name ?? this.class2Name,
    );
  }

  /// Параметры по умолчанию
  static BayesianClassifier get defaultParameters {
      return BayesianClassifier(
        class1: const UniformParameters(a: 3.0, b: 5.0),
        class2: const NormalParameters(m: 5.0, sigma: 1.0),
        p1: 0.5,
        p2: 0.5,
        class1Name: 'Равномерный класс',
        class2Name: 'Нормальный класс',
      );
    }

  @override
  List<Object?> get props => [class1, class2, p1, p2, class1Name, class2Name];
}

extension BayesianClassifierAsyncAnalysis on BayesianClassifier {
  /// Находит точки пересечения графиков p(ωᵢ)·fᵢ(x)
  List<double> findIntersectionPoints() {
    final intersections = <double>[];
    final minX = _getAnalysisMinX();
    final maxX = _getAnalysisMaxX();
    const steps = 1000;
    
    double? prevDiff;
    
    for (int i = 0; i <= steps; i++) {
      final x = minX + (maxX - minX) * i / steps;
      final density1 = _calculateDensity(class1, x) * p1;
      final density2 = _calculateDensity(class2, x) * p2;
      final diff = density1 - density2;
      
      // Ищем смену знака разности
      if (prevDiff != null && prevDiff * diff <= 0) {
        // Уточняем точку пересечения методом бисекции
        final intersection = _refineIntersection(x - (maxX - minX) / steps, x);
        if (intersection != null) {
          intersections.add(intersection);
        }
      }
      
      prevDiff = diff;
    }
    
    return intersections;
  }
  
  /// Рассчитывает частоту ошибок для тестовой выборки 
  Future<ClassificationResult> calculateErrorRateAsync({
    int samplesPerClass = 1000,
  }) async {
    // Генерируем тестовые данные через существующие генераторы
    final testSamples = await TestDataGenerator.generateTestData(
      class1Params: class1,
      class2Params: class2,
      samplesPerClass: samplesPerClass,
    );
    
    return _calculateErrorRateForSamples(testSamples);
  }
  
  /// Рассчитывает частоту ошибок для готовой выборки
  ClassificationResult calculateErrorRate(List<TestSample> testSamples) {
    return _calculateErrorRateForSamples(testSamples);
  }
  
  /// Внутренний метод для расчета ошибок
  ClassificationResult _calculateErrorRateForSamples(List<TestSample> testSamples) {
    int correctClassifications = 0;
    int totalSamples = testSamples.length;
    
    final classifiedSamples = testSamples.map((sample) {
      final predictedClass = classifyValue(sample.value);
      final isCorrect = predictedClass == sample.trueClass;
      
      if (isCorrect) correctClassifications++;
      
      return ClassifiedSample(
        value: sample.value,
        trueClass: sample.trueClass,
        predictedClass: predictedClass,
        isCorrect: isCorrect,
      );
    }).toList();
    
    final errorRate = (totalSamples - correctClassifications) / totalSamples;
    
    return ClassificationResult(
      errorRate: errorRate,
      correctClassifications: correctClassifications,
      totalSamples: totalSamples,
      classifiedSamples: classifiedSamples,
      intersectionPoints: findIntersectionPoints(),
    );
  }
  
  /// Уточняет точку пересечения методом бисекции
  double? _refineIntersection(double x1, double x2, {int iterations = 10}) {
    for (int i = 0; i < iterations; i++) {
      final mid = (x1 + x2) / 2;
      final density1 = _calculateDensity(class1, mid) * p1;
      final density2 = _calculateDensity(class2, mid) * p2;
      final diff = density1 - density2;
      
      if (diff.abs() < 1e-10) return mid;
      
      final diff1 = _calculateDensity(class1, x1) * p1 - _calculateDensity(class2, x1) * p2;
      
      if (diff1 * diff <= 0) {
        x2 = mid;
      } else {
        x1 = mid;
      }
    }
    
    return (x1 + x2) / 2;
  }
  
  /// Классифицирует значение x
  bool classifyValue(double x) {
    final density1 = _calculateDensity(class1, x) * p1;
    final density2 = _calculateDensity(class2, x) * p2;
    return density1 >= density2; // true = класс 1, false = класс 2
  }
  
  
  double _calculateDensity(DistributionParameters params, double x) {
    return switch (params) {
      NormalParameters p => _normalDensity(x, p.m, p.sigma),
      UniformParameters p => _uniformDensity(x, p.a, p.b),
      _ => 0,
    };
  }
  
  double _uniformDensity(double x, double a, double b) {
    return (x >= a && x <= b) ? 1 / (b - a) : 0;
  }
  
  double _normalDensity(double x, double m, double sigma) {
    final exponent = -0.5 * ((x - m) / sigma) * ((x - m) / sigma);
    return (1 / (sigma * sqrt(2 * 3.1415926535))) * exp(exponent);
  }
  
  double _getAnalysisMinX() {
    final min1 = _getDistributionMin(class1);
    final min2 = _getDistributionMin(class2);
    return (min(min1, min2) - 1).clamp(-10.0, 0.0);
  }
  
  double _getAnalysisMaxX() {
    final max1 = _getDistributionMax(class1);
    final max2 = _getDistributionMax(class2);
    return (max(max1, max2) + 1).clamp(0.0, 20.0);
  }
  
  double _getDistributionMin(DistributionParameters params) {
    return switch (params) {
      NormalParameters p => p.m - 3 * p.sigma,
      UniformParameters p => p.a,
      _ => 0,
    };
  }
  
  double _getDistributionMax(DistributionParameters params) {
    return switch (params) {
      NormalParameters p => p.m + 3 * p.sigma,
      UniformParameters p => p.b,
      _ => 1,
    };
  }

  /// Рассчитывает детальную информацию для одного значения
DetailedClassifiedSample classifyValueWithDetails(double value, bool trueClass) {
  final density1 = _calculateDensity(class1, value) * p1;
  final density2 = _calculateDensity(class2, value) * p2;
  final predictedClass = density1 >= density2;
  final decisionBoundary = density1 - density2;

  return DetailedClassifiedSample(
    value: value,
    trueClass: trueClass,
    predictedClass: predictedClass,
    isCorrect: predictedClass == trueClass,
    density1: density1,
    density2: density2,
    decisionBoundary: decisionBoundary,
  );
}

/// Возвращает детализированные результаты классификации
Future<ClassificationResult> calculateDetailedErrorRateAsync({
  int samplesPerClass = 1000,
}) async {
  final testSamples = await TestDataGenerator.generateTestData(
    class1Params: class1,
    class2Params: class2,
    samplesPerClass: samplesPerClass,
  );
  
  return _calculateDetailedErrorRateForSamples(testSamples);
}

ClassificationResult _calculateDetailedErrorRateForSamples(List<TestSample> testSamples) {
  int correctClassifications = 0;
  int totalSamples = testSamples.length;
  
  final detailedSamples = testSamples.map((sample) {
    return classifyValueWithDetails(sample.value, sample.trueClass);
  }).toList();

  correctClassifications = detailedSamples.where((s) => s.isCorrect).length;
  final errorRate = (totalSamples - correctClassifications) / totalSamples;

  return ClassificationResult(
    errorRate: errorRate,
    correctClassifications: correctClassifications,
    totalSamples: totalSamples,
    classifiedSamples: detailedSamples,
    intersectionPoints: findIntersectionPoints(),
  );
}
}