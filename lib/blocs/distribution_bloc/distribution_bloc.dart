import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/calculators/estimation_calculator.dart';
import '../../models/saved_result.dart';
import '../../repositories/distribution_repository.dart';
import '../../repositories/saved_results_repository.dart';
import 'distribution_event.dart';
import 'distribution_state.dart';

/// {@template distribution_bloc}
/// BLoC для управления генерацией распределений.
/// Обрабатывает события выбора типа распределения, изменения параметров,
/// генерации значений, сохранения результатов и работы с сохраненными данными.
/// {@endtemplate}
class DistributionBloc extends Bloc<DistributionEvent, DistributionState> {
  /// Репозиторий для работы с распределениями.
  final DistributionRepository _repository;

  /// Репозиторий для работы с сохраненными результатами.
  final SavedResultsRepository _savedResultsRepository;
  
  /// {@macro distribution_bloc}
  /// Принимает:
  /// - [repository] - репозиторий для работы с распределениями
  /// - [savedResultsRepository] - репозиторий для работы с сохраненными результатами
  DistributionBloc({
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
    on<AllParametersChanged>(_onAllParametersChanged);
    on<EstimateAllParametersRequest>(_onEstimateAllParametersRequested);
  }

  /// Обработчик события выбора типа распределения.
  /// Переводит BLoC в состояние выбора распределения.
  /// Принимает:
  /// - [event] - событие выбора типа распределения
  /// - [emit] - эмиттер для изменения состояния
  FutureOr<void> _onDistributionTypeSelected(
    DistributionTypeSelect event,
    Emitter<DistributionState> emit,
  ) {
    emit(const DistributionSelection());
  }

  /// Обработчик события изменения параметров распределения.
  /// Переводит BLoC в состояние ввода параметров.
  /// Принимает:
  /// - [event] - событие изменения параметров распределения
  /// - [emit] - эмиттер для изменения состояния
  FutureOr<void> _onDistributionParametersChanged(
    DistributionParametersChanged event,
    Emitter<DistributionState> emit,
  ) {
    emit(DistributionParametersInput(parameters: event.parameters));
  }

  /// Обработчик события запроса генерации значений распределения.
  /// Выполняет асинхронную генерацию данных и переводит BLoC в соответствующее состояние.
  /// Принимает:
  /// - [event] - событие запроса генерации
  /// - [emit] - эмиттер для изменения состояния
  /// В случае ошибки переводит BLoC в состояние ошибки.
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

  /// Обработчик события закрытия экрана результатов.
  /// Возвращает BLoC к состоянию ввода параметров.
  /// Принимает:
  /// - [event] - событие закрытия результатов
  /// - [emit] - эмиттер для изменения состояния
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

  /// Обработчик события сброса состояния распределения.
  /// Возвращает BLoC в начальное состояние.
  /// Принимает:
  /// - [event] - событие сброса
  /// - [emit] - эмиттер для изменения состояния
  FutureOr<void> _onDistributionReset(
    DistributionReset event,
    Emitter<DistributionState> emit,
  ) {
    emit(const DistributionInitial());
  }

  /// Обработчик события выбора сохраненного результата.
  /// Переводит BLoC в состояние успешной генерации с выбранным результатом.
  /// Принимает:
  /// - [event] - событие выбора сохраненного результата
  /// - [emit] - эмиттер для изменения состояния
  FutureOr<void> _onSavedResultSelected(
    SavedResultSelected event,
    Emitter<DistributionState> emit,
  ) {
    final result = event.savedResult.generationResult;
    emit(DistributionGenerationSuccess(generatedResult: result));
  }

  /// Обработчик события сохранения текущего результата.
  /// Сохраняет текущий сгенерированный результат в репозиторий.
  /// Принимает:
  /// - [event] - событие сохранения результата
  /// - [emit] - эмиттер для изменения состояния
  /// В случае ошибки переводит BLoC в состояние ошибки.
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
  /// Обработчик события изменения параметров всех распределений.
  FutureOr<void> _onAllParametersChanged(
    AllParametersChanged event,
    Emitter<DistributionState> emit,
  ) {
    emit(AllParametersInput(parameters: event.parameters));
  }

  /// Обработчик события запроса оценки параметров всех распределений.
  FutureOr<void> _onEstimateAllParametersRequested(
    EstimateAllParametersRequest event,
    Emitter<DistributionState> emit,
  ) async {
    print('BLoC: Начало оценки всех параметров');

    final currentState = state;
    if (currentState is! AllParametersInput) {
      print('BLoC: Ошибка - состояние не AllParametersInput, а ${currentState}'); // Отладочная печать
      return;
    }

    emit(const DistributionLoadInProgress());
    print('BLoC: Состояние изменено на DistributionLoadInProgress');

    try {
      final calculator = EstimationCalculator(_repository);
      final estimates = await calculator.calculateAllEstimates(
        currentState.parameters,
      );
      print('BLoC: Оценки успешно вычислены');
      emit(AllEstimationSuccess(parameterEstimates: estimates));
      print('BLoC: Состояние изменено на AllEstimationSuccess');
    } catch (error) {
      emit(DistributionErrorState(error.toString()));
    }
  }
}