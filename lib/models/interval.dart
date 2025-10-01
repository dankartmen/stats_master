import 'package:equatable/equatable.dart';
import '../models/generation_result.dart';
/// {@template interval}
/// Интервал вариационного ряда.
/// {@endtemplate}
class Interval with EquatableMixin {
  /// {@macro interval}
  const Interval({
    required this.index,
    required this.start,
    required this.end,
    required this.frequency,
  });

  final int index;
  final double start;
  final double end;
  final int frequency;

  /// Середина интервала
  double get midpoint => (start + end) / 2;

  /// Относительная частота
  double relativeFrequency(int totalSampleSize) => frequency / totalSampleSize;

  Interval copyWith({
    int? frequency,
  }) {
    return Interval(
      index: index,
      start: start,
      end: end,
      frequency: frequency ?? this.frequency,
    );
  }

  /// Преобразует в JSON
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'start': start,
      'end': end,
      'frequency': frequency,
    };
  }

  /// Создает из JSON
  factory Interval.fromJson(Map<String, dynamic> json) {
    return Interval(
      index: json['index'] as int,
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      frequency: json['frequency'] as int,
    );
  }

  @override
  List<Object> get props => [index, start, end, frequency];
}

/// {@template interval_data}
/// Данные интервального вариационного ряда.
/// {@endtemplate}
class IntervalData with EquatableMixin {
  /// {@macro interval_data}
  const IntervalData({
    required this.intervals,
    required this.frequencyDict,
    required this.cumulativeProbabilities,
    required this.numberOfIntervals,
    required this.intervalWidth,
  });

  final List<Interval> intervals;
  final Map<int, int> frequencyDict;
  final List<double> cumulativeProbabilities;
  final int numberOfIntervals;
  final double intervalWidth;

  /// Преобразует в JSON
  Map<String, dynamic> toJson() {
    return {
      'intervals': intervals.map((i) => i.toJson()).toList(),
      'frequencyDict': _mapIntIntToJson(frequencyDict),
      'cumulativeProbabilities': cumulativeProbabilities,
      'numberOfIntervals': numberOfIntervals,
      'intervalWidth': intervalWidth,
    };
  }

  /// Создает из JSON
  factory IntervalData.fromJson(Map<String, dynamic> json) {
    return IntervalData(
      intervals: (json['intervals'] as List)
          .map((i) => Interval.fromJson(i as Map<String, dynamic>))
          .toList(),
      frequencyDict: _mapIntIntFromJson(json['frequencyDict'] as Map),
      cumulativeProbabilities: List<double>.from(json['cumulativeProbabilities'] as List),
      numberOfIntervals: json['numberOfIntervals'] as int,
      intervalWidth: (json['intervalWidth'] as num).toDouble(),
    );
  }

  // ... (существующий код класса IntervalData)

/// Преобразует Map<int, int> в JSON-совместимый формат
static Map<String, int> _mapIntIntToJson(Map<int, int> map) {
  return map.map((key, value) => MapEntry(key.toString(), value));
}

/// Восстанавливает Map<int, int> из JSON
static Map<int, int> _mapIntIntFromJson(Map<dynamic, dynamic> jsonMap) {
  final result = <int, int>{};
  
  for (final entry in jsonMap.entries) {
    final key = int.tryParse(entry.key.toString());
    final value = entry.value is int ? entry.value as int : (entry.value as num).toInt();
    
    if (key != null) {
      result[key] = value;
    }
  }
  
  return result;
}

  @override
  List<Object> get props => [
        intervals,
        frequencyDict,
        cumulativeProbabilities,
        numberOfIntervals,
        intervalWidth,
      ];
}