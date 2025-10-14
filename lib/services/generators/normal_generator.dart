import 'dart:math';

import '../../models/distribution_parameters.dart';
import '../../models/generated_value.dart';
import '../../models/generation_result.dart';
import '../../models/interval.dart';
import 'distribution_generator.dart';

/// {@template binomial_generator}
/// Генератор биномиального распределения.
/// Генерация случайных величин, распределенных по нормальному закону
/// с использованием метода центральной предельной теоремы (сумма 12 равномерных величин).
/// {@endtemplate}
class NormalGenerator implements DistributionGenerator{
  @override
  GenerationResult generateResults({required DistributionParameters parameters, required int sampleSize,}){
    if (parameters is! NormalParameters){
      throw ArgumentError('Ожидаются параметры нормального распределения');
    }
    final m = parameters.m;
    final sigma = parameters.sigma;
    final random = Random();
    final results = <GeneratedValue>[];

    for(int i = 0; i < sampleSize; i++){
      double u;
      double sumValue = 0;
      for(int j = 0; j < 12; j++){
        u = random.nextDouble();
        sumValue += u;
      }
      final standardValue = sumValue - 6; // Стандартная нормальная велечина ξ ∈ N(0,1), где m = 0, σ = 1  
      final value = (standardValue) * sigma + m; // Наша нормальная случайная велечина ξ ∈ N(m,σ)
      results.add(
        GeneratedValue(
          value: value, 
          randomU: null,
          additionalInfo: {
            'm': m,
            'sigma': sigma,
            'standartValue':standardValue
          }
        )
      );
    }
  
    // Строим интервальный вариационный ряд
    final intervalData = _buildIntervalVariationSeries(results, sampleSize);

    return GenerationResult(
      results: results,
      parameters: parameters,
      sampleSize: sampleSize,
      intervalData: intervalData,
    );
  }

  /// Строит интервальный вариационный ряд для нормального распределения.
  /// Принимает:
  /// - [values] - сгенерированные значения
  /// - [sampleSize] - размер выборки
  /// Возвращает:
  /// - [IntervalData] - данные интервального вариационного ряда
  IntervalData _buildIntervalVariationSeries(
    List<GeneratedValue> values,
    int sampleSize
  ){
    final numberOfIntervals = 13;// _calculateNumberOfIntevals(sampleSize);

    // Делим отрезок (-6, 6) на N одинаковых частей
    final intervalWidth = (12) / numberOfIntervals;

    final intervals = List<Interval>.generate(numberOfIntervals,(i){
      final start = -6 + i * intervalWidth;
      final end = start + intervalWidth;
      return Interval(
        index: i,
        start: start,
        end: end, 
        frequency: 0
      );
    });

    // Подсчитываем частоты
    final frequencyDict = <int,int>{};
    for(final value in values){
      final intervalIndex = _findIntervalIndex(value.value.toDouble(), intervals);
      frequencyDict[intervalIndex] = (frequencyDict[intervalIndex] ?? 0) + 1;
      intervals[intervalIndex] = intervals[intervalIndex].copyWith(
        frequency: intervals[intervalIndex].frequency + 1,
      );
    }

    return IntervalData(
      intervals: intervals,
      frequencyDict: frequencyDict, 
      cumulativeProbabilities: null, 
      numberOfIntervals: numberOfIntervals, 
      intervalWidth: intervalWidth
    );

  }

  /// Находит индекс интервала для значения.
  /// Принимает:
  /// - [value] - значение для поиска
  /// - [intervals] - список интервалов
  /// Возвращает:
  /// - [int] - индекс интервала, содержащего значение
  int _findIntervalIndex(double value, List<Interval> intervals){
    for (int i = 0; i < intervals.length; i++){
      if (value >= intervals[i].start && value <= intervals[i].end){
        return i;
      }
    }
    // Если значение равно последней границе, возвращаем последний интервал
    if (value == intervals.last.end) {
      return intervals.length - 1;
    }
    return intervals.length - 1;
  }
}