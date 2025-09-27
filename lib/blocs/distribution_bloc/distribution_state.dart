import 'package:equatable/equatable.dart';
import '../../models/distribution_parameters.dart';
import '../../models/generated_value.dart';

/// {@template distribution_state}
/// Базовое состояние DistributionBloc.
/// {@endtemplate}
abstract class DistributionState with EquatableMixin {
  const DistributionState();
  
  @override
  List<Object> get props => [];
}

/// {@template distribution_initial}
/// Начальное состояние.
/// {@endtemplate}
class DistributionInitial extends DistributionState {
  const DistributionInitial();
}

/// {@template distribution_load_in_progress}
/// Состояние загрузки.
/// {@endtemplate}
class DistributionLoadInProgress extends DistributionState {
  const DistributionLoadInProgress();
}

/// {@template distribution_selection}
/// Состояние выбора распределения.
/// {@endtemplate}
class DistributionSelection extends DistributionState {
  const DistributionSelection();
}

/// {@template distribution_parameters_input}
/// Состояние ввода параметров.
/// {@endtemplate}
class DistributionParametersInput extends DistributionState{
  final DistributionParameters parameters;

  const DistributionParametersInput({required this.parameters});

  @override
  List<Object> get props => [parameters];
}

/// {@template distribution_generation_success}
/// Состояние успешной генерации.
/// {@endtemplate}
class DistributionGenerationSuccess extends DistributionState {
  final DistributionParameters parameters;
  final List<GeneratedValue> generatedValues;
  final int sampleSize;
  /// Словарь частот {значение: количество}
  final Map<int, int> frequencyDict;
  /// Кумулятивные вероятности [a_0, a_1, ..., a_n]
  final List<double> cumulativeProbabilities;

  const DistributionGenerationSuccess(
    {
      required this.parameters,
      required this.generatedValues, 
      required this.sampleSize, 
      required this.cumulativeProbabilities, 
      required this.frequencyDict
    }
  );

  @override
  List<Object> get props => [parameters,generatedValues,sampleSize];
}

/// {@template distribution_generation_success}
/// Состояние ошибки.
/// {@endtemplate}
class DistributionErrorState extends DistributionState{
  final String error;

  const DistributionErrorState(this.error);

  @override
  List<Object> get props => [error];
}