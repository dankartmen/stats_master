import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/distribution_parameters.dart';
import '../models/generated_value.dart';
import '../models/generation_result.dart';
import '../models/saved_result.dart';

/// {@template saved_results_repository}
/// Репозиторий для работы с сохраненными результатами.
/// {@endtemplate}
class SavedResultsRepository {
  static const String _fileName = 'saved_results.json';

  /// {@macro saved_results_repository}
  SavedResultsRepository();

  /// Сохраняет результат генерации.
  Future<void> saveResult(SavedResult result) async {
    final savedResults = await _loadAllResults();
    savedResults[result.id] = result;
    await _saveAllResults(savedResults);
  }

  /// Загружает все сохраненные результаты.
  Future<List<SavedResult>> loadAllResults() async {
    final results = await _loadAllResults();
    return results.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Удаляет сохраненный результат.
  Future<void> deleteResult(String id) async {
    final savedResults = await _loadAllResults();
    savedResults.remove(id);
    await _saveAllResults(savedResults);
  }

  /// Загружает конкретный результат по ID.
  Future<SavedResult?> loadResult(String id) async {
    final savedResults = await _loadAllResults();
    return savedResults[id];
  }

  /// Загружает все результаты из файла.
  Future<Map<String, SavedResult>> _loadAllResults() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return {};
      }

      final contents = await file.readAsString();
      final jsonMap = json.decode(contents) as Map<String, dynamic>;
      
      return jsonMap.map((key, value) {
        return MapEntry(key, SavedResult.fromJson(value));
      });
    } catch (e) {
      print('Ошибка загрузки сохранений: $e');
      return {};
    }
  }

  /// Сохраняет все результаты в файл.
  Future<void> _saveAllResults(Map<String, SavedResult> results) async {
    try {
      final file = await _getFile();
      final jsonMap = results.map((key, value) => MapEntry(key, value.toJson()));
      await file.writeAsString(json.encode(jsonMap));
    } catch (e) {
      print('Ошибка сохранения: $e');
      throw Exception('Не удалось сохранить результат');
    }
  }

  /// Получает файл для сохранения.
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }
}

  
/// Расширения для преобразования в JSON
extension SavedResultJson on SavedResult {
  static Map<String, int> _mapIntIntToJson(Map<int, int> map) {
    return map.map((key, value) => MapEntry(key.toString(), value));
  }

  static Map<int, int> _mapIntIntFromJson(Map<dynamic, dynamic> jsonMap) {
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

  /// Преобразует в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'generationResult': _generationResultToJson(generationResult),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Создает из JSON
  static SavedResult fromJson(Map<String, dynamic> json) {
    return SavedResult(
      id: json['id'] as String,
      name: json['name'] as String,
      generationResult: _generationResultFromJson(json['generationResult']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static Map<String, dynamic> _generationResultToJson(GenerationResult result) {
    return {
      'values': result.results.map((v) => v.toJson()).toList(),
      'parameters': _parametersToJson(result.parameters),
      'sampleSize': result.sampleSize,
      'frequencyDict': _mapIntIntToJson(result.frequencyDict),
      'cumulativeProbabilities': result.cumulativeProbabilities,
      'additionalInfo': result.additionalInfo,
    };
  }

  static GenerationResult _generationResultFromJson(Map<String, dynamic> json) {
    return GenerationResult(
      results: (json['values'] as List).map((v) => GeneratedValue.fromJson(v)).toList(),
      parameters: _parametersFromJson(json['parameters']),
      sampleSize: json['sampleSize'] as int,
      frequencyDict: _mapIntIntFromJson(json['frequencyDict']),
      cumulativeProbabilities: List<double>.from(json['cumulativeProbabilities']),
      additionalInfo: Map<String, dynamic>.from(json['additionalInfo']),
    );
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
          p: json['p'] as double,
        ),
      'uniform' => UniformParameters(
          a: json['a'] as double,
          b: json['b'] as double,
        ),
      _ => throw Exception('Неизвестный тип параметров: $type'),
    };
  }
}

/// Расширения для GeneratedValue
extension GeneratedValueJson on GeneratedValue {
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'randomU': randomU,
      'additionalInfo': additionalInfo,
    };
  }

  static GeneratedValue fromJson(Map<String, dynamic> json) {
    return GeneratedValue(
      value: json['value'] as double,
      randomU: json['randomU'] as double,
      additionalInfo: Map<String, dynamic>.from(json['additionalInfo']),
    );
  }
}