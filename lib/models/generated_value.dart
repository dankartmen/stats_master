import 'package:equatable/equatable.dart';

/// {@template generated_value}
/// Результат генерации одного значения.
/// {@endtemplate}
class GeneratedValue with EquatableMixin {
  /// {@macro generated_value}
  const GeneratedValue({
    required this.value,
    required this.randomU,
    required this.additionalInfo,
  });

  final int value;
  final double randomU;
  final Map<String, dynamic> additionalInfo;

  @override
  List<Object> get props => [value, randomU];
}