import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/bayesian_classifier.dart';
import '../models/classification_models.dart';
import '../models/distribution_parameters.dart';

/// {@template bayesian_results_screen}
/// Экран результатов байесовской классификации
/// {@endtemplate}
class BayesianResultsScreen extends StatefulWidget {
  /// {@macro bayesian_results_screen}
  const BayesianResultsScreen({
    super.key,
    required this.classifier,
  });

  final BayesianClassifier classifier;

  @override
  State<BayesianResultsScreen> createState() => _BayesianResultsScreenState();
}

class _BayesianResultsScreenState extends State<BayesianResultsScreen> {
  bool _isTesting = false;
  ClassificationResult? _testResult;
  List<double> _intersectionPoints = [];

  @override
  void initState() {
    super.initState();
    // Вычисляем точки пересечения при инициализации
    _intersectionPoints = widget.classifier.findIntersectionPoints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Результаты классификации'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildClassifierInfo(),
            const SizedBox(height: 20),
            _buildDensityChart(),
            const SizedBox(height: 20),
            _buildDecisionRule(),
            const SizedBox(height: 20),
            _buildTestResults(),
            const SizedBox(height: 20), // Добавляем отступ снизу
          ],
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Тестирование классификатора',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Кнопка для детальной проверки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showClassificationDebug,
                    child: const Text('Проверить классификацию'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _runClassificationTest,
                    child: const Text('Полный тест'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '1000 samples на класс',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            
            if (_isTesting) ...[
              const SizedBox(height: 16),
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Генерация данных и тестирование...'),
                ],
              ),
            ],
            
            if (_testResult != null) ...[
              const SizedBox(height: 16),
              _buildTestSummary(_testResult!),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showDetailedResults(_testResult!),
                  child: const Text('Подробные результаты'),
                ),
              ),
            ],
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
                _buildClassInfo(widget.classifier.class1Name, widget.classifier.p1, widget.classifier.class1),
                _buildClassInfo(widget.classifier.class2Name, widget.classifier.p2, widget.classifier.class2),
              ],
            ),
            if (_intersectionPoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Точки пересечения: ${_intersectionPoints.map((x) => x.toStringAsFixed(3)).join(', ')}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
      NormalParameters p => 'N(${p.m.toStringAsFixed(2)}, ${p.sigma.toStringAsFixed(2)})',
      UniformParameters p => 'U(${p.a.toStringAsFixed(2)}, ${p.b.toStringAsFixed(2)})',
      BinomialParameters p => 'B(${p.n}, ${p.p.toStringAsFixed(2)})',
      _ => 'Неизвестно',
    };
  }

  Widget _buildDensityChart() {
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
      ),
    );
  }

  Widget _buildCombinedChart() {
    final minX = _getMinX();
    final maxX = _getMaxX();
    final maxY = _getMaxY();

    // Line for class 1 (blue)
    final class1Spots = _generateSpotsForClass(widget.classifier.class1, widget.classifier.p1);
    final class1IsCurved = widget.classifier.class1 is NormalParameters;
    final class1Fill = widget.classifier.class1 is! NormalParameters && widget.classifier.class1 is! BinomialParameters;

    // Line for class 2 (red)
    final class2Spots = _generateSpotsForClass(widget.classifier.class2, widget.classifier.p2);
    final class2IsCurved = widget.classifier.class2 is NormalParameters;
    final class2Fill = widget.classifier.class2 is! NormalParameters && widget.classifier.class2 is! BinomialParameters;

    // Создаем споты для точек пересечения
    final intersectionSpots = _intersectionPoints.map((x) {
      final density1 = _calculateDensity(widget.classifier.class1, x) * widget.classifier.p1;
      return FlSpot(x, density1);
    }).toList();

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
            barWidth: 2,
            isStrokeCapRound: true,
            belowBarData: class1Fill
                ? BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.2),
                  )
                : BarAreaData(show: false),
          ),
          // Класс 2 (красный цвет)
          LineChartBarData(
            spots: class2Spots,
            isCurved: class2IsCurved,
            color: Colors.red,
            barWidth: 2,
            isStrokeCapRound: true,
            belowBarData: class2Fill
                ? BarAreaData(
                    show: true,
                    color: Colors.red.withOpacity(0.2),
                  )
                : BarAreaData(show: false),
          ),
          // Точки пересечения (зеленые точки)
          if (_intersectionPoints.isNotEmpty)
            LineChartBarData(
              spots: intersectionSpots,
              isCurved: false,
              color: Colors.transparent,
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.green,
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
                final text = switch (touchedSpot.barIndex) {
                  0 => '${widget.classifier.class1Name}: ${touchedSpot.y.toStringAsFixed(4)}',
                  1 => '${widget.classifier.class2Name}: ${touchedSpot.y.toStringAsFixed(4)}',
                  2 => 'Точка пересечения: x=${touchedSpot.x.toStringAsFixed(3)}',
                  _ => '${touchedSpot.y.toStringAsFixed(4)}',
                };
                return LineTooltipItem(
                  text,
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _calculateXInterval(double minX, double maxX) {
    final range = maxX - minX;
    if (range <= 5) return 0.5;
    if (range <= 10) return 1.0;
    if (range <= 20) return 2.0;
    return 5.0;
  }

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

  List<FlSpot> _generateBinomialPoints(BinomialParameters params, double probability) {
    final spots = <FlSpot>[];
    final minX = max(0.0, _getMinX());
    final maxX = min(params.n.toDouble(), _getMaxX());
    
    for (int k = 0; k <= params.n; k++) {
      final x = k.toDouble();
      final density = _binomialProbability(params.n, params.p, k) * probability;
      spots.add(FlSpot(x, density));
      
      // Добавляем точки для создания ступенчатого графика
      if (k < params.n) {
        spots.add(FlSpot(x + 0.999, density));
      }
    }
    
    // Добавляем граничные точки
    spots.insert(0, FlSpot(minX, 0));
    spots.add(FlSpot(maxX, 0));
    
    return spots;
  }

  double _calculateDensity(DistributionParameters params, double x) {
    return switch (params) {
      NormalParameters p => _normalDensity(x, p.m, p.sigma),
      UniformParameters p => _uniformDensity(x, p.a, p.b),
      BinomialParameters p => _binomialProbability(p.n, p.p, x.round()),
      _ => 0,
    };
  }

  double _uniformDensity(double x, double a, double b) {
    return (x >= a && x <= b) ? 1 / (b - a) : 0;
  }

  double _normalDensity(double x, double m, double sigma) {
    final exponent = -0.5 * pow((x - m) / sigma, 2);
    return (1 / (sigma * sqrt(2 * 3.1415926535))) * exp(exponent);
  }

  double _binomialProbability(int n, double p, int k) {
    if (k < 0 || k > n) return 0.0;
    if (p == 0.0) return (k == 0) ? 1.0 : 0.0; 
    if (p == 1.0) return (k == n) ? 1.0 : 0.0;
    
    final coefficient = _binomialCoefficient(n, k);
    return (coefficient * pow(p, k) * pow(1 - p, n - k)).toDouble();
  }

  int _binomialCoefficient(int n, int k) {
    if (k < 0 || k > n) return 0;
    if (k == 0 || k == n) return 1;
    
    if (k > n - k) {
      k = n - k;
    }
    
    int result = 1;
    for (int i = 1; i <= k; i++) {
      result = result * (n - i + 1) ~/ i;
    }
    return result;
  }

  double _getMinX() {
    final min1 = _getDistributionMin(widget.classifier.class1);
    final min2 = _getDistributionMin(widget.classifier.class2);
    return (min(min1, min2) - 1).clamp(-5.0, 0.0);
  }

  double _getMaxX() {
    final max1 = _getDistributionMax(widget.classifier.class1);
    final max2 = _getDistributionMax(widget.classifier.class2);
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
      final density1 = _calculateDensity(widget.classifier.class1, x) * widget.classifier.p1;
      final density2 = _calculateDensity(widget.classifier.class2, x) * widget.classifier.p2;
      maxY = max(maxY, max(density1, density2));
    }
    
    return max(maxY * 1.2, 0.1); // Добавляем 20% отступа, минимум 0.1
  }

  Widget _buildLegend() {
    final legendItems = <Widget>[
      _buildLegendItem(widget.classifier.class1Name, Colors.blue),
      const SizedBox(width: 16),
      _buildLegendItem(widget.classifier.class2Name, Colors.red),
    ];

    if (_intersectionPoints.isNotEmpty) {
      legendItems.addAll([
        const SizedBox(width: 16),
        _buildLegendItem('Точки пересечения', Colors.green),
      ]);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: legendItems,
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
            shape: text == 'Точки пересечения' ? BoxShape.circle : BoxShape.rectangle,
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
              'Если ${widget.classifier.p1.toStringAsFixed(3)}·f₁(x) ≥ ${widget.classifier.p2.toStringAsFixed(3)}·f₂(x), '
              'то объект относится к ${widget.classifier.class1Name}, иначе к ${widget.classifier.class2Name}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            if (_intersectionPoints.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Границы решений: ${_intersectionPoints.map((x) => 'x = ${x.toStringAsFixed(3)}').join(', ')}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  

  Widget _buildTestSummary(ClassificationResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getErrorRateColor(result.errorRate),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Частота ошибок: ${(result.errorRate * 100).toStringAsFixed(2)}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Правильно классифицировано: ${result.correctClassifications}/${result.totalSamples}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getErrorRateColor(double errorRate) {
    if (errorRate < 0.05) return Colors.green;
    if (errorRate < 0.15) return Colors.orange;
    return Colors.red;
  }

  Future<void> _runClassificationTest() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final result = await widget.classifier.calculateErrorRateAsync(
        samplesPerClass: 200,
      );
      
      setState(() {
        _testResult = result;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при тестировании: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  void _showDetailedResults(ClassificationResult result) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Детальные результаты тестирования',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildConfusionMatrix(result),
              const SizedBox(height: 20),
              _buildClassStatistics(result),
              const SizedBox(height: 20),
              _buildIntersectionInfo(result),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfusionMatrix(ClassificationResult result) {
    int truePositive = result.classifiedSamples
        .where((s) => s.trueClass && s.predictedClass)
        .length;
    int falsePositive = result.classifiedSamples
        .where((s) => !s.trueClass && s.predictedClass)
        .length;
    int trueNegative = result.classifiedSamples
        .where((s) => !s.trueClass && !s.predictedClass)
        .length;
    int falseNegative = result.classifiedSamples
        .where((s) => s.trueClass && !s.predictedClass)
        .length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Матрица ошибок:', 
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(),
          columnWidths: const {
            0: FixedColumnWidth(100),
            1: FixedColumnWidth(80),
            2: FixedColumnWidth(80),
          },
          children: [
            TableRow(children: [
              const TableCell(child: SizedBox()),
              TableCell(
                child: Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.all(8),
                  child: const Center(
                    child: Text('К1', 
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              TableCell(
                child: Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.all(8),
                  child: const Center(
                    child: Text('К2', 
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ]),
            TableRow(children: [
              TableCell(
                child: Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.all(8),
                  child: const Center(
                    child: Text('К1', 
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              TableCell(
                child: Container(
                  color: Colors.green[100],
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Column(
                      children: [
                        Text('$truePositive', 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('TP', style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              TableCell(
                child: Container(
                  color: Colors.red[100],
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Column(
                      children: [
                        Text('$falseNegative', 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('FN', style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
            TableRow(children: [
              TableCell(
                child: Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.all(8),
                  child: const Center(
                    child: Text('К2', 
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              TableCell(
                child: Container(
                  color: Colors.red[100],
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Column(
                      children: [
                        Text('$falsePositive', 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('FP', style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              TableCell(
                child: Container(
                  color: Colors.green[100],
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Column(
                      children: [
                        Text('$trueNegative', 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('TN', style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ],
    );
  }

  Widget _buildClassStatistics(ClassificationResult result) {
    int class1Correct = result.classifiedSamples
        .where((s) => s.trueClass && s.isCorrect)
        .length;
    int class2Correct = result.classifiedSamples
        .where((s) => !s.trueClass && s.isCorrect)
        .length;
    
    int class1Total = result.classifiedSamples
        .where((s) => s.trueClass)
        .length;
    int class2Total = result.classifiedSamples
        .where((s) => !s.trueClass)
        .length;
    
    final class1Accuracy = class1Total > 0 ? class1Correct / class1Total : 0;
    final class2Accuracy = class2Total > 0 ? class2Correct / class2Total : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Статистика по классам:', 
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildClassAccuracy(
          widget.classifier.class1Name, 
          class1Correct, 
          class1Total, 
          class1Accuracy.toDouble()
        ),
        const SizedBox(height: 8),
        _buildClassAccuracy(
          widget.classifier.class2Name, 
          class2Correct, 
          class2Total, 
          class2Accuracy.toDouble()
        ),
      ],
    );
  }

  Widget _buildClassAccuracy(String className, int correct, int total, double accuracy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$className: $correct/$total (${(accuracy * 100).toStringAsFixed(1)}%)'),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: accuracy,
          backgroundColor: Colors.grey[300],
          color: accuracy > 0.8 ? Colors.green : 
                 accuracy > 0.6 ? Colors.orange : Colors.red,
        ),
      ],
    );
  }

  Widget _buildIntersectionInfo(ClassificationResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Границы решений:', 
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (result.intersectionPoints.isEmpty)
          const Text('Границы не найдены', style: TextStyle(color: Colors.grey)),
        for (final point in result.intersectionPoints)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('x = ${point.toStringAsFixed(4)}', 
                style: const TextStyle(fontFamily: 'Monospace')),
          ),
      ],
    );
  }

  /// Показывает детальную проверку классификации для нескольких тестовых значений
  void _showClassificationDebug() {
    // Генерируем несколько тестовых значений вручную для демонстрации
    final testSamples = <TestSample>[
      TestSample(value: 2.5, trueClass: false), // Должен быть класс 2 (нормальный)
      TestSample(value: 3.5, trueClass: true),  // Должен быть класс 1 (равномерный)
      TestSample(value: 4.0, trueClass: true),  // Должен быть класс 1 (равномерный)
      TestSample(value: 4.5, trueClass: true),  // Должен быть класс 1 (равномерный)
      TestSample(value: 5.5, trueClass: false), // Должен быть класс 2 (нормальный)
      TestSample(value: 6.0, trueClass: false), // Должен быть класс 2 (нормальный)
    ];

    final debugResults = <ClassificationDebugResult>[];

    for (final sample in testSamples) {
      final x = sample.value;
      
      // Вычисляем плотности для обоих классов
      final density1 = _calculateDensity(widget.classifier.class1, x) * widget.classifier.p1;
      final density2 = _calculateDensity(widget.classifier.class2, x) * widget.classifier.p2;
      
      // Классифицируем
      final predictedClass = density1 >= density2;
      
      // Определяем результат
      final isCorrect = predictedClass == sample.trueClass;
      
      debugResults.add(ClassificationDebugResult(
        value: x,
        trueClass: sample.trueClass,
        predictedClass: predictedClass,
        density1: density1,
        density2: density2,
        isCorrect: isCorrect,
        decisionRule: density1 >= density2 ? 'p₁·f₁(x) ≥ p₂·f₂(x)' : 'p₁·f₁(x) < p₂·f₂(x)',
      ));
    }

    // Показываем диалог с детальной информацией
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Детальная проверка классификации',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._buildDebugResults(debugResults),
              const SizedBox(height: 20),
              _buildDebugSummary(debugResults),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDebugResults(List<ClassificationDebugResult> results) {
    return results.map((result) => _buildDebugResultCard(result)).toList();
  }

  Widget _buildDebugResultCard(ClassificationDebugResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с значением и результатом
            Row(
              children: [
                Text(
                  'x = ${result.value.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: result.isCorrect ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.isCorrect ? 'ВЕРНО' : 'ОШИБКА',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Информация о плотностях
            Table(
              columnWidths: const {
                0: FixedColumnWidth(120),
                1: FixedColumnWidth(100),
                2: FixedColumnWidth(100),
              },
              children: [
                TableRow(children: [
                  const TableCell(child: Text('Параметр', style: TextStyle(fontWeight: FontWeight.bold))),
                  TableCell(child: Text(widget.classifier.class1Name, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                  TableCell(child: Text(widget.classifier.class2Name, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                ]),
                TableRow(children: [
                  const TableCell(child: Text('p(ωᵢ)·fᵢ(x)')),
                  TableCell(child: Text(result.density1.toStringAsFixed(4))),
                  TableCell(child: Text(result.density2.toStringAsFixed(4))),
                ]),
              ],
            ),
            const SizedBox(height: 8),
            
            // Правило принятия решения
            Text(
              'Правило: ${result.decisionRule}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            
            // Результат классификации
            Row(
              children: [
                const Text('Результат: '),
                Text(
                  'Истинный класс: ${result.trueClass ? widget.classifier.class1Name : widget.classifier.class2Name}',
                  style: TextStyle(
                    color: result.trueClass ? Colors.blue : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(' → '),
                Text(
                  'Предсказанный: ${result.predictedClass ? widget.classifier.class1Name : widget.classifier.class2Name}',
                  style: TextStyle(
                    color: result.predictedClass ? Colors.blue : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugSummary(List<ClassificationDebugResult> results) {
    final correctCount = results.where((r) => r.isCorrect).length;
    final totalCount = results.length;
    final accuracy = correctCount / totalCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Сводка проверки:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Правильно классифицировано: $correctCount/$totalCount'),
          Text('Точность: ${(accuracy * 100).toStringAsFixed(1)}%'),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: accuracy,
            backgroundColor: Colors.grey[300],
            color: accuracy > 0.8 ? Colors.green : 
                  accuracy > 0.6 ? Colors.orange : Colors.red,
          ),
        ],
      ),
    );
  }






  


}


class ClassificationDebugResult {
  final double value;
  final bool trueClass;
  final bool predictedClass;
  final double density1;
  final double density2;
  final bool isCorrect;
  final String decisionRule;

  ClassificationDebugResult({
    required this.value,
    required this.trueClass,
    required this.predictedClass,
    required this.density1,
    required this.density2,
    required this.isCorrect,
    required this.decisionRule,
  });
}