import '../models/distribution_parameters.dart';
import '../models/distribution_type.dart';
import '../models/generated_value.dart';
import '../services/generators/distribution_generator.dart';
import '../services/generators/binomial_generator.dart';
//import '../services/generators/uniform_generator.dart';

/// {@template distribution_repository}
/// Репозиторий для работы с генерацией распределений.
/// {@endtemplate}
class DistributionRepository {
  final Map<DistributionType, DistributionGenerator> _generators;

  /// {@macro distribution_repository}
  DistributionRepository()
      : _generators = {
          DistributionType.binomial: BinomialGenerator(),
          //DistributionType.uniform: UniformGenerator(),
        };

  /// Генерирует значения распределения.
  List<GeneratedValue> generateValues({
    required DistributionParameters parameters,
    required int sampleSize,
  }) {
    final generator = _generators[parameters.type];
    if (generator == null) {
      throw Exception('Генератор для ${parameters.type} не найден');
    }

    return generator.generateValues(parameters: parameters, sampleSize: sampleSize);
  }

  /// Возвращает информацию о поддерживаемых распределениях.
  List<DistributionType> getSupportedDistributions() {
    return _generators.keys.toList();
  }
}