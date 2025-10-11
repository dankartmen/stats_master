import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:stats_master/models/interval.dart';
import '../models/distribution_parameters.dart';
import '../models/generated_value.dart';
import '../models/generation_result.dart';
import '../models/saved_result.dart';

/// {@template saved_results_repository}
/// Репозиторий для работы с сохраненными результатами генерации.
/// Нужен для сохранения, загрузки, удаления и управления результатами
/// в локальном хранилище.
/// {@endtemplate}
class SavedResultsRepository {
  /// Имя файла для хранения сохраненных результатов.
  static const String _fileName = 'saved_results.json';

  /// {@macro saved_results_repository}
  SavedResultsRepository();

  /// Принимает:
  /// - [result] - сохраняемый результат генерации
  /// В случае ошибки выбрасывает исключение.
  Future<void> saveResult(SavedResult result) async {
    final savedResults = await _loadAllResults();
    savedResults[result.id] = result;
    await _saveAllResults(savedResults);
  }

  /// Загружает все сохраненные результаты из локального хранилища.
  /// Возвращает:
  /// - [List<SavedResult>] - список сохраненных результатов, отсортированных по дате создания (новые первыми)
  Future<List<SavedResult>> loadAllResults() async {
    final results = await _loadAllResults();
    return results.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Удаляет сохраненный результат по идентификатору.
  /// Принимает:
  /// - [id] - идентификатор удаляемого результата
  Future<void> deleteResult(String id) async {
    final savedResults = await _loadAllResults();
    savedResults.remove(id);
    await _saveAllResults(savedResults);
  }

  /// Загружает конкретный результат по идентификатору.
  /// Принимает:
  /// - [id] - идентификатор загружаемого результата
  /// Возвращает:
  /// - [SavedResult?] - найденный результат или null, если результат не найден
  Future<SavedResult?> loadResult(String id) async {
    final savedResults = await _loadAllResults();
    return savedResults[id];
  }

  /// Загружает все результаты из файла хранилища.
  /// Возвращает:
  /// - [Map<String, SavedResult>]
  ///  В случае ошибки возвращает пустой словарь.
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

  /// Сохраняет все результаты в файл хранилища.
  /// Принимает:
  /// - [results] - словарь результатов для сохранения
  /// В случае ошибки выбрасывает исключение.
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

  /// Получает файл для сохранения результатов.
  /// Возвращает:
  /// - [File] - файл в директории документов приложения
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }
}

  
/// {@template saved_result_json}
/// Расширение для преобразования SavedResult в JSON и обратно.
/// {@endtemplate}
extension SavedResultJson on SavedResult {

  /// Преобразует словарь Map<int, int> в JSON-совместимый формат.
  /// Принимает:
  /// - [map] - исходный словарь для преобразования
  /// Возвращает:
  /// - [Map<String, int>] - преобразованный словарь
  static Map<String, int> _mapIntIntToJson(Map<int, int> map) {
    return map.map((key, value) => MapEntry(key.toString(), value));
  }

  /// Восстанавливает словарь Map<int, int> из JSON-формата.
  /// Принимает:
  /// - [jsonMap] - JSON-словарь для преобразования
  /// Возвращает:
  /// - [Map<int, int>] - восстановленный словарь
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

  /// Преобразует SavedResult в JSON-формат.
  /// Возвращает:
  /// - [Map<String, dynamic>] - JSON-представление сохраненного результата
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'generationResult': _generationResultToJson(generationResult),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Создает SavedResult из JSON-формата.
  /// Принимает:
  /// - [json] - JSON-данные для преобразования
  /// Возвращает:
  /// - [SavedResult] - восстановленный сохраненный результат
  static SavedResult fromJson(Map<String, dynamic> json) {
    return SavedResult(
      id: json['id'] as String,
      name: json['name'] as String,
      generationResult: _generationResultFromJson(json['generationResult']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Преобразует GenerationResult в JSON-формат.
  /// Принимает:
  /// - [result] - результат генерации для преобразования
  /// Возвращает:
  /// - [Map<String, dynamic>] - JSON-представление результата генерации
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

  /// Восстанавливает GenerationResult из JSON-формата.
  /// Принимает:
  /// - [json] - JSON-данные результата генерации
  /// Возвращает:
  /// - [GenerationResult] - восстановленный результат генерации
  static GenerationResult _generationResultFromJson(Map<String, dynamic> json) {
    return GenerationResult(
      results: (json['values'] as List).map((v) => GeneratedValue.fromJson(v)).toList(),
      parameters: _parametersFromJson(json['parameters']),
      sampleSize: json['sampleSize'] as int,
      intervalData: json['intervalData'] as IntervalData,
      additionalInfo: Map<String, dynamic>.from(json['additionalInfo']),
    );
  }

  /// Преобразует DistributionParameters в JSON-формат.
  /// Принимает:
  /// - [parameters] - параметры распределения для преобразования
  /// Возвращает:
  /// - [Map<String, dynamic>] - JSON-представление параметров
  /// В случае неизвестного типа параметров выбрасывает исключение.
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
      NormalParameters p => {  // Добавьте этот case
        'type': 'normal',
        'm': p.m,
        'sigma': p.sigma,
      },
      _ => throw Exception('Неизвестный тип параметров'),
    };
  }

  /// Восстанавливает DistributionParameters из JSON-формата.
  /// Принимает:
  /// - [json] - JSON-данные параметров распределения
  /// Возвращает:
  /// - [DistributionParameters] - восстановленные параметры распределения
  /// В случае неизвестного типа параметров выбрасывает исключение.
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
      'normal' => NormalParameters(  // Добавьте этот case
        m: json['m'] as double,
        sigma: json['sigma'] as double,
      ),
      _ => throw Exception('Неизвестный тип параметров: $type'),
    };
  }
}


/// {@template generated_value_json}
/// Расширение для преобразования GeneratedValue в JSON и обратно.
/// {@endtemplate}
extension GeneratedValueJson on GeneratedValue {

  /// Преобразует GeneratedValue в JSON-формат.
  /// Возвращает:
  /// - [Map<String, dynamic>] - JSON-представление сгенерированного значения
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'randomU': randomU,
      'additionalInfo': additionalInfo,
    };
  }

  /// Создает GeneratedValue из JSON-формата.
  /// Принимает:
  /// - [json] - JSON-данные для преобразования
  /// Возвращает:
  /// - [GeneratedValue] - восстановленное сгенерированное значение
  static GeneratedValue fromJson(Map<String, dynamic> json) {
    return GeneratedValue(
      value: json['value'] as double,
      randomU: json['randomU'] as double,
      additionalInfo: Map<String, dynamic>.from(json['additionalInfo']),
    );
  }
}