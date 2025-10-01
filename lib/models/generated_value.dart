import 'package:equatable/equatable.dart';

/// {@template generated_value}
/// Результат генерации одного значения.
/// {@endtemplate}
class GeneratedValue with EquatableMixin {
  /// {@macro generated_value}
  const GeneratedValue({
    required this.value,
    required this.randomU,
    required this.additionalInfo,
  });

  final num value;
  final double randomU;
  final Map<String, dynamic> additionalInfo;

  @override
  List<Object> get props => [value, randomU];

  /// Преобразует в JSON
  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'randomU': randomU,
      'additionalInfo': _cleanAdditionalInfo(additionalInfo),
    };
  }

  /// Создает из JSON
  factory GeneratedValue.fromJson(Map<String, dynamic> json) {
    return GeneratedValue(
      value: (json['value'] as num).toDouble(),
      randomU: (json['randomU'] as num).toDouble(),
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
        // Преобразуем в строку или пропускаем
        cleanInfo[entry.key] = value.toString();
      }
    }
    
    return cleanInfo;
  }
}