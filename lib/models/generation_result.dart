import 'package:equatable/equatable.dart';

import 'distribution_parameters.dart';
import 'generated_value.dart';
import 'interval.dart';

/// {@template generation_result}
/// Результат генерации с дополнительной метаинформацией.
/// {@endtemplate}
class GenerationResult with EquatableMixin {
  /// {@macro generation_result}
  const GenerationResult({
    required this.results,
    required this.parameters,
    required this.sampleSize,
    required this.frequencyDict,
    required this.cumulativeProbabilities,
    this.additionalInfo = const {}
  });

  /// Сгенерированные значения
  final List<GeneratedValue> results;

  /// Параметры распределения
  final DistributionParameters parameters;

  /// Размер выборки
  final int sampleSize;

  /// Словарь частот {значение: количество}
  final Map<int, int> frequencyDict;

  /// Кумулятивные вероятности [a_0, a_1, ..., a_n]
  final List<double> cumulativeProbabilities;

  /// Дополнительная информация
  final additionalInfo;

  /// Получает данные интервалов (для равномерного распределения)
  IntervalData? get intervalData {
    if (additionalInfo.containsKey('intervalData')) {
      final intervalDataJson = additionalInfo['intervalData'];
      if (intervalDataJson is Map<String, dynamic>) {
        return IntervalData.fromJson(intervalDataJson);
      }
    }
    return null;
  }

  /// Количество интервалов
  int? get numberOfIntervals {
    if (additionalInfo.containsKey('numberOfIntervals')) {
      return additionalInfo['numberOfIntervals'] as int;
    }
    return null;
  }

  /// Ширина интервала
  double? get intervalWidth {
    if (additionalInfo.containsKey('intervalWidth')) {
      return additionalInfo['intervalWidth'] as double;
    }
    return null;
  }
  
  /// Преобразует в JSON
  Map<String, dynamic> toJson() {
    return {
      'values': results.map((v) => v.toJson()).toList(),
      'parameters': _parametersToJson(parameters),
      'sampleSize': sampleSize,
      'frequencyDict': mapIntIntToJson(frequencyDict),
      'cumulativeProbabilities': cumulativeProbabilities,
      'additionalInfo': _cleanAdditionalInfo(additionalInfo),
    };
  }

  /// Создает из JSON
  factory GenerationResult.fromJson(Map<String, dynamic> json) {
    return GenerationResult(
      results: (json['values'] as List)
          .map((v) => GeneratedValue.fromJson(v as Map<String, dynamic>))
          .toList(),
      parameters: _parametersFromJson(json['parameters'] as Map<String, dynamic>),
      sampleSize: json['sampleSize'] as int,
      frequencyDict: mapIntIntFromJson(json['frequencyDict'] as Map),
      cumulativeProbabilities: List<double>.from(json['cumulativeProbabilities'] as List),
      additionalInfo: Map<String, dynamic>.from(json['additionalInfo'] as Map),
    );
  }

  /// Очищает additionalInfo от несериализуемых объектов
  static Map<String, dynamic> _cleanAdditionalInfo(Map<String, dynamic> info) {
    final cleanInfo = <String, dynamic>{};
    
    for (final entry in info.entries) {
      final value = entry.value;
      if (value == null ||
          value is num ||
          value is bool ||
          value is String ||
          value is List ||
          value is Map) {
        cleanInfo[entry.key] = value;
      } else {
        // Пропускаем сложные объекты
        print('Пропущен несериализуемый объект: ${entry.key}');
      }
    }
    
    return cleanInfo;
  }

  /// Преобразует Map<int, int> в JSON-совместимый формат
  static Map<String, int> mapIntIntToJson(Map<int, int> map) {
    return map.map((key, value) => MapEntry(key.toString(), value));
  }

  /// Восстанавливает Map<int, int> из JSON
  static Map<int, int> mapIntIntFromJson(Map<dynamic, dynamic> jsonMap) {
    final result = <int, int>{};
    
    for (final entry in jsonMap.entries) {
      final key = int.tryParse(entry.key.toString());
      final value = entry.value is int ? entry.value as int : (entry.value as num).toInt();
      
      if (key != null) {
        result[key] = value;
      }
    }
    
    return result;
  }

  static Map<String, dynamic> _parametersToJson(DistributionParameters parameters) {
    return switch (parameters) {
      BinomialParameters p => {
          'type': 'binomial',
          'n': p.n,
          'p': p.p,
        },
      UniformParameters p => {
          'type': 'uniform',
          'a': p.a,
          'b': p.b,
        },
      _ => throw Exception('Неизвестный тип параметров'),
    };
  }

  static DistributionParameters _parametersFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'binomial' => BinomialParameters(
          n: json['n'] as int,
          p: (json['p'] as num).toDouble(),
        ),
      'uniform' => UniformParameters(
          a: (json['a'] as num).toDouble(),
          b: (json['b'] as num).toDouble(),
        ),
      _ => throw Exception('Неизвестный тип параметров: $type'),
    };
  }


  @override
  List<Object> get props => [results, parameters, sampleSize, frequencyDict, cumulativeProbabilities, additionalInfo];
}