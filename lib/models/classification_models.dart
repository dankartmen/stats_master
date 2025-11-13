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