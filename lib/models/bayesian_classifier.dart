import 'package:equatable/equatable.dart';
import 'distribution_parameters.dart';

/// {@template bayesian_classifier}
/// Модель байесовского классификатора для двух классов
/// {@endtemplate}
class BayesianClassifier with EquatableMixin {
  /// {@macro bayesian_classifier}
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

  /// Проверяет валидность параметров
  bool get isValid => p1 + p2 == 1.0 && p1 >= 0 && p2 >= 0;

  /// Копирует объект с новыми значениями
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

  /// Параметры по умолчанию
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