import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../repositories/distribution_repository.dart';
import 'distribution_event.dart';
import 'distribution_state.dart';

/// {@template distribution_bloc}
/// BLoC для управления генерацией распределений.
/// {@endtemplate}
class DistributionBloc extends Bloc<DistributionEvent, DistributionState> {
  final DistributionRepository _repository;
  DistributionBloc({required DistributionRepository repository}): _repository = repository, super(const DistributionInitial()) {
    on<DistributionTypeSelect>(_onDistributionTypeSelected);
    on<DistributionParametersChanged>(_onDistributionParametersChanged);
    on<DistributionGenerateRequest>(_onDistributionGenerateRequested);
    on<DistributionReset>(_onDistributionReset);
  }
  FutureOr<void> _onDistributionTypeSelected(
    DistributionTypeSelect event,
    Emitter<DistributionState> emit,
  ) {
    // Здесь будет логика создания параметров по умолчанию
    // для выбранного типа распределения
    emit(const DistributionSelection());
  }

  FutureOr<void> _onDistributionParametersChanged(
    DistributionParametersChanged event,
    Emitter<DistributionState> emit,
  ) {
    emit(DistributionParametersInput(parameters: event.parameters));
  }

  FutureOr<void> _onDistributionGenerateRequested(
    DistributionGenerateRequest event,
    Emitter<DistributionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DistributionParametersInput) return;

    emit(const DistributionLoadInProgress());

    try {
      final generatedValues = await _repository.generateValues(
        parameters: currentState.parameters,
        sampleSize: event.sampleSize,
      );

      emit(DistributionGenerationSuccess(
        parameters: currentState.parameters,
        generatedValues: generatedValues,
        sampleSize: event.sampleSize,
      ));
    } catch (error) {
      emit(DistributionErrorState(error.toString()));
    }
  }

  FutureOr<void> _onDistributionReset(
    DistributionReset event,
    Emitter<DistributionState> emit,
  ) {
    emit(const DistributionInitial());
  }
}