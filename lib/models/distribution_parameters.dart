import 'package:equatable/equatable.dart';

import 'distribution_type.dart';

/// {@template distribution_parameters}
/// Базовый класс для параметров распределения.
/// {@endtemplate}
abstract class DistributionParameters with EquatableMixin{
  const DistributionParameters({required this.type});

  /// Тип распределения
  final DistributionType type;

  @override
  List<Object?> get props => [type];
}

/// {@template binomial_parameters}
/// Параметры биномиального распределения.
/// {@endtemplate}
class BinomialParameters extends DistributionParameters {
  const BinomialParameters({
    required this.n,
    required this.p,
  }) : super(type: DistributionType.binomial);

  /// Количество испытаний
  final int n;

  /// Вероятность успеха
  final double p;

  @override
  List<Object?> get props => [type,n,p];
}

/// {@template uniform_parameters}
/// Параметры равномерного распределения.
/// {@endtemplate}
class UniformParameters extends DistributionParameters {
  /// {@macro uniform_parameters}
  const UniformParameters({
    required this.a,
    required this.b,
  }) : super(type: DistributionType.uniform);

  /// Нижняя граница интервала
  final double a;

  /// Верхняя граница интервала
  final double b;

  @override
  List<Object?> get props => [type,a,b];
}

/// {@template uniform_parameters}
/// Параметры нормального распределения.
/// {@endtemplate}
class NormalParameters extends DistributionParameters {
  /// {@macro uniform_parameters}
  const NormalParameters({
    required this.m,
    required this.sigma,
  }) : super(type: DistributionType.uniform);

  /// Математическое ожидание
  final double m;

  /// Стандартное отклонение
  final double sigma;

  @override
  List<Object?> get props => [type,m,sigma];
}