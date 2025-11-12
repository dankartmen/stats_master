// screens/bayesian_results_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/bayesian_classifier.dart';
import '../models/distribution_parameters.dart';

/// {@template bayesian_results_screen}
/// Экран результатов байесовской классификации
/// {@endtemplate}
class BayesianResultsScreen extends StatelessWidget {
  /// {@macro bayesian_results_screen}
  const BayesianResultsScreen({
    super.key,
    required this.classifier,
  });

  final BayesianClassifier classifier;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Результаты классификации'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildClassifierInfo(),
            const SizedBox(height: 20),
            Expanded(
              child: _buildDensityChart(),
            ),
            const SizedBox(height: 20),
            _buildDecisionRule(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassifierInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Параметры классификатора',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildClassInfo(classifier.class1Name, classifier.p1, classifier.class1),
                _buildClassInfo(classifier.class2Name, classifier.p2, classifier.class2),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassInfo(String name, double probability, DistributionParameters params) {
    return Column(
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('P = ${probability.toStringAsFixed(3)}'),
        const SizedBox(height: 4),
        Text(_getParamsDescription(params), style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _getParamsDescription(DistributionParameters params) {
    return switch (params) {
      NormalParameters p => 'N(${p.m}, ${p.sigma})',
      UniformParameters p => 'U(${p.a}, ${p.b})',
      _ => 'Неизвестно',
    };
  }

  Widget _buildDensityChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Плотности распределения p(ωᵢ)·fᵢ(x)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildCombinedChart(),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedChart() {
    final minX = _getMinX();
    final maxX = _getMaxX();
    final maxY = _getMaxY();

    // Line for class 1 (blue)
    final class1Spots = _generateSpotsForClass(classifier.class1, classifier.p1);
    final class1IsCurved = classifier.class1 is NormalParameters;
    final class1Fill = classifier.class1 is! NormalParameters; // Fill for uniform

    // Line for class 2 (red)
    final class2Spots = _generateSpotsForClass(classifier.class2, classifier.p2);
    final class2IsCurved = classifier.class2 is NormalParameters;
    final class2Fill = classifier.class2 is! NormalParameters; // Fill for uniform

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: maxY / 5,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${value.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
            axisNameWidget: const Text(
              'Плотность',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1.0,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
            axisNameWidget: const Text(
              'Значение признака x',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          // Класс 1 (синий цвет)
          LineChartBarData(
            spots: class1Spots,
            isCurved: class1IsCurved,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: class1Fill
                ? BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.3),
                  )
                : BarAreaData(show: false),
          ),
          // Класс 2 (красный цвет)
          LineChartBarData(
            spots: class2Spots,
            isCurved: class2IsCurved,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: class2Fill
                ? BarAreaData(
                    show: true,
                    color: Colors.red.withOpacity(0.3),
                  )
                : BarAreaData(show: false),
          ),
        ],
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
      ),
    );
  }

  List<FlSpot> _generateSpotsForClass(DistributionParameters params, double probability) {
    if (params is NormalParameters) {
      return _generateNormalPoints(params, probability);
    } else if (params is UniformParameters) {
      return _generateUniformPoints(params, probability);
    }
    return [];
  }

  List<FlSpot> _generateNormalPoints(NormalParameters params, double probability) {
    final spots = <FlSpot>[];
    final minX = _getMinX();
    final maxX = _getMaxX();
    const steps = 100;
    
    for (int i = 0; i <= steps; i++) {
      final x = minX + (maxX - minX) * i / steps;
      final density = _normalDensity(x, params.m, params.sigma) * probability;
      spots.add(FlSpot(x, density));
    }
    
    return spots;
  }

  List<FlSpot> _generateUniformPoints(UniformParameters params, double probability) {
    final minX = _getMinX();
    final maxX = _getMaxX();
    final density = (1 / (params.b - params.a)) * probability;
    
    final spots = <FlSpot>[
      FlSpot(minX, 0),
      FlSpot(params.a, 0),
      FlSpot(params.a, density),
      FlSpot(params.b, density),
      FlSpot(params.b, 0),
      FlSpot(maxX, 0),
    ];
    
    return spots;
  }

  double _calculateDensity(DistributionParameters params, double x) {
    return switch (params) {
      NormalParameters p => _normalDensity(x, p.m, p.sigma),
      UniformParameters p => _uniformDensity(x, p.a, p.b),
      _ => 0,
    };
  }

  double _uniformDensity(double x, double a, double b) {
    // Для равномерного распределения плотность постоянна на интервале [a, b] и равна 0 вне его
    return (x >= a && x <= b) ? 1 / (b - a) : 0;
  }

  double _normalDensity(double x, double m, double sigma) {
    final exponent = -0.5 * pow((x - m) / sigma, 2);
    return (1 / (sigma * sqrt(2 * 3.1415926535))) * exp(exponent);
  }

  double _getMinX() {
    final min1 = _getDistributionMin(classifier.class1);
    final min2 = _getDistributionMin(classifier.class2);
    return min(min1, min2).clamp(0.0, 10.0); // Для U(3,5) и N(5,1) min = 2
  }

  double _getMaxX() {
    final max1 = _getDistributionMax(classifier.class1);
    final max2 = _getDistributionMax(classifier.class2);
    return (max(max1, max2) + 1).clamp(0.0, 10.0); // Для U(3,5) и N(5,1) max = 9
  }

  double _getDistributionMin(DistributionParameters params) {
    return switch (params) {
      NormalParameters p => p.m - 3 * p.sigma, // Для N(5,1) это 2
      UniformParameters p => p.a, // Для U(3,5) это 3
      _ => 0,
    };
  }

  double _getDistributionMax(DistributionParameters params) {
    return switch (params) {
      NormalParameters p => p.m + 3 * p.sigma, // Для N(5,1) это 8
      UniformParameters p => p.b, // Для U(3,5) это 5
      _ => 1,
    };
  }

  double _getMaxY() {
    double maxY = 0;
    final steps = 100;
    final minX = _getMinX();
    final maxX = _getMaxX();
    
    for (int i = 0; i <= steps; i++) {
      final x = minX + (maxX - minX) * i / steps;
      final density1 = _calculateDensity(classifier.class1, x) * classifier.p1;
      final density2 = _calculateDensity(classifier.class2, x) * classifier.p2;
      maxY = max(maxY, max(density1, density2));
    }
    
    return maxY * 1.1;
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(classifier.class1Name, Colors.blue),
        const SizedBox(width: 20),
        _buildLegendItem(classifier.class2Name, Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  Widget _buildDecisionRule() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Правило классификации',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Если ${classifier.p1.toStringAsFixed(3)}·f₁(x) ≥ ${classifier.p2.toStringAsFixed(3)}·f₂(x), '
              'то объект относится к ${classifier.class1Name.replaceAll('ый', 'ому').replaceAll('сс', 'су').toLowerCase()}, иначе к ${classifier.class2Name.replaceAll('ый', 'ому').replaceAll('сс', 'су').toLowerCase()}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}