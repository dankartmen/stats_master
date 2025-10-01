import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/saved_result.dart';
import '../../repositories/distribution_repository.dart';
import '../../repositories/saved_results_repository.dart';
import 'distribution_event.dart';
import 'distribution_state.dart';

/// {@template distribution_bloc}
/// BLoC для управления генерацией распределений.
/// {@endtemplate}
class DistributionBloc extends Bloc<DistributionEvent, DistributionState> {
  final DistributionRepository _repository;
  final SavedResultsRepository _savedResultsRepository;
  
  DistributionBloc(
    {
      required DistributionRepository repository,
      required SavedResultsRepository savedResultsRepository
    }): _repository = repository, _savedResultsRepository = savedResultsRepository, super(const DistributionInitial()) {
    on<DistributionTypeSelect>(_onDistributionTypeSelected);
    on<DistributionParametersChanged>(_onDistributionParametersChanged);
    on<DistributionGenerateRequest>(_onDistributionGenerateRequested);
    on<DistributionResultsClosed>(_onDistributionResultsClosed);
    on<DistributionReset>(_onDistributionReset);
    on<SavedResultSelected>(_onSavedResultSelected);
    on<SaveCurrentResult>(_onSaveCurrentResult);
  }
  FutureOr<void> _onDistributionTypeSelected(
    DistributionTypeSelect event,
    Emitter<DistributionState> emit,
  ) {
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
      final generatedResult = await _repository.generateResults(
        parameters: currentState.parameters,
        sampleSize: event.sampleSize,
      );

      emit(DistributionGenerationSuccess(
        generatedResult: generatedResult,
      ));
    } catch (error) {
      emit(DistributionErrorState(error.toString()));
    }
  }

  FutureOr<void> _onDistributionResultsClosed(
    DistributionResultsClosed event,
    Emitter<DistributionState> emit,
  ) {
    // Возвращаемся к состоянию ввода параметров
    if (state is DistributionGenerationSuccess) {
      final successState = state as DistributionGenerationSuccess;
      emit(DistributionParametersInput(parameters: successState.generatedResult.parameters));
    }
  }

  FutureOr<void> _onDistributionReset(
    DistributionReset event,
    Emitter<DistributionState> emit,
  ) {
    emit(const DistributionInitial());
  }
  FutureOr<void> _onSavedResultSelected(
    SavedResultSelected event,
    Emitter<DistributionState> emit,
  ) {
    final result = event.savedResult.generationResult;
    emit(DistributionGenerationSuccess(generatedResult: result));
  }

  FutureOr<void> _onSaveCurrentResult(
    SaveCurrentResult event,
    Emitter<DistributionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DistributionGenerationSuccess) return;

    emit(const DistributionSaveInProgress());

    try {
      final savedResult = SavedResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: event.name,
        generationResult: currentState.generatedResult,
        createdAt: DateTime.now(),
      );

      await _savedResultsRepository.saveResult(savedResult);
      emit(const DistributionSaveSuccess());
      
      // Возвращаемся к состоянию успешной генерации
      emit(currentState);
    } catch (error) {
      emit(DistributionErrorState(error.toString()));
    }
  }

}