import 'package:equatable/equatable.dart';

/// {@template distribution_type}
/// Перечисление поддерживаемых типов распределений.
/// {@endtemplate}
enum DistributionType {
  /// {@template binomial_distribution}
  /// Дискретное биномиальное распределение
  /// {@endtemplate}
  binomial,

  /// {@template uniform_distribution}
  /// Непрерывное равномерное распределение
  /// {@endtemplate}
  uniform,
}

/// {@template distribution_category}
/// Категория распределения (дискретное/непрерывное).
/// {@endtemplate}
enum DistributionCategory {
  discrete,
  continuous,
}

/// {@template distribution_info}
/// Метаинформация о распределении.
/// {@endtemplate}
class DistributionInfo with EquatableMixin{
  /// {@macro distribution_info}
  const DistributionInfo({
    required this.type,
    required this.name,
    required this.category,
    required this.description,
  });

  /// Тип распределения
  final DistributionType type;

  /// Название распределения
  final String name;

  /// Категория распределения
  final DistributionCategory category;

  /// Описание распределения
  final String description;

  @override
  List<Object> get props => [type,name,category,description];
}