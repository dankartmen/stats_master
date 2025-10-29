// Файл: lib/screens/all_parameter_estimation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/distribution_bloc/distribution_bloc.dart';
import '../blocs/distribution_bloc/distribution_state.dart';
import '../models/parameter_estimates.dart';

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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          'Математическое ожидание (μ)',
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

  String _calculateDifference(double theoretical, double estimated) {
    final difference = estimated - theoretical;
    final percentage = theoretical != 0 
        ? (difference / theoretical * 100).abs()
        : 0;
    return '${difference.toStringAsFixed(4)} (${percentage.toStringAsFixed(1)}%)';
  }
}