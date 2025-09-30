import '../../models/distribution_parameters.dart';
import '../../models/generation_result.dart';

/// {@template distribution_generator}
/// Абстрактный генератор распределений.
/// {@endtemplate}
abstract class DistributionGenerator {
  /// Генерируем значения распределения
  GenerationResult generateResults({required DistributionParameters parameters, required int sampleSize});
}