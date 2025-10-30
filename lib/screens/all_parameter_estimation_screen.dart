import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/distribution_bloc/distribution_bloc.dart';
import '../blocs/distribution_bloc/distribution_state.dart';
import '../models/interval_estimates.dart';
import '../models/parameter_estimates.dart';
import '../services/calculators/interval_estimation_calculator.dart';

/// {@template all_parameter_estimation_screen}
/// Экран отображения оценок параметров всех распределений.
/// {@endtemplate}
class AllParameterEstimationScreen extends StatelessWidget {
  /// {@macro all_parameter_estimation_screen}
  const AllParameterEstimationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<DistributionBloc, DistributionState>(
      listener: (context, state) {
        if (state is DistributionErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: ${state.error}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Оценки параметров распределений'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocBuilder<DistributionBloc, DistributionState>(
          builder: (context, state) {
            if (state is AllEstimationSuccess) {
              return _buildEstimationContent(state.parameterEstimates);
            } else if (state is DistributionLoadInProgress) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return const Center(
                child: Text('Нет данных для отображения'),
              );
            }
          },
        ),
      ),
    );
  }

  /// Строит содержимое экрана с оценками параметров.
  /// Принимает:
  /// - [estimates] - оценки параметров всех распределений
  /// Возвращает:
  /// - [Widget] - виджет с содержимым экрана оценок
  Widget _buildEstimationContent(AllParameterEstimates estimates) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(estimates),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDistributionEstimate(estimates.binomial, Colors.blue),
                  const SizedBox(height: 16),
                  _buildDistributionEstimate(estimates.uniform, Colors.green),
                  const SizedBox(height: 16),
                  _buildDistributionEstimate(estimates.normal, Colors.orange),
                  const SizedBox(height: 16),
                  _buildIntervalEstimates(estimates.normal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Строит заголовок экрана с общей информацией.
  /// Принимает:
  /// - [estimates] - оценки параметров всех распределений
  /// Возвращает:
  /// - [Widget] - виджет заголовка с информацией о выборках
  Widget _buildHeader(AllParameterEstimates estimates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Оценки параметров распределений',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Общий размер выборок: ${estimates.totalSampleSize} значений',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Строит карточку с оценками параметров для одного распределения.
  /// Принимает:
  /// - [estimate] - точечные оценки распределения
  /// - [color] - цвет акцента для карточки
  /// Возвращает:
  /// - [Widget] - виджет карточки распределения
  Widget _buildDistributionEstimate(
      DistributionEstimate estimate, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок распределения
            Row(
              children: [
                Container(
                  width: 8,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  estimate.distributionName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'n = ${estimate.sampleSize}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Таблица оценок
            _buildEstimationTable(estimate),
          ],
        ),
      ),
    );
  }

  /// Строит таблицу с точечными оценками параметров распределения.
  /// Принимает:
  /// - [estimate] - точечные оценки распределения
  /// Возвращает:
  /// - [Widget] - виджет таблицы с оценками параметров
  Widget _buildEstimationTable(DistributionEstimate estimate) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.0),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
      },
      border: TableBorder.all(
        color: Colors.grey[300]!,
        borderRadius: BorderRadius.circular(8),
      ),
      children: [
        // Заголовок таблицы
        _buildTableHeader(),
        
        // Математическое ожидание
        _buildTableRow(
          'Математическое ожидание (M)',
          estimate.theoreticalMean.toStringAsFixed(4),
          estimate.sampleMean.toStringAsFixed(4),
          _calculateDifference(estimate.theoreticalMean, estimate.sampleMean),
        ),
        
        // Дисперсия
        _buildTableRow(
          'Дисперсия (σ²)',
          estimate.theoreticalVariance.toStringAsFixed(4),
          estimate.sampleVariance.toStringAsFixed(4),
          _calculateDifference(estimate.theoreticalVariance, estimate.sampleVariance),
        ),
        
        // Исправленная дисперсия
        _buildTableRow(
          'Исправленная дисперсия',
          '-',
          estimate.correctedSampleVariance.toStringAsFixed(4),
          null,
        ),
        
        // Стандартное отклонение
        _buildTableRow(
          'Стандартное отклонение (σ)',
          estimate.theoreticalSigma.toStringAsFixed(4),
          estimate.sampleSigma.toStringAsFixed(4),
          _calculateDifference(estimate.theoreticalSigma, estimate.sampleSigma),
        ),
      ],
    );
  }

  /// Строит заголовок таблицы оценок параметров.
  /// Возвращает:
  /// - [TableRow] - строка заголовка таблицы
  TableRow _buildTableHeader() {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      children: const [
        Padding(
          padding: EdgeInsets.all(12.0),
          child: Text(
            'Параметр',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(12.0),
          child: Text(
            'Теоретическое',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(12.0),
          child: Text(
            'Оценка',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Строит строку таблицы с оценкой параметра.
  /// Принимает:
  /// - [parameter] - название параметра
  /// - [theoretical] - теоретическое значение параметра
  /// - [estimated] - оцененное значение параметра
  /// - [difference] - разница между теоретическим и оцененным значением
  /// Возвращает:
  /// - [TableRow] - строка таблицы с данными параметра
  TableRow _buildTableRow(
      String parameter, String theoretical, String estimated, String? difference) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey[50]),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                parameter,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (difference != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Разница: $difference',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            theoretical,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theoretical == '-' ? Colors.grey : Colors.black,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            estimated,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  /// Вычисляет разницу между теоретическим и оцененным значением.
  /// Принимает:
  /// - [theoretical] - теоретическое значение параметра
  /// - [estimated] - оцененное значение параметра
  /// Возвращает:
  /// - [String] - форматированная строка с абсолютной разницей и процентным отклонением
  String _calculateDifference(double theoretical, double estimated) {
    final difference = estimated - theoretical;
    final percentage = theoretical != 0 
        ? (difference / theoretical * 100).abs()
        : 0;
    return '${difference.toStringAsFixed(4)} (${percentage.toStringAsFixed(1)}%)';
  }

  /// Строит интервальные оценки для нормального распределения.
  /// Принимает:
  /// - [normalEstimate] - точечные оценки нормального распределения
  /// Возвращает:
  /// - [Widget] - виджет с интервальными оценками
  Widget _buildIntervalEstimates(DistributionEstimate normalEstimate) {
    final calculator = IntervalEstimationCalculator();
    final intervalEstimates = calculator.calculateNormalIntervals(
      sampleMean: normalEstimate.sampleMean,
      sampleSigma: normalEstimate.sampleSigma,
      sampleSize: normalEstimate.sampleSize,
      theoreticalSigma: normalEstimate.theoreticalSigma,
      confidenceLevel: 0.95,
    );

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Container(
                  width: 8,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Интервальные оценки (нормальное распределение)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Информация о выборке
            _buildSampleInfo(intervalEstimates),
            const SizedBox(height: 16),
            
            // Доверительные интервалы
            _buildConfidenceIntervals(intervalEstimates),
          ],
        ),
      ),
    );
  }

  /// Строит информацию о выборке для интервальных оценок.
  /// Принимает:
  /// - [estimates] - интервальные оценки нормального распределения
  /// Возвращает:
  /// - [Widget] - виджет с информацией о выборке
  Widget _buildSampleInfo(NormalIntervalEstimates estimates) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Информация о выборке:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text('• Размер выборки: n = ${estimates.sampleSize}'),
          Text('• Выборочное среднее: x̄ = ${estimates.sampleMean.toStringAsFixed(4)}'),
          Text('• Выборочное стандартное отклонение: s = ${estimates.sampleSigma.toStringAsFixed(4)}'),
          Text('• Уровень доверия: ${(estimates.confidenceLevel * 100).toInt()}%'),
        ],
      ),
    );
  }

  /// Строит доверительные интервалы для отображения.
  /// Принимает:
  /// - [estimates] - интервальные оценки нормального распределения
  /// Возвращает:
  /// - [Widget] - виджет с доверительными интервалами
  Widget _buildConfidenceIntervals(NormalIntervalEstimates estimates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Доверительные интервалы:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        
        // Интервал для M (σ известна)
        _buildIntervalCard(
          estimates.sigmaKnown,
          'Для математического ожидания M (σ известна)',
          Colors.blue,
        ),
        const SizedBox(height: 12),
        
        // Интервал для M (σ неизвестна)
        _buildIntervalCard(
          estimates.sigmaUnknown,
          'Для математического ожидания M (σ неизвестна)',
          Colors.green,
        ),
        const SizedBox(height: 12),
        
        // Интервал для дисперсии
        _buildIntervalCard(
          estimates.varianceInterval,
          'Для дисперсии σ²',
          Colors.orange,
        ),
        
        // Пояснения
        const SizedBox(height: 16),
        _buildExplanations(),
      ],
    );
  }

  /// Строит карточку для отображения доверительного интервала.
  /// Принимает:
  /// - [interval] - доверительный интервал
  /// - [title] - заголовок карточки
  /// - [color] - цвет карточки
  /// Возвращает:
  /// - [Widget] - виджет карточки интервала
  Widget _buildIntervalCard(
    ConfidenceInterval interval,
    String title,
    Color color,
  ) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Доверительный интервал:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '[${interval.lowerBound.toStringAsFixed(4)}, ${interval.upperBound.toStringAsFixed(4)}]',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Ширина интервала: ${interval.width.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  'Центр: ${interval.center.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Строит пояснения к интервальным оценкам.
  /// Возвращает:
  /// - [Widget] - виджет с пояснениями
  Widget _buildExplanations() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Пояснения:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 8),
          Text('• M (σ известна) - используется нормальное распределение'),
          Text('• M (σ неизвестна) - используется t-распределение Стьюдента'),
          Text('• σ² (дисперсия) - используется χ²-распределение'),
          SizedBox(height: 8),
          Text(
            'Уровень доверия 95% означает, что в 95% случаев построенные таким образом интервалы будут содержать истинное значение параметра.',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}