import 'package:equatable/equatable.dart';

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

  @override
  List<Object> get props => [
        intervals,
        frequencyDict,
        cumulativeProbabilities,
        numberOfIntervals,
        intervalWidth,
      ];
}