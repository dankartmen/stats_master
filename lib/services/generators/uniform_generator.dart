import 'dart:math';
import '../../models/distribution_parameters.dart';
import '../../models/generated_value.dart';
import '../../models/generation_result.dart';
import '../../models/interval.dart';
import 'distribution_generator.dart';

/// {@template uniform_generator}
/// Генератор равномерного распределения
/// {@endtemplate}
class UniformGenerator implements DistributionGenerator{
  @override
  GenerationResult generateResults({required DistributionParameters parameters, required int sampleSize}){
    if(parameters is! UniformParameters){
      throw ArgumentError('Ожидаются параметры равномерного распределения');
    }
    final a = parameters.a;
    final b = parameters.b;
    final random = Random();
    final results = <GeneratedValue>[];

    // Стандартный метод: F(x) = y, где F(x) - функция распределения
    // Для равномерного распределения: F(x) = (x - a) / (b - a)
    // Решаем: (x - a) / (b - a) = u => x = a + u * (b - a)
    
    for (int i = 0; i < sampleSize; i++) {
      final u = random.nextDouble();
      final x = a + u * (b-a);

      results.add(
        GeneratedValue(
          value: x,
          randomU: u, 
          additionalInfo: {
            'a': a,
            'b': b,
            'calculation': 'x = $a +$u * (${b-a}) = $x',
          }
        )
      );
    }

    // Строим интервальный вариационный ряд
    final intervalData = _buildIntervalVariationSeries(results,a,b,sampleSize);

    return GenerationResult(
      results: results,
      parameters: parameters,
      sampleSize: sampleSize,
      intervalData: intervalData
    );
  }

  // Данные интервального вариационного ряда
  IntervalData _buildIntervalVariationSeries(
    List<GeneratedValue> values,
    double a,
    double b,
    int sampleSize
  ){
    // Определяем количество интервалов по формуле N = [log n]
    final numberOfIntervals = 10;// _calculateNumberOfIntevals(sampleSize);

    // Делим отрезок (а, b) на N одинаковых частей
    final intervalWidth = (b - a) / numberOfIntervals;

    final intervals = List<Interval>.generate(numberOfIntervals,(i){
      final start = a + i * intervalWidth;
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
  
  /// Вычисляет количество интервалов по формуле [N = log n]
  int _calculateNumberOfIntevals(int samoleSize){
    final logN = log(samoleSize) / ln2;
    return logN.floor();
  }

  /// Находит индекс интервала для значения
  int _findIntervalIndex(double value, List<Interval> intervals){
    for (int i = 0; i < intervals.length; i++){
      if (value >= intervals[i].start && value <= intervals[i].end){
        return i;
      }
    }
    return intervals.length - 1;
  }

  
}

