import '../../models/distribution_parameters.dart';
import '../../models/generation_result.dart';

/// {@template distribution_generator}
/// Абстрактный генератор распределений.
/// {@endtemplate}
abstract class DistributionGenerator {
  /// Генерирует значения распределения на основе переданных параметров.
  /// Принимает:
  /// - [parameters] - параметры распределения для генерации
  /// - [sampleSize] - размер выборки для генерации
  /// Возвращает:
  /// - [GenerationResult] - результат генерации значений
  /// В случае несоответствия типа параметров выбрасывает ArgumentError.
  GenerationResult generateResults({
    required DistributionParameters parameters,
    required int sampleSize
  });
}