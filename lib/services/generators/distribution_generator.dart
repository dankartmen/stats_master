import '../../models/distribution_parameters.dart';
import '../../models/generated_value.dart';

/// {@template distribution_generator}
/// Абстрактный генератор распределений.
/// {@endtemplate}
abstract class DistributionGenerator {
  /// Генерируем значения распределения
  List<GeneratedValue> generateValues({required DistributionParameters parameters, required int sampleSize});
}