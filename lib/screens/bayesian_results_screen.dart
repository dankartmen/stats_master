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
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    _buildDensityLine(1, Colors.blue),
                    _buildDensityLine(2, Colors.red),
                  ],
                  minX: _getMinX(),
                  maxX: _getMaxX(),
                  minY: 0,
                  maxY: _getMaxY(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildDensityLine(int classNumber, Color color) {
    final isClass1 = classNumber == 1;
    final params = isClass1 ? classifier.class1 : classifier.class2;
    final probability = isClass1 ? classifier.p1 : classifier.p2;
    
    final spots = _generateDensityPoints(params, probability);
    
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      belowBarData: BarAreaData(show: false),
    );
  }

  List<FlSpot> _generateDensityPoints(DistributionParameters params, double probability) {
    final spots = <FlSpot>[];
    final minX = _getMinX();
    final maxX = _getMaxX();
    const steps = 100;
    
    for (int i = 0; i <= steps; i++) {
      final x = minX + (maxX - minX) * i / steps;
      final density = _calculateDensity(params, x) * probability;
      spots.add(FlSpot(x, density));
    }
    
    return spots;
  }

  double _calculateDensity(DistributionParameters params, double x) {
    return switch (params) {
      NormalParameters p => _normalDensity(x, p.m, p.sigma),
      UniformParameters p => _uniformDensity(x, p.a, p.b),
      _ => 0,
    };
  }

  double _normalDensity(double x, double m, double sigma) {
    final exponent = -0.5 * pow((x - m) / sigma, 2);
    return (1 / (sigma * sqrt(2 * 3.1415926535))) * exp(exponent);
  }

  double _uniformDensity(double x, double a, double b) {
    return (x >= a && x <= b) ? 1 / (b - a) : 0;
  }

  double _getMinX() {
    final min1 = _getDistributionMin(classifier.class1);
    final min2 = _getDistributionMin(classifier.class2);
    return (min(min1, min2) - 1).clamp(-10.0, 10.0); // Ограничиваем диапазон
  }

  double _getMaxX() {
    final max1 = _getDistributionMax(classifier.class1);
    final max2 = _getDistributionMax(classifier.class2);
    return (max(max1, max2) + 1).clamp(-10.0, 15.0); // Ограничиваем диапазон
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
              'то объект относится к ${classifier.class1Name}, иначе к ${classifier.class2Name}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}