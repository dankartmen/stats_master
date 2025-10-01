import 'package:equatable/equatable.dart';
import '../../models/distribution_parameters.dart';
import '../../models/generation_result.dart';

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
  final GenerationResult generatedResult;

  const DistributionGenerationSuccess(
    {
      required this.generatedResult,
      
    }
  );

  @override
  List<Object> get props => [generatedResult];
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