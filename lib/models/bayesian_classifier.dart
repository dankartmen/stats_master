import 'dart:math';

import 'package:equatable/equatable.dart';
import '../services/calculators/bayesian_calculator.dart';
import '../services/generators/test_data_generator.dart';
import 'classification_models.dart';
import 'distribution_parameters.dart';

/// {@template bayesian_classifier}
/// Модель байесовского классификатора для двух классов.
/// Реализует алгоритм байесовской классификации с использованием плотностей распределений
/// и априорных вероятностей для принятия решений.
/// {@endtemplate}
class BayesianClassifier with EquatableMixin {
  /// {@macro bayesian_classifier}
  /// Принимает:
  /// - [class1] - параметры распределения для класса 1
  /// - [class2] - параметры распределения для класса 2
  /// - [p1] - априорная вероятность класса 1
  /// - [p2] - априорная вероятность класса 2
  /// - [class1Name] - название класса 1 (по умолчанию 'Класс 1')
  /// - [class2Name] - название класса 2 (по умолчанию 'Класс 2')
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

  /// Проверяет валидность параметров классификатора.
  /// Возвращает:
  /// - [bool] - true если сумма вероятностей равна 1 и обе вероятности неотрицательны
  bool get isValid => p1 + p2 == 1.0 && p1 >= 0 && p2 >= 0;

  /// Создает копию классификатора с новыми значениями.
  /// Принимает:
  /// - [class1] - новые параметры класса 1 (опционально)
  /// - [class2] - новые параметры класса 2 (опционально)
  /// - [p1] - новая вероятность класса 1 (опционально)
  /// - [p2] - новая вероятность класса 2 (опционально)
  /// - [class1Name] - новое название класса 1 (опционально)
  /// - [class2Name] - новое название класса 2 (опционально)
  /// Возвращает:
  /// - [BayesianClassifier] - новый экземпляр классификатора
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

  /// Возвращает классификатор с параметрами по умолчанию.
  /// Возвращает:
  /// - [BayesianClassifier] - классификатор с равномерным и нормальным распределениями
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

/// {@template bayesian_classifier_async_analysis}
/// Расширение для асинхронного анализа байесовского классификатора.
/// Содержит методы для поиска точек пересечения, расчета ошибок классификации
/// и теоретического анализа ошибок.
/// {@endtemplate}
extension BayesianClassifierAsyncAnalysis on BayesianClassifier {
  /// Находит точки пересечения графиков p(ωᵢ)·fᵢ(x).
  /// Возвращает:
  /// - [List<double>] - список точек пересечения плотностей распределений
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
  
  
  
  /// Рассчитывает частоту ошибок для готовой выборки.
  /// Принимает:
  /// - [testSamples] - список тестовых образцов
  /// Возвращает:
  /// - [ClassificationResult] - результат классификации с ошибками
  ClassificationResult calculateErrorRate(List<TestSample> testSamples) {
    return _calculateErrorRateForSamples(testSamples);
  }
  
  /// Внутренний метод для расчета ошибок классификации.
  /// Принимает:
  /// - [testSamples] - список тестовых образцов
  /// Возвращает:
  /// - [ClassificationResult] - результат классификации с ошибками
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
  
  /// Уточняет точку пересечения методом бисекции.
  /// Принимает:
  /// - [x1] - левая граница интервала
  /// - [x2] - правая граница интервала
  /// - [iterations] - количество итераций уточнения (по умолчанию 10)
  /// Возвращает:
  /// - [double?] - уточненная точка пересечения или null если не найдена
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
  
  /// Классифицирует значение x с использованием байесовского правила.
  /// Принимает:
  /// - [x] - значение для классификации
  /// Возвращает:
  /// - [bool] - true если отнесен к классу 1, false если к классу 2
  bool classifyValue(double x) {
    final density1 = _calculateDensity(class1, x) * p1;
    final density2 = _calculateDensity(class2, x) * p2;
    return density1 >= density2; // true = класс 1, false = класс 2
  }
  
  /// Вычисляет плотность распределения в точке x.
  /// Принимает:
  /// - [params] - параметры распределения
  /// - [x] - точка для вычисления плотности
  /// Возвращает:
  /// - [double] - значение плотности
  double _calculateDensity(DistributionParameters params, double x) {
    return switch (params) {
      NormalParameters p => BayesianCalculator.normalDensity(x, p.m, p.sigma),
      UniformParameters p => BayesianCalculator.uniformDensity(x, p.a, p.b),
      _ => 0,
    };
  }
  
  /// Вычисляет плотность равномерного распределения.
  /// Принимает:
  /// - [x] - точка для вычисления
  /// - [a] - нижняя граница распределения
  /// - [b] - верхняя граница распределения
  /// Возвращает:
  /// - [double] - значение плотности равномерного распределения
  double uniformDensity(double x, double a, double b) {
    return (x >= a && x <= b) ? 1 / (b - a) : 0;
  }
  
  
  
  /// Вычисляет минимальное значение X для анализа.
  /// Возвращает:
  /// - [double] - минимальное значение X для анализа распределений
  double _getAnalysisMinX() {
    final min1 = _getDistributionMin(class1);
    final min2 = _getDistributionMin(class2);
    return (min(min1, min2) - 1).clamp(-10.0, 0.0);
  }
  
  /// Вычисляет максимальное значение X для анализа.
  /// Возвращает:
  /// - [double] - максимальное значение X для анализа распределений
  double _getAnalysisMaxX() {
    final max1 = _getDistributionMax(class1);
    final max2 = _getDistributionMax(class2);
    return (max(max1, max2) + 1).clamp(0.0, 20.0);
  }
  
  /// Вычисляет минимальное значение для распределения.
  /// Принимает:
  /// - [params] - параметры распределения
  /// Возвращает:
  /// - [double] - минимальное значение распределения
  double _getDistributionMin(DistributionParameters params) {
    return switch (params) {
      NormalParameters p => p.m - 3 * p.sigma,
      UniformParameters p => p.a,
      _ => 0,
    };
  }
  
  /// Вычисляет максимальное значение для распределения.
  /// Принимает:
  /// - [params] - параметры распределения
  /// Возвращает:
  /// - [double] - максимальное значение распределения
  double _getDistributionMax(DistributionParameters params) {
    return switch (params) {
      NormalParameters p => p.m + 3 * p.sigma,
      UniformParameters p => p.b,
      _ => 1,
    };
  }

  /// Рассчитывает детальную информацию для одного значения.
  /// Принимает:
  /// - [value] - значение для классификации
  /// - [trueClass] - истинный класс значения
  /// Возвращает:
  /// - [DetailedClassifiedSample] - детализированная информация о классификации
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

  /// Возвращает детализированные результаты классификации.
  /// Принимает:
  /// - [totalSamples] - количество образцов на класс (по умолчанию 1000)
  /// Возвращает:
  /// - [Future<ClassificationResult>] - детализированный результат классификации
  Future<ClassificationResult> calculateDetailedErrorRateAsync({
    int totalSamples = 400,
  }) async {
    final testSamples = await TestDataGenerator.generateTestData(
      class1Params: class1,
      class2Params: class2,
      totalSamples: totalSamples,
      class1Probability: p1
    );
    
    return _calculateDetailedErrorRateForSamples(testSamples);
  }

  /// Внутренний метод для расчета детализированных ошибок классификации.
  /// Принимает:
  /// - [testSamples] - список тестовых образцов
  /// Возвращает:
  /// - [ClassificationResult] - детализированный результат классификации
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

  /// Вычисляет теоретическую вероятность ошибки через интегрирование меньшей плотности.
  /// Возвращает:
  /// - [double] - теоретическая вероятность ошибки классификации
  double calculateTheoreticalError() {
    final intersections = findIntersectionPoints();
    final sortedIntersections = [...intersections]..sort();
    
    // Добавляем границы интегрирования
    final integrationBounds = [
      _getAnalysisMinX(),
      ...sortedIntersections,
      _getAnalysisMaxX()
    ];
    
    double totalError = 0.0;
    
    // Интегрируем на каждом интервале
    for (int i = 0; i < integrationBounds.length - 1; i++) {
      final a = integrationBounds[i];
      final b = integrationBounds[i + 1];
      
      // Определяем, какая плотность меньше на этом интервале
      final midpoint = (a + b) / 2;
      final density1 = _calculateDensity(class1, midpoint) * p1;
      final density2 = _calculateDensity(class2, midpoint) * p2;
      
      final minDensity = min(density1, density2);
      
      // Интегрируем меньшую плотность на интервале
      final intervalError = _integrateFunction(a, b, (x) => minDensity);
      totalError += intervalError;
    }
    
    return totalError;
  }

  /// Более точный метод интегрирования меньшей плотности.
  /// Принимает:
  /// - [stepsPerInterval] - количество шагов на интервал (по умолчанию 100)
  /// Возвращает:
  /// - [double] - точная теоретическая вероятность ошибки
  double calculateTheoreticalErrorPrecise({int stepsPerInterval = 100}) {
    final intersections = findIntersectionPoints();
    final sortedIntersections = [...intersections]..sort();
    
    final integrationBounds = [
      _getAnalysisMinX(),
      ...sortedIntersections,
      _getAnalysisMaxX()
    ];
    
    double totalError = 0.0;
    
    for (int i = 0; i < integrationBounds.length - 1; i++) {
      final a = integrationBounds[i];
      final b = integrationBounds[i + 1];
      
      // Используем метод Симпсона для более точного интегрирования
      totalError += _simpsonIntegration(a, b, (x) {
        final density1 = _calculateDensity(class1, x) * p1;
        final density2 = _calculateDensity(class2, x) * p2;
        return min(density1, density2);
      }, stepsPerInterval);
    }
    
    return totalError;
  }

  /// Метод Симпсона для численного интегрирования.
  /// Принимает:
  /// - [a] - нижний предел интегрирования
  /// - [b] - верхний предел интегрирования
  /// - [f] - функция для интегрирования
  /// - [n] - количество шагов (должно быть четным)
  /// Возвращает:
  /// - [double] - результат интегрирования
  double _simpsonIntegration(double a, double b, double Function(double) f, int n) {
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

  /// Простое интегрирование методом прямоугольников.
  /// Принимает:
  /// - [a] - нижний предел интегрирования
  /// - [b] - верхний предел интегрирования
  /// - [f] - функция для интегрирования
  /// - [steps] - количество шагов (по умолчанию 100)
  /// Возвращает:
  /// - [double] - результат интегрирования
  double _integrateFunction(double a, double b, double Function(double) f, {int steps = 100}) {
    final stepSize = (b - a) / steps;
    double sum = 0.0;
    
    for (int i = 0; i < steps; i++) {
      final x = a + i * stepSize;
      sum += f(x) * stepSize;
    }
    
    return sum;
  }

  /// Полная информация о теоретической ошибке.
  /// Возвращает:
  /// - [TheoreticalErrorInfo] - полная информация об ошибках по интервалам
  TheoreticalErrorInfo calculateTheoreticalErrorInfo() {
    final intersections = findIntersectionPoints();
    final sortedIntersections = [...intersections]..sort();
    
    final integrationBounds = [
      _getAnalysisMinX(),
      ...sortedIntersections,
      _getAnalysisMaxX()
    ];
    
    final intervalErrors = <ErrorInterval>[];
    double totalError = 0.0;
    
    for (int i = 0; i < integrationBounds.length - 1; i++) {
      final a = integrationBounds[i];
      final b = integrationBounds[i + 1];
      
      final intervalError = _simpsonIntegration(a, b, (x) {
        final density1 = _calculateDensity(class1, x) * p1;
        final density2 = _calculateDensity(class2, x) * p2;
        return min(density1, density2);
      }, 100);
      
      // Определяем, какой класс "проигрывает" на этом интервале
      final midpoint = (a + b) / 2;
      final density1 = _calculateDensity(class1, midpoint) * p1;
      final density2 = _calculateDensity(class2, midpoint) * p2;
      final losingClass = density1 < density2 ? class1Name : class2Name;
      
      intervalErrors.add(ErrorInterval(
        start: a,
        end: b,
        error: intervalError,
        losingClass: losingClass,
      ));
      
      totalError += intervalError;
    }
    
    return TheoreticalErrorInfo(
      totalError: totalError,
      intervals: intervalErrors,
      intersectionPoints: intersections,
    );
  }
}

/// {@template bayesian_calculator_extension}
/// Расширение с аналитическими методами расчета через BayesianCalculator.
/// Предоставляет методы для точных аналитических вычислений с использованием
/// табличных значений и аналитических формул.
/// {@endtemplate}
extension BayesianCalculatorExtension on BayesianClassifier {
  /// Рассчитывает теоретическую ошибку с использованием аналитических методов и таблиц.
  /// Возвращает:
  /// - [double] - теоретическая ошибка, рассчитанная аналитически
  /// Рассчитывает теоретическую ошибку с использованием аналитических методов и таблиц
  double calculateTheoreticalErrorAnalytical() {
    // 1. Находим границы решений (точки пересечения)
    final intersections = findIntersectionPoints();
    final sortedIntersections = [...intersections]..sort();
    
    // 2. Разбиваем ось на интервалы этими точками
    final bounds = [
      BayesianCalculator.getDistributionMin(class1),
      BayesianCalculator.getDistributionMin(class2),
      ...sortedIntersections,
      BayesianCalculator.getDistributionMax(class1),
      BayesianCalculator.getDistributionMax(class2),
    ]..sort();
    
    double totalError = 0.0;

    // 3. На каждом интервале определяем, какая плотность меньше
    for (int i = 0; i < bounds.length - 1; i++) {
      final a = bounds[i];
      final b = bounds[i + 1];
      
      // Пропускаем слишком маленькие интервалы
      if (b - a < 1e-10) continue;
      
      // Находим середину интервала для проверки
      final midpoint = (a + b) / 2;
      final density1 = BayesianCalculator.calculateDensity(class1, midpoint) * p1;
      final density2 = BayesianCalculator.calculateDensity(class2, midpoint) * p2;
      
      // 4. Интегрируем МЕНЬШУЮ плотность на интервале
      if (density1 < density2) {  
        // Ошибаемся против класса 1 - интегрируем его плотность
        totalError += BayesianCalculator.integrateDistribution(class1, a, b, 1.0) * p1;
      } else {
        // Ошибаемся против класса 2 - интегрируем его плотность
        totalError += BayesianCalculator.integrateDistribution(class2, a, b, 1.0) * p2;
      }
    }
    
    return totalError;
  }

  /// Полная информация о теоретической ошибке с аналитическими методами.
  /// Возвращает:
  /// - [TheoreticalErrorInfo] - полная аналитическая информация об ошибках
  /// Полная информация о теоретической ошибке с аналитическими методами
  TheoreticalErrorInfo calculateTheoreticalErrorInfoAnalytical() {
    // 1. Находим границы решений (точки пересечения)
    final intersections = findIntersectionPoints();
    final sortedIntersections = [...intersections]..sort();
    
    // 2. Разбиваем ось на интервалы этими точками
    final bounds = [
      min(BayesianCalculator.getDistributionMin(class1), BayesianCalculator.getDistributionMin(class2)),
      ...sortedIntersections,
      max(BayesianCalculator.getDistributionMax(class1), BayesianCalculator.getDistributionMax(class2)),
    ]..sort();
    
    final intervalErrors = <ErrorInterval>[];
    double totalError = 0.0;
    
    // 3. На каждом интервале определяем, какая плотность меньше
    for (int i = 0; i < bounds.length - 1; i++) {
      final a = bounds[i];
      final b = bounds[i + 1];
      
      // Пропускаем слишком маленькие интервалы
      if (b - a < 1e-10) continue;
      
      // Находим середину интервала для проверки
      final midpoint = (a + b) / 2;
      final density1 = BayesianCalculator.calculateDensity(class1, midpoint) * p1;
      final density2 = BayesianCalculator.calculateDensity(class2, midpoint) * p2;
      
      double intervalError;
      String losingClass;
      
      // 4. Интегрируем МЕНЬШУЮ плотность на интервале
      if (density1 < density2) {
        // Ошибаемся против класса 1 - интегрируем его плотность
        intervalError = BayesianCalculator.integrateDistribution(class1, a, b, 1.0) * p1;
        losingClass = class1Name;
      } else {
        // Ошибаемся против класса 2 - интегрируем его плотность
        intervalError = BayesianCalculator.integrateDistribution(class2, a, b, 1.0) * p2;
        losingClass = class2Name;
      }
      
      intervalErrors.add(ErrorInterval(
        start: a,
        end: b,
        error: intervalError,
        losingClass: losingClass,
      ));
      
      totalError += intervalError;
    }
    
    return TheoreticalErrorInfo(
      totalError: totalError,
      intervals: intervalErrors,
      intersectionPoints: intersections,
    );
  }

  /// Классифицирует значение с использованием калькулятора для плотностей.
  /// Принимает:
  /// - [value] - значение для классификации
  /// - [trueClass] - истинный класс значения
  /// Возвращает:
  /// - [DetailedClassifiedSample] - детализированная информация о классификации
  DetailedClassifiedSample classifyValueWithDetailsAnalytical(double value, bool trueClass) {
    final density1 = BayesianCalculator.calculateDensity(class1, value) * p1;
    final density2 = BayesianCalculator.calculateDensity(class2, value) * p2;
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

  /// Находит точки пересечения с использованием калькулятора.
  /// Возвращает:
  /// - [List<double>] - список точек пересечения, найденных аналитически
  List<double> findIntersectionPointsAnalytical() {
    final intersections = <double>[];
    final minX = min(
      BayesianCalculator.getDistributionMin(class1),
      BayesianCalculator.getDistributionMin(class2),
    );
    final maxX = max(
      BayesianCalculator.getDistributionMax(class1),
      BayesianCalculator.getDistributionMax(class2),
    );
    const steps = 1000;
    
    double? prevDiff;
    
    for (int i = 0; i <= steps; i++) {
      final x = minX + (maxX - minX) * i / steps;
      final density1 = BayesianCalculator.calculateDensity(class1, x) * p1;
      final density2 = BayesianCalculator.calculateDensity(class2, x) * p2;
      final diff = density1 - density2;
      
      // Ищем смену знака разности
      if (prevDiff != null && prevDiff * diff <= 0) {
        // Уточняем точку пересечения методом бисекции
        final intersection = _refineIntersectionAnalytical(x - (maxX - minX) / steps, x);
        if (intersection != null) {
          intersections.add(intersection);
        }
      }
      
      prevDiff = diff;
    }
    
    return intersections;
  }

  /// Уточняет точку пересечения методом бисекции с использованием калькулятора.
  /// Принимает:
  /// - [x1] - левая граница интервала
  /// - [x2] - правая граница интервала
  /// - [iterations] - количество итераций уточнения (по умолчанию 10)
  /// Возвращает:
  /// - [double?] - уточненная точка пересечения или null если не найдена
  double? _refineIntersectionAnalytical(double x1, double x2, {int iterations = 10}) {
    for (int i = 0; i < iterations; i++) {
      final mid = (x1 + x2) / 2;
      final density1 = BayesianCalculator.calculateDensity(class1, mid) * p1;
      final density2 = BayesianCalculator.calculateDensity(class2, mid) * p2;
      final diff = density1 - density2;
      
      if (diff.abs() < 1e-10) return mid;
      
      final diff1 = BayesianCalculator.calculateDensity(class1, x1) * p1 - 
                   BayesianCalculator.calculateDensity(class2, x1) * p2;
      
      if (diff1 * diff <= 0) {
        x2 = mid;
      } else {
        x1 = mid;
      }
    }
    
    return (x1 + x2) / 2;
  }
}
