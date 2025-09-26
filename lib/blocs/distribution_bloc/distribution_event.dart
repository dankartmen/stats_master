import 'package:equatable/equatable.dart';
import '../../models/distribution_parameters.dart';
/// {@template distribution_event}
/// Базовое событие для DistributionBloc.
/// {@endtemplate}
abstract class DistributionEvent with EquatableMixin{
  @override
  List<Object?> get props => [];
}

class DistributionTypeSelect extends DistributionEvent{

  final String distributionType;

  DistributionTypeSelect(this.distributionType);

  @override
  List<Object?> get props => [distributionType];
}

/// {@template distribution_parameters_changed}
/// Событие изменения параметров распределения.
/// {@endtemplate}
class DistributionParametersChanged extends DistributionEvent{
  final DistributionParameters parameters;
  
  DistributionParametersChanged(this.parameters);

  @override
  List<Object?> get props => [parameters];
}

/// {@template distribution_generate_requested}
/// Событие запроса генерации значений.
/// {@endtemplate}
class DistributionGenerateRequest extends DistributionEvent{

  final int sampleSize;

  DistributionGenerateRequest(this.sampleSize);

  @override
  List<Object?> get props => [sampleSize];
}

class DistributionReset extends DistributionEvent {}