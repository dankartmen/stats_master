import 'package:equatable/equatable.dart';

import '../../models/all_distribution_parameters.dart';
import '../../models/distribution_parameters.dart';
import '../../models/generation_result.dart';
import '../../models/parameter_estimates.dart';

/// {@template distribution_state}
/// Базовое состояние DistributionBloc.
/// {@endtemplate}
abstract class DistributionState with EquatableMixin {
  const DistributionState();
  
  @override
  List<Object> get props => [];
}

/// {@template distribution_initial}
/// Начальное состояние DistributionBloc.
/// {@endtemplate}
class DistributionInitial extends DistributionState {
  const DistributionInitial();
}

/// {@template distribution_load_in_progress}
/// Состояние загрузки данных распределения.
/// {@endtemplate}
class DistributionLoadInProgress extends DistributionState {
  const DistributionLoadInProgress();
}

/// {@template distribution_selection}
/// Состояние выбора типа распределения.
/// {@endtemplate}
class DistributionSelection extends DistributionState {
  const DistributionSelection();
}

/// {@template distribution_parameters_input}
/// Состояние ввода параметров распределения.
/// {@endtemplate}
class DistributionParametersInput extends DistributionState{
  /// Параметры распределения для ввода.
  final DistributionParameters parameters;

  /// {@macro distribution_parameters_input}
  const DistributionParametersInput({required this.parameters});

  @override
  List<Object> get props => [parameters];
}

/// {@template distribution_generation_success}
/// Состояние успешной генерации значений распределения.
/// {@endtemplate}
class DistributionGenerationSuccess extends DistributionState {
  /// Результат генерации значений.
  final GenerationResult generatedResult;

  /// {@macro distribution_generation_success}
  const DistributionGenerationSuccess({ required this.generatedResult});

  @override
  List<Object> get props => [generatedResult];
}

/// {@template distribution_error_state}
/// Состояние ошибки.
/// {@endtemplate}
class DistributionErrorState extends DistributionState{
  /// Текст ошибки.
  final String error;
  
  /// {@macro distribution_error_state}
  const DistributionErrorState(this.error);

  @override
  List<Object> get props => [error];
}

/// {@template distribution_save_in_progress}
/// Состояние сохранения результата.
/// {@endtemplate}
class DistributionSaveInProgress extends DistributionState {
  const DistributionSaveInProgress();
}

/// {@template distribution_save_success}
/// Состояние успешного сохранения.
/// {@endtemplate}
class DistributionSaveSuccess extends DistributionState {
  const DistributionSaveSuccess();
}

/// {@template distribution_estimation_success}
/// Состояние успешной оценки параметров распределения.
/// {@endtemplate}
class DistributionEstimationSuccess extends DistributionState {
  /// Результат оценки параметров.
  final DistributionEstimate parameterEstimates;

  /// {@macro distribution_estimation_success}
  const DistributionEstimationSuccess({required this.parameterEstimates});

  @override
  List<Object> get props => [parameterEstimates];
}
/// {@template all_parameters_input}
/// Состояние ввода параметров всех распределений.
/// {@endtemplate}
class AllParametersInput extends DistributionState {
  /// Параметры всех распределений для ввода.
  final AllDistributionParameters parameters;

  /// {@macro all_parameters_input}
  const AllParametersInput({required this.parameters});

  @override
  List<Object> get props => [parameters];
}

/// {@template all_estimation_success}
/// Состояние успешной оценки параметров всех распределений.
/// {@endtemplate}
class AllEstimationSuccess extends DistributionState {
  /// Результат оценки параметров всех распределений.
  final AllParameterEstimates parameterEstimates;

  /// {@macro all_estimation_success}
  const AllEstimationSuccess({required this.parameterEstimates});

  @override
  List<Object> get props => [parameterEstimates];
}
