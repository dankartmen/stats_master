import 'package:equatable/equatable.dart';

import '../models/distribution_type.dart';
import 'distribution_parameters.dart';
import 'generation_result.dart';
/// {@template saved_result}
/// Сохраненный результат генерации для последующей загрузки.
/// {@endtemplate}
class SavedResult with EquatableMixin {
  /// {@macro saved_result}
  const SavedResult({
    required this.id,
    required this.name,
    required this.generationResult,
    required this.createdAt,
  });

  /// Уникальный идентификатор
  final String id;

  /// Название сохранения (пользовательское)
  final String name;

  /// Результат генерации
  final GenerationResult generationResult;

  /// Дата создания
  final DateTime createdAt;

  /// Тип распределения
  DistributionType get distributionType => generationResult.parameters.type;

  /// Краткое описание
  String get description {
    final params = generationResult.parameters;
    return switch (params) {
      BinomialParameters p => 'Биномиальное: n=${p.n}, p=${p.p.toStringAsFixed(2)}',
      UniformParameters p => 'Равномерное: [${p.a.toStringAsFixed(2)}, ${p.b.toStringAsFixed(2)}]',
      _ => 'Неизвестное распределение',
    };
  }

  @override
  List<Object> get props => [id, name, generationResult, createdAt];

  /// Копирует объект с новыми значениями
  SavedResult copyWith({
    String? name,
    GenerationResult? generationResult,
  }) {
    return SavedResult(
      id: id,
      name: name ?? this.name,
      generationResult: generationResult ?? this.generationResult,
      createdAt: createdAt,
    );
  }

  /// Преобразует в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'generationResult': generationResult.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Создает из JSON
  factory SavedResult.fromJson(Map<String, dynamic> json) {
    return SavedResult(
      id: json['id'] as String,
      name: json['name'] as String,
      generationResult: GenerationResult.fromJson(json['generationResult'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}