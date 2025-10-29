import 'package:equatable/equatable.dart';

import 'distribution_parameters.dart';

/// {@template all_distribution_parameters}
/// Параметры всех распределений для комплексной оценки.
/// {@endtemplate}
class AllDistributionParameters with EquatableMixin {
  /// {@macro all_distribution_parameters}
  const AllDistributionParameters({
    required this.binomial,
    required this.uniform,
    required this.normal,
    required this.binomialSampleSize,
    required this.uniformSampleSize,
    required this.normalSampleSize,
  });

  /// Параметры биномиального распределения
  final BinomialParameters binomial;

  /// Параметры равномерного распределения
  final UniformParameters uniform;

  /// Параметры нормального распределения
  final NormalParameters normal;

  /// Размер выборки для биномиального распределения
  final int binomialSampleSize;

  /// Размер выборки для равномерного распределения
  final int uniformSampleSize;

  /// Размер выборки для нормального распределения
  final int normalSampleSize;

  /// Параметры по умолчанию
  static AllDistributionParameters get defaultParameters {
    return AllDistributionParameters(
      binomial: const BinomialParameters(n: 10, p: 0.5),
      uniform: const UniformParameters(a: 0.0, b: 1.0),
      normal: const NormalParameters(m: 0, sigma: 1),
      binomialSampleSize: 200,
      uniformSampleSize: 200,
      normalSampleSize: 200,
    );
  }

  /// Копирует объект с новыми значениями
  AllDistributionParameters copyWith({
    BinomialParameters? binomial,
    UniformParameters? uniform,
    NormalParameters? normal,
    int? binomialSampleSize,
    int? uniformSampleSize,
    int? normalSampleSize,
  }) {
    return AllDistributionParameters(
      binomial: binomial ?? this.binomial,
      uniform: uniform ?? this.uniform,
      normal: normal ?? this.normal,
      binomialSampleSize: binomialSampleSize ?? this.binomialSampleSize,
      uniformSampleSize: uniformSampleSize ?? this.uniformSampleSize,
      normalSampleSize: normalSampleSize ?? this.normalSampleSize,
    );
  }

  @override
  List<Object?> get props => [
        binomial,
        uniform,
        normal,
        binomialSampleSize,
        uniformSampleSize,
        normalSampleSize,
      ];
}