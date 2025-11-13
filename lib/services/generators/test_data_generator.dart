
import '../../models/classification_models.dart';
import '../../models/distribution_parameters.dart';
import 'binomial_generator.dart';
import 'distribution_generator.dart';
import 'normal_generator.dart';
import 'uniform_generator.dart';

class TestDataGenerator {
  /// Генерирует тестовые данные с использованием существующих генераторов
  static Future<List<TestSample>> generateTestData({
    required DistributionParameters class1Params,
    required DistributionParameters class2Params,
    required int samplesPerClass,
  }) async {
    final samples = <TestSample>[];
    
    // Генерация данных для класса 1
    final class1Samples = await _generateFromDistribution(
      class1Params, 
      samplesPerClass
    );
    samples.addAll(class1Samples.map((value) => 
      TestSample(value: value, trueClass: true)));
    
    // Генерация данных для класса 2
    final class2Samples = await _generateFromDistribution(
      class2Params, 
      samplesPerClass
    );
    samples.addAll(class2Samples.map((value) => 
      TestSample(value: value, trueClass: false)));
    
    // Перемешиваем данные
    samples.shuffle();
    
    return samples;
  }
  
  static Future<List<double>> _generateFromDistribution(
    DistributionParameters params, 
    int count
  ) async {
    final generator = _getGeneratorForParams(params);
    final result = generator.generateResults(
      parameters: params,
      sampleSize: count,
    );
    
    return result.results.map((generatedValue) => generatedValue.value.toDouble()).toList();
  }
  
  static DistributionGenerator _getGeneratorForParams(DistributionParameters params) {
    return switch (params) {
      BinomialParameters _ => BinomialGenerator(),
      UniformParameters _ => UniformGenerator(),
      NormalParameters _ => NormalGenerator(),
      _ => throw ArgumentError('Unsupported distribution type'),
    };
  }
}