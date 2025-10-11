import '../models/distribution_parameters.dart';
import '../models/distribution_type.dart';
import '../models/generation_result.dart';
import '../services/generators/binomial_generator.dart';
import '../services/generators/distribution_generator.dart';
import '../services/generators/uniform_generator.dart';
import '../services/generators/normal_generator.dart';

/// {@template distribution_repository}
/// Репозиторий для работы с генерацией распределений.
/// Предоставляет методы для генерации значений различных распределений
/// и получения информации о поддерживаемых типах распределений.
/// {@endtemplate}
class DistributionRepository {
  final Map<DistributionType, DistributionGenerator> _generators;

  /// {@macro distribution_repository}
  /// Инициализирует репозиторий с доступными генераторами распределений.
  DistributionRepository()
      : _generators = {
          DistributionType.binomial: BinomialGenerator(),
          DistributionType.uniform: UniformGenerator(),
          DistributionType.normal: NormalGenerator(),
        };

  /// Генерирует значения распределения на основе переданных параметров.
  /// Принимает:
  /// - [parameters] - параметры распределения для генерации
  /// - [sampleSize] - размер выборки для генерации
  /// Возвращает:
  /// - [GenerationResult] - результат генерации значений
  /// В случае ошибки выбрасывает исключение.
  GenerationResult generateResults({
    required DistributionParameters parameters,
    required int sampleSize,
  }) {
    final generator = _generators[parameters.type];
    if (generator == null) {
      throw Exception('Генератор для ${parameters.type} не найден');
    }

    return generator.generateResults(parameters: parameters, sampleSize: sampleSize);
  }

  /// Возвращает информацию о поддерживаемых распределениях.
  List<DistributionType> getSupportedDistributions() {
    return _generators.keys.toList();
  }
}