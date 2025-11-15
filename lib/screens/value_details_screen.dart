import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/bayesian_classifier.dart';
import '../models/classification_models.dart';
import '../models/distribution_parameters.dart';

class ValueDetailsScreen extends StatelessWidget {
  final BayesianClassifier classifier;
  final DetailedClassifiedSample sample;
  final List<double> intersectionPoints;
  final theoreticalErrorInfo;
  
  const ValueDetailsScreen({
    super.key,
    required this.classifier,
    required this.sample,
    required this.intersectionPoints, 
    this.theoreticalErrorInfo,
  });
  
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали классификации значения'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildValueInfo(),
            const SizedBox(height: 20),
            _buildDetailedChart(),
            const SizedBox(height: 20),
            _buildClassificationInfo(),
            const SizedBox(height: 20), // Добавляем отступ снизу для прокрутки
          ],
        ),
      ),
    );
  }

  Widget _buildValueInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Значение: ${sample.value.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem('Истинный класс', 
                      sample.trueClass ? classifier.class1Name : classifier.class2Name),
                  const SizedBox(width: 20),
                  _buildInfoItem('Прогнозируемый класс', 
                      sample.predictedClass ? classifier.class1Name : classifier.class2Name),
                  const SizedBox(width: 20),
                  _buildInfoItem('Результат', 
                      sample.isCorrect ? 'Правильно' : 'Ошибка',
                      color: sample.isCorrect ? Colors.green : Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedChart() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 400,
        maxHeight: 600,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Положение значения на графике плотностей',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildValueChart(),
              ),
              const SizedBox(height: 16),
              _buildChartLegend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueChart() {
    final minX = _getMinX();
    final maxX = _getMaxX();
    final maxY = _getMaxY();

    final class1Spots = _generateSpotsForClass(classifier.class1, classifier.p1);
    final class2Spots = _generateSpotsForClass(classifier.class2, classifier.p2);
    
    // Точка для текущего значения
    final valueSpot = FlSpot(sample.value, 0);
    final valueDensitySpot = FlSpot(sample.value, max(sample.density1, sample.density2));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY / 5,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    value.toStringAsFixed(2),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: _calculateXInterval(minX, maxX),
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          // Класс 1 (синий)
          LineChartBarData(
            spots: class1Spots,
            isCurved: classifier.class1 is NormalParameters,
            color: Colors.blue.withOpacity(0.6),
            barWidth: 2,
            isStrokeCapRound: true,
          ),
          // Класс 2 (красный)
          LineChartBarData(
            spots: class2Spots,
            isCurved: classifier.class2 is NormalParameters,
            color: Colors.red.withOpacity(0.6),
            barWidth: 2,
            isStrokeCapRound: true,
          ),
          // Пунктирная линия от значения
          LineChartBarData(
            spots: [valueSpot, valueDensitySpot],
            isCurved: false,
            color: Colors.green,
            barWidth: 1,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
          // Точка значения на оси X
          LineChartBarData(
            spots: [valueSpot],
            isCurved: false,
            color: Colors.transparent,
            barWidth: 0,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: Colors.green,
                  strokeWidth: 3,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
          // Точка на графике плотности
          LineChartBarData(
            spots: [valueDensitySpot],
            isCurved: false,
            color: Colors.transparent,
            barWidth: 0,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: sample.favorsClass1 ? Colors.blue : Colors.red,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                String text;
                Color color;
                
                switch (touchedSpot.barIndex) {
                  case 0:
                    text = '${classifier.class1Name}: ${touchedSpot.y.toStringAsFixed(4)}';
                    color = Colors.blue;
                  case 1:
                    text = '${classifier.class2Name}: ${touchedSpot.y.toStringAsFixed(4)}';
                    color = Colors.red;
                  case 2:
                    text = 'Значение: x=${touchedSpot.x.toStringAsFixed(3)}';
                    color = Colors.green;
                  case 3:
                    text = 'Положение значения: x=${touchedSpot.x.toStringAsFixed(3)}';
                    color = Colors.green;
                  case 4:
                    final density = touchedSpot.y;
                    final favoredClass = sample.favorsClass1 ? classifier.class1Name : classifier.class2Name;
                    text = 'Плотность: ${density.toStringAsFixed(4)}\nВ пользу: $favoredClass';
                    color = sample.favorsClass1 ? Colors.blue : Colors.red;
                  default:
                    text = '${touchedSpot.y.toStringAsFixed(4)}';
                    color = Colors.grey;
                }
                
                return LineTooltipItem(
                  text,
                  TextStyle(color: color, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChartLegend() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(classifier.class1Name, Colors.blue),
          const SizedBox(width: 16),
          _buildLegendItem(classifier.class2Name, Colors.red),
          const SizedBox(width: 16),
          _buildLegendItem('Текущее значение', Colors.green),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildClassificationInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Информация о классификации',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Теоретическая вероятность ошибки для контекста
            if (theoreticalErrorInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Теоретическая ошибка: ',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${(theoreticalErrorInfo!.totalError * 100).toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(150),
                  1: FixedColumnWidth(120),
                },
                children: [
                  _buildTableRow('p(ω₁)·f₁(x)', sample.density1.toStringAsFixed(6)),
                  _buildTableRow('p(ω₂)·f₂(x)', sample.density2.toStringAsFixed(6)),
                  _buildTableRow(
                    'Разность', 
                    sample.decisionBoundary.toStringAsFixed(6),
                    color: sample.decisionBoundary >= 0 ? Colors.green : Colors.red,
                  ),
                  _buildTableRow(
                    'Уверенность', 
                    '${(sample.confidence * 100).toStringAsFixed(2)}%',
                    color: sample.confidence > 0.1 ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              sample.favorsClass1 
                  ? '✓ Значение классифицировано в пользу ${classifier.class1Name}'
                  : '✓ Значение классифицировано в пользу ${classifier.class2Name}',
              style: TextStyle(
                color: sample.favorsClass1 ? Colors.blue : Colors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (!sample.isCorrect) ...[
              const SizedBox(height: 8),
              Text(
                '⚠ Ошибка классификации: истинный класс отличается от прогнозируемого',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (intersectionPoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Границы решений: ${intersectionPoints.map((x) => 'x = ${x.toStringAsFixed(3)}').join(', ')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value, {Color? color}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label, 
            style: const TextStyle(fontWeight: FontWeight.w500)
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Вспомогательные методы для графика (аналогичные BayesianResultsScreen)
  List<FlSpot> _generateSpotsForClass(DistributionParameters params, double probability) {
    if (params is NormalParameters) {
      return _generateNormalPoints(params, probability);
    } else if (params is UniformParameters) {
      return _generateUniformPoints(params, probability);
    } else if (params is BinomialParameters) {
      return _generateBinomialPoints(params, probability);
    }
    return [];
  }

  List<FlSpot> _generateNormalPoints(NormalParameters params, double probability) {
    final spots = <FlSpot>[];
    final minX = _getMinX();
    final maxX = _getMaxX();
    const steps = 150;
    
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
    
    return [
      FlSpot(minX, 0),
      FlSpot(params.a, 0),
      FlSpot(params.a, density),
      FlSpot(params.b, density),
      FlSpot(params.b, 0),
      FlSpot(maxX, 0),
    ];
  }

  List<FlSpot> _generateBinomialPoints(BinomialParameters params, double probability) {
    final spots = <FlSpot>[];
    
    for (int k = 0; k <= params.n; k++) {
      final x = k.toDouble();
      final density = _binomialProbability(params.n, params.p, k) * probability;
      spots.add(FlSpot(x, density));
      
      if (k < params.n) {
        spots.add(FlSpot(x + 0.999, density));
      }
    }
    
    spots.insert(0, FlSpot(_getMinX(), 0));
    spots.add(FlSpot(_getMaxX(), 0));
    
    return spots;
  }

  double _normalDensity(double x, double m, double sigma) {
    final exponent = -0.5 * pow((x - m) / sigma, 2);
    return (1 / (sigma * sqrt(2 * 3.1415926535))) * exp(exponent);
  }

  double _binomialProbability(int n, double p, int k) {
    if (k < 0 || k > n) return 0.0;
    final coefficient = _binomialCoefficient(n, k);
    return (coefficient * pow(p, k) * pow(1 - p, n - k)).toDouble();
  }

  int _binomialCoefficient(int n, int k) {
    if (k < 0 || k > n) return 0;
    if (k == 0 || k == n) return 1;
    if (k > n - k) k = n - k;
    
    int result = 1;
    for (int i = 1; i <= k; i++) {
      result = result * (n - i + 1) ~/ i;
    }
    return result;
  }

  double _getMinX() {
    final min1 = _getDistributionMin(classifier.class1);
    final min2 = _getDistributionMin(classifier.class2);
    return (min(min1, min2) - 1).clamp(-5.0, 0.0);
  }

  double _getMaxX() {
    final max1 = _getDistributionMax(classifier.class1);
    final max2 = _getDistributionMax(classifier.class2);
    return (max(max1, max2) + 1).clamp(0.0, 50.0);
  }

  double _getDistributionMin(DistributionParameters params) {
    return switch (params) {
      NormalParameters p => p.m - 3 * p.sigma,
      UniformParameters p => p.a,
      BinomialParameters p => 0.0,
      _ => 0,
    };
  }

  double _getDistributionMax(DistributionParameters params) {
    return switch (params) {
      NormalParameters p => p.m + 3 * p.sigma,
      UniformParameters p => p.b,
      BinomialParameters p => p.n.toDouble(),
      _ => 1,
    };
  }

  double _getMaxY() {
    double maxY = 0;
    const steps = 100;
    final minX = _getMinX();
    final maxX = _getMaxX();
    
    for (int i = 0; i <= steps; i++) {
      final x = minX + (maxX - minX) * i / steps;
      final density1 = _calculateDensity(classifier.class1, x) * classifier.p1;
      final density2 = _calculateDensity(classifier.class2, x) * classifier.p2;
      maxY = max(maxY, max(density1, density2));
    }
    
    return max(maxY * 1.2, max(sample.density1, sample.density2) * 1.2);
  }

  double _calculateDensity(DistributionParameters params, double x) {
    return switch (params) {
      NormalParameters p => _normalDensity(x, p.m, p.sigma),
      UniformParameters p => (x >= p.a && x <= p.b) ? 1 / (p.b - p.a) : 0,
      BinomialParameters p => _binomialProbability(p.n, p.p, x.round()),
      _ => 0,
    };
  }

  double _calculateXInterval(double minX, double maxX) {
    final range = maxX - minX;
    if (range <= 5) return 0.5;
    if (range <= 10) return 1.0;
    if (range <= 20) return 2.0;
    return 5.0;
  }
}