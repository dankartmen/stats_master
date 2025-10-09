import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/distribution_parameters.dart';
import '../../models/generated_value.dart';
import '../../models/generation_result.dart';
import '../../models/interval.dart';
import 'distribution_generator.dart';

/// {@template binomial_generator}
/// Генератор биномиального распределения.
/// {@endtemplate}
class BinomialGenerator implements DistributionGenerator{
  @override
  GenerationResult generateResults({required DistributionParameters parameters, required int sampleSize,}){
    if (parameters is! BinomialParameters){
      throw ArgumentError('Ожидаются параметры биноминального распределения');
    }
    final n = parameters.n;
    final p = parameters.p;
    final cumulativeProbabilities = _createCumulativeProbabilities(n,p);
    final random = Random();
    final results = <GeneratedValue>[];
    final frequencyDict = <int, int>{};

    // Инициализируем словарь частот
    for (int i = 0; i <= n; i++) {
      frequencyDict[i] = 0;
    }

    for(int i = 0; i < sampleSize; i++){
      final u = random.nextDouble();
      final value = _findValueInCumulative(u, cumulativeProbabilities);
      results.add(GeneratedValue(
        value: value,
        randomU: u, 
        additionalInfo: {
          'cumulativeIndex': value,
        }
      ));
      frequencyDict[value] = frequencyDict[value]! + 1;
    }

    final intervalData = IntervalData(
      intervals: [],
      frequencyDict: frequencyDict,
      cumulativeProbabilities: cumulativeProbabilities,
      numberOfIntervals: n + 1, // n+1 возможных значений (0 до n)
      intervalWidth: 1.0,
    );
    return GenerationResult(
      results: results,
      parameters: parameters,
      sampleSize: sampleSize,
      intervalData: intervalData
    );
  }

  int _findValueInCumulative(double u, List<double> cumulativeProbabilities){
    int left = 0;
    int right = cumulativeProbabilities.length - 1;
      
    // бинарным поиском ищем между какими вероятностями попала случ. вел.
    while (left <= right) {
      final mid = (left + right) ~/ 2;
      if (u <= cumulativeProbabilities[mid]) {
        right = mid - 1;
      } else {
        left = mid + 1;
      }
    }
    return left;
  }

  /// Вычисление биномиального коэффициента C(n, m)
  /// Используется итеративный подход для избежания переполнения целых чисел.
  /// Принимает:
  /// - [n] - общее количество элементов
  /// - [m] - количество выбираемых элементов
  /// Возвращает:
  /// - биномиальный коэффициент C(n, m)
  /// При невалидных параметрах возвращает 0
  int _binomialCoefficient(int n, int m) {
    if (m < 0 || m > n) return 0;
    if (m == 0 || m == n) return 1;
    
    // Используем свойство симметрии для уменьшения количества итераций
    if (m > n - m) {
      m = n - m;
    }
    
    int result = 1;
    for (int i = 1; i <= m; i++) {
      result = result * (n - i + 1) ~/ i;
    }
    return result;
  }
  
  /// Метод для расчета вероятности биномиального распределения.
  ///  Принимает:
  /// - [n] - количество испытаний
  /// - [p] - вероятность успеха в одном испытании
  /// - [m] - количество успехов
  /// Возвращает:
  /// - вероятность P(ξ = m)
  /// При граничных условиях (p=0 или p=1) возвращает соответствующие значения
  double _binomialProbability(int n, double p, int m) {
    if (m < 0 || m > n) return 0.0;
    if (p == 0.0) return (m == 0) ? 1.0 : 0.0; 
    if (p == 1.0) return (m == n) ? 1.0 : 0.0;
    
    final q = 1 - p;
    
    final coefficient = _binomialCoefficient(n, m);
    return (coefficient * pow(p, m) * pow(q, n - m)).toDouble();
    
  }

  /// Метод для создания массива кумулятивных вероятностей.
  /// Строит последовательность a_0, a_1, ..., a_n где a_i = ∑_{i=1}^{n} P_i (сумма вероятностей от 1 до i-той)
  /// Принимает:
  /// - [n] - количество испытаний
  /// - [p] - вероятность успеха
  /// Возвращает:
  /// - массив кумулятивных вероятностей длиной n+1
  List<double> _createCumulativeProbabilities(int n, double p) {
    final probabilities = List<double>.generate(n + 1, (m) => _binomialProbability(n, p, m));
    
    // Нормализуем вероятности (из-за ошибок округления сумма может быть ≠ 1)
    final sum = probabilities.reduce((a, b) => a + b);
    final normalized = probabilities.map((prob) => prob / sum).toList();
    
    // Строим кумулятивные вероятности
    final cumulative = List<double>.filled(n + 1, 0.0);
    cumulative[0] = normalized[0];
    debugPrint('Вероятность для X = 0 равна ${normalized[0]}');
    
    for (int i = 1; i <= n; i++) {
      debugPrint('Вероятность для X = $i равна ${normalized[i]}');
      cumulative[i] = cumulative[i - 1] + normalized[i];
      debugPrint('Кумулятивная вероятность для X = $i равна ${cumulative[i]}');
    }
    
    // Гарантируем, что последнее значение равно 1.0
    cumulative[n] = 1.0;
    
    return cumulative;
  }
}