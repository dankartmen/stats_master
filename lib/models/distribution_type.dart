import 'package:equatable/equatable.dart';

/// {@template distribution_type}
/// Перечисление поддерживаемых типов распределений.
/// {@endtemplate}
enum DistributionType {
  /// Дискретное биномиальное распределение
  binomial,

  /// Непрерывное равномерное распределение
  uniform,

  /// Непрерывное нормальное распределение
  normal
}

/// {@template distribution_category}
/// Категория распределения (дискретное/непрерывное).
/// {@endtemplate}
enum DistributionCategory {
  discrete,
  continuous,
}

/// {@template distribution_info}
/// Информация о распределении.
/// {@endtemplate}
class DistributionInfo with EquatableMixin{

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