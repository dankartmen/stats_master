import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

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
    this.intervalData,
    this.additionalInfo = const {}
  });

  /// Сгенерированные значения
  final List<GeneratedValue> results;

  /// Параметры распределения
  final DistributionParameters parameters;

  /// Размер выборки
  final int sampleSize;


  final IntervalData? intervalData;

  /// Дополнительная информация
  final additionalInfo;

  /// Для обратной совместимости - геттеры
  Map<int, int> get frequencyDict {
    if (intervalData != null) {
      return intervalData!.frequencyDict;
    }
    // Для биномиального распределения вычисляем на лету
    final dict = <int, int>{};
    for (final value in results) {
      final key = value.value.toInt();
      dict[key] = (dict[key] ?? 0) + 1;
    }
    return dict;
  }

  List<double>? get cumulativeProbabilities => intervalData?.cumulativeProbabilities;

  
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
      intervalData: IntervalData.fromJson(json),
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
        debugPrint('Пропущен несериализуемый объект: ${entry.key}');
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
      NormalParameters p => {  
        'type': 'normal',
        'm': p.m,
        'sigma': p.sigma,
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
      'normal' => NormalParameters(  
        m: (json['m'] as num).toDouble(),
        sigma: (json['sigma'] as num).toDouble(),
      ),
      _ => throw Exception('Неизвестный тип параметров: $type'),
    };
  }


  @override
  List<Object?> get props => [results, parameters, sampleSize, frequencyDict, cumulativeProbabilities, additionalInfo];
}