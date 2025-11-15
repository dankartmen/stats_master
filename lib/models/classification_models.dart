import 'package:equatable/equatable.dart';

/// Тестовый образец с известным истинным классом
class TestSample with EquatableMixin {
  final double value;
  final bool trueClass; // true = класс 1, false = класс 2
  
  const TestSample({required this.value, required this.trueClass});
  
  @override
  List<Object> get props => [value, trueClass];
}

/// Результат классификации одного образца
class ClassifiedSample with EquatableMixin {
  final double value;
  final bool trueClass;
  final bool predictedClass;
  final bool isCorrect;
  
  const ClassifiedSample({
    required this.value,
    required this.trueClass,
    required this.predictedClass,
    required this.isCorrect,
  });
  
  @override
  List<Object> get props => [value, trueClass, predictedClass, isCorrect];
}

/// Полный результат классификации
class ClassificationResult with EquatableMixin {
  final double errorRate;
  final int correctClassifications;
  final int totalSamples;
  final List<ClassifiedSample> classifiedSamples;
  final List<double> intersectionPoints;
  
  const ClassificationResult({
    required this.errorRate,
    required this.correctClassifications,
    required this.totalSamples,
    required this.classifiedSamples,
    required this.intersectionPoints,
  });
  
  @override
  List<Object> get props => [
    errorRate, 
    correctClassifications, 
    totalSamples, 
    classifiedSamples,
    intersectionPoints,
  ];
}

/// Расширенная информация о классифицированном образце
class DetailedClassifiedSample extends ClassifiedSample {
  final double density1; // p(ω₁)·f₁(x)
  final double density2; // p(ω₂)·f₂(x)
  final double decisionBoundary; // Разность плотностей

  const DetailedClassifiedSample({
    required super.value,
    required super.trueClass,
    required super.predictedClass,
    required super.isCorrect,
    required this.density1,
    required this.density2,
    required this.decisionBoundary,
  });

  /// В какую сторону отклоняется решение
  bool get favorsClass1 => decisionBoundary >= 0;
  
  /// Насколько уверенно классификация
  double get confidence => decisionBoundary.abs();
}

/// Информация об ошибке на одном интервале
class ErrorInterval with EquatableMixin {
  final double start;
  final double end;
  final double error;
  final String losingClass; // Класс, который "проигрывает" на этом интервале
  
  const ErrorInterval({
    required this.start,
    required this.end,
    required this.error,
    required this.losingClass,
  });
  
  /// Длина интервала
  double get length => end - start;
  
  /// Процент от общей ошибки
  double errorPercentage(double totalError) => (error / totalError) * 100;
  
  @override
  List<Object> get props => [start, end, error, losingClass];
}

/// Полная информация о теоретической ошибке
class TheoreticalErrorInfo with EquatableMixin {
  final double totalError;
  final List<ErrorInterval> intervals;
  final List<double> intersectionPoints;
  
  const TheoreticalErrorInfo({
    required this.totalError,
    required this.intervals,
    required this.intersectionPoints,
  });
  
  /// Вероятность правильной классификации
  double get correctProbability => 1.0 - totalError;
  
  @override
  List<Object> get props => [totalError, intervals, intersectionPoints];
}