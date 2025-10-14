import 'package:equatable/equatable.dart';

import '../../models/distribution_parameters.dart';
import '../../models/saved_result.dart';
/// {@template distribution_event}
/// Базовое событие для DistributionBloc.
/// {@endtemplate}
abstract class DistributionEvent with EquatableMixin{
  @override
  List<Object?> get props => [];
}

/// {@template distribution_parameters_changed}
/// Событие выбора распределения.
/// {@endtemplate}
class DistributionTypeSelect extends DistributionEvent{
  /// Выбранный тип распределения.
  final String distributionType;

  /// {@macro distribution_type_select}
  DistributionTypeSelect(this.distributionType);

  @override
  List<Object?> get props => [distributionType];
}

/// {@template distribution_parameters_changed}
/// Событие изменения параметров распределения.
/// {@endtemplate}
class DistributionParametersChanged extends DistributionEvent{
  /// Новые параметры распределения.
  final DistributionParameters parameters;
  
  /// {@macro distribution_parameters_changed}
  DistributionParametersChanged(this.parameters);

  @override
  List<Object?> get props => [parameters];
}

/// {@template distribution_generate_requested}
/// Событие запроса генерации значений.
/// {@endtemplate}
class DistributionGenerateRequest extends DistributionEvent{

  final int sampleSize;

  /// {@macro distribution_generate_request}
  DistributionGenerateRequest(this.sampleSize);

  @override
  List<Object?> get props => [sampleSize];
}

/// {@template distribution_results_closed}
/// Событие закрытия экрана результатов.
/// {@endtemplate}
class DistributionResultsClosed extends DistributionEvent {
  DistributionResultsClosed();
}

/// {@template saved_result_selected}
/// Событие выбора сохраненного результата.
/// {@endtemplate}
class SavedResultSelected extends DistributionEvent {
  /// {@macro saved_result_selected}
  SavedResultSelected(this.savedResult);

  final SavedResult savedResult;

  @override
  List<Object> get props => [savedResult];
}

/// {@template save_current_result}
/// Событие сохранения текущего результата.
/// {@endtemplate}
class SaveCurrentResult extends DistributionEvent {
  /// {@macro save_current_result}
  SaveCurrentResult(this.name);

  final String name;

  @override
  List<Object> get props => [name];
}

class DistributionReset extends DistributionEvent {}