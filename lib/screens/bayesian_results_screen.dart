import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stats_master/services/calculators/chart_data_calculator.dart';
import '../models/bayesian_classifier.dart';
import '../models/classification_models.dart';
import '../models/distribution_parameters.dart';
import 'value_details_screen.dart';

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

class _BayesianResultsScreenState extends State<BayesianResultsScreen>
    with TickerProviderStateMixin {
  bool _isTesting = false;
  ClassificationResult? _testResult;
  List<double> _intersectionPoints = [];
  TheoreticalErrorInfo? _theoreticalErrorInfo;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _intersectionPoints = widget.classifier.findIntersectionPoints();
    _calculateTheoreticalError();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Результаты классификации'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: FadeTransition(
        opacity: _animationController,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildClassifierInfo(theme),
              const SizedBox(height: 20),
              _buildDensityChart(theme),
              const SizedBox(height: 20),
              _buildDecisionRule(theme),
              const SizedBox(height: 20),
              _buildTestResults(theme),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Строит карточку с информацией о параметрах классификатора.
  /// Принимает:
  /// - [theme] - текущая тема приложения для стилизации
  Widget _buildClassifierInfo(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Параметры классификатора',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildClassInfo(theme, widget.classifier.class1Name, widget.classifier.p1, widget.classifier.class1, theme.colorScheme.primary),
                _buildClassInfo(theme, widget.classifier.class2Name, widget.classifier.p2, widget.classifier.class2, theme.colorScheme.error),
              ],
            ),
            if (_intersectionPoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Точки пересечения: ${_intersectionPoints.map((x) => x.toStringAsFixed(3)).join(', ')}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Строит информацию о классе с параметрами распределения.
  /// Принимает:
  /// - [theme] - текущая тема приложения
  /// - [name] - название класса
  /// - [probability] - априорная вероятность класса
  /// - [params] - параметры распределения
  /// - [color] - цвет для стилизации класса
  Widget _buildClassInfo(ThemeData theme, String name, double probability, DistributionParameters params, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(name, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
          Text('P = ${probability.toStringAsFixed(3)}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(_getParamsDescription(params), style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  /// Возвращает строковое описание параметров распределения.
  /// Принимает:
  /// - [params] - параметры распределения
  String _getParamsDescription(DistributionParameters params) {
    return switch (params) {
      NormalParameters p => 'N(${p.m.toStringAsFixed(2)}, ${p.sigma.toStringAsFixed(2)})',
      UniformParameters p => 'U(${p.a.toStringAsFixed(2)}, ${p.b.toStringAsFixed(2)})',
      BinomialParameters p => 'B(${p.n}, ${p.p.toStringAsFixed(2)})',
      _ => 'Неизвестно',
    };
  }

  /// Строит график плотностей распределений.
  /// Принимает:
  /// - [theme] - текущая тема приложения для стилизации
  Widget _buildDensityChart(ThemeData theme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 400, maxHeight: 600),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Плотности распределения p(ωᵢ)·fᵢ(x)',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildCombinedChart(theme)),
              const SizedBox(height: 16),
              _buildLegend(theme),
            ],
          ),
        ),
      ),
    );
  }

  /// Строит комбинированный график плотностей с линиями и точками пересечения.
  /// Принимает:
  /// - [theme] - текущая тема приложения для цветов и стилей
  Widget _buildCombinedChart(ThemeData theme) {
    final minX = _getMinX();
    final maxX = _getMaxX();
    final maxY = _getMaxY();

    final class1Spots = ChartDataCalculator.generateSpotsForClass(widget.classifier.class1, widget.classifier.p1, minX, maxX);
    final class1IsCurved = widget.classifier.class1 is NormalParameters;
    final class1Fill = widget.classifier.class1 is! NormalParameters && widget.classifier.class1 is! BinomialParameters;

    final class2Spots = ChartDataCalculator.generateSpotsForClass(widget.classifier.class2, widget.classifier.p2, minX, maxX);
    final class2IsCurved = widget.classifier.class2 is NormalParameters;
    final class2Fill = widget.classifier.class2 is! NormalParameters && widget.classifier.class2 is! BinomialParameters;

    final intersectionSpots = _intersectionPoints.map((x) {
      final density1 = _calculateDensity(widget.classifier.class1, x) * widget.classifier.p1;
      return FlSpot(x, density1);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxY / 5,
          verticalInterval: _calculateXInterval(minX, maxX),
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
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
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
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
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
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
          LineChartBarData(
            spots: class1Spots,
            isCurved: class1IsCurved,
            color: theme.colorScheme.primary,
            barWidth: 2,
            isStrokeCapRound: true,
            belowBarData: class1Fill
                ? BarAreaData(
                    show: true,
                    gradient: LinearGradient(colors: [theme.colorScheme.primary.withValues(alpha: 0.2), Colors.transparent]),
                  )
                : BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: class2Spots,
            isCurved: class2IsCurved,
            color: theme.colorScheme.error,
            barWidth: 2,
            isStrokeCapRound: true,
            belowBarData: class2Fill
                ? BarAreaData(
                    show: true,
                    gradient: LinearGradient(colors: [theme.colorScheme.error.withValues(alpha: 0.2), Colors.transparent]),
                  )
                : BarAreaData(show: false),
          ),
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
                    color: theme.colorScheme.tertiary,
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
                  _ => touchedSpot.y.toStringAsFixed(4),
                };
                return LineTooltipItem(
                  text,
                  theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// Вычисляет интервал для осей X в графике.
  /// Принимает:
  /// - [minX] - минимальное значение X
  /// - [maxX] - максимальное значение X
  double _calculateXInterval(double minX, double maxX) {
    final range = maxX - minX;
    if (range <= 5) return 0.5;
    if (range <= 10) return 1.0;
    if (range <= 20) return 2.0;
    return 5.0;
  }


  /// Вычисляет плотность для заданного распределения в точке x.
  /// Принимает:
  /// - [params] - параметры распределения
  /// - [x] - значение точки
  double _calculateDensity(DistributionParameters params, double x) {
    return switch (params) {
      NormalParameters p => _normalDensity(x, p.m, p.sigma),
      UniformParameters p => _uniformDensity(x, p.a, p.b),
      BinomialParameters p => _binomialProbability(p.n, p.p, x.round()),
      _ => 0,
    };
  }

  /// Вычисляет плотность равномерного распределения.
  /// Принимает:
  /// - [x] - значение точки
  /// - [a] - нижняя граница
  /// - [b] - верхняя граница
  double _uniformDensity(double x, double a, double b) {
    return (x >= a && x <= b) ? 1 / (b - a) : 0;
  }

  /// Вычисляет плотность нормального распределения.
  /// Принимает:
  /// - [x] - значение точки
  /// - [m] - математическое ожидание
  /// - [sigma] - стандартное отклонение
  double _normalDensity(double x, double m, double sigma) {
    final exponent = -0.5 * pow((x - m) / sigma, 2);
    return (1 / (sigma * sqrt(2 * 3.1415926535))) * exp(exponent);
  }

  /// Вычисляет вероятность биномиального распределения.
  /// Принимает:
  /// - [n] - количество испытаний
  /// - [p] - вероятность успеха
  /// - [k] - количество успехов
  double _binomialProbability(int n, double p, int k) {
    if (k < 0 || k > n) return 0.0;
    if (p == 0.0) return (k == 0) ? 1.0 : 0.0; 
    if (p == 1.0) return (k == n) ? 1.0 : 0.0;
    
    final coefficient = _binomialCoefficient(n, k);
    return (coefficient * pow(p, k) * pow(1 - p, n - k)).toDouble();
  }

  /// Вычисляет биномиальный коэффициент.
  /// Принимает:
  /// - [n] - общее количество
  /// - [k] - выбираемое количество
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

  /// Вычисляет минимальное значение X для графика.
  double _getMinX() {
    final min1 = _getDistributionMin(widget.classifier.class1);
    final min2 = _getDistributionMin(widget.classifier.class2);
    return (min(min1, min2) - 1).clamp(-5.0, 0.0);
  }

  /// Вычисляет максимальное значение X для графика.
  double _getMaxX() {
    final max1 = _getDistributionMax(widget.classifier.class1);
    final max2 = _getDistributionMax(widget.classifier.class2);
    return (max(max1, max2) + 1).clamp(0.0, 50.0);
  }

  /// Вычисляет минимальное значение для распределения.
  /// Принимает:
  /// - [params] - параметры распределения
  double _getDistributionMin(DistributionParameters params) {
    return switch (params) {
      NormalParameters p => p.m - 3 * p.sigma,
      UniformParameters p => p.a,
      BinomialParameters p => 0.0,
      _ => 0,
    };
  }

  /// Вычисляет максимальное значение для распределения.
  /// Принимает:
  /// - [params] - параметры распределения
  double _getDistributionMax(DistributionParameters params) {
    return switch (params) {
      NormalParameters p => p.m + 3 * p.sigma,
      UniformParameters p => p.b,
      BinomialParameters p => p.n.toDouble(),
      _ => 1,
    };
  }

  /// Вычисляет максимальное значение Y для графика.
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
    
    return max(maxY * 1.2, 0.1);
  }

  /// Строит легенду для графика плотностей.
  /// Принимает:
  /// - [theme] - текущая тема приложения
  Widget _buildLegend(ThemeData theme) {
    final legendItems = <Widget>[
      _buildLegendItem(theme, widget.classifier.class1Name, theme.colorScheme.primary),
      const SizedBox(width: 16),
      _buildLegendItem(theme, widget.classifier.class2Name, theme.colorScheme.error),
    ];

    if (_intersectionPoints.isNotEmpty) {
      legendItems.addAll([
        const SizedBox(width: 16),
        _buildLegendItem(theme, 'Точки пересечения', theme.colorScheme.tertiary),
      ]);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: legendItems),
    );
  }

  /// Строит элемент легенды.
  /// Принимает:
  /// - [theme] - текущая тема
  /// - [text] - текст элемента
  /// - [color] - цвет элемента
  Widget _buildLegendItem(ThemeData theme, String text, Color color) {
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
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }

  /// Строит карточку с правилом классификации.
  /// Принимает:
  /// - [theme] - текущая тема приложения
  Widget _buildDecisionRule(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.rule, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Правило классификации',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Если ${widget.classifier.p1.toStringAsFixed(3)}·f₁(x) ≥ ${widget.classifier.p2.toStringAsFixed(3)}·f₂(x), '
              'то объект относится к ${widget.classifier.class1Name}, иначе к ${widget.classifier.class2Name}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (_intersectionPoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Границы решений: ${_intersectionPoints.map((x) => 'x = ${x.toStringAsFixed(3)}').join(', ')}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Вычисляет теоретическую ошибку классификатора.
  void _calculateTheoreticalError() {
    try {
      _theoreticalErrorInfo = widget.classifier.calculateTheoreticalErrorInfoAnalytical();
    } catch (error) {
      debugPrint('Ошибка при расчете теоретической ошибки: $error');
    }
  }

  /// Строит карточку с результатами тестирования.
  /// Принимает:
  /// - [theme] - текущая тема приложения
  Widget _buildTestResults(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Тестирование классификатора',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showClassificationDebug,
                    icon: const Icon(Icons.search),
                    label: const Text('Проверить классификацию'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _runClassificationTest,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Полный тест'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '1000 samples на класс',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            
            if (_theoreticalErrorInfo != null) ...[
              _buildTheoreticalErrorInfo(theme),
              const SizedBox(height: 16),
              
            ],

            if (_isTesting) ...[
              const SizedBox(height: 16),
              Column(
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('Генерация данных и тестирование...', style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
            
            if (_testResult != null) ...[
              const SizedBox(height: 16),
              _buildTestSummary(theme, _testResult!),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDetailedResults(_testResult!),
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Подробные результаты'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showValueSelection,
                      icon: const Icon(Icons.visibility),
                      label: const Text('Просмотреть значения'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Строит информацию о теоретической ошибке.
  /// Принимает:
  /// - [theme] - текущая тема приложения
  Widget _buildTheoreticalErrorInfo(ThemeData theme) {
    final info = _theoreticalErrorInfo!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                'Теоретическая вероятность ошибки',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTheoreticalStat(theme, 'Ошибка', '${(info.totalError * 100).toStringAsFixed(2)}%'),
              _buildTheoreticalStat(theme, 'Правильно', '${(info.correctProbability * 100).toStringAsFixed(2)}%'),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showTheoreticalErrorDetails,
            icon: const Icon(Icons.info_outline),
            label: const Text('Детали расчета'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Строит статистику теоретической ошибки.
  /// Принимает:
  /// - [theme] - текущая тема
  /// - [label] - метка статистики
  /// - [value] - значение статистики
  Widget _buildTheoreticalStat(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Показывает диалоговое окно с деталями теоретической ошибки.
  void _showTheoreticalErrorDetails() {
    if (_theoreticalErrorInfo == null) return;
    
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Text(
                    'Детали теоретического расчета ошибки',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildErrorCalculationExplanation(theme),
              const SizedBox(height: 20),
              _buildErrorIntervalsTable(theme),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Закрыть'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Строит объяснение метода расчета ошибки.
  /// Принимает:
  /// - [theme] - текущая тема
  Widget _buildErrorCalculationExplanation(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Метод расчета:',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('• Область интегрирования разбивается на интервалы точками пересечения'),
          const Text('• На каждом интервале вычисляется интеграл от меньшей из плотностей:'),
          const Text('  min(p(ω₁)·f₁(x), p(ω₂)·f₂(x))'),
          const Text('• Сумма интегралов дает общую вероятность ошибки'),
          const Text('• Метод Симпсона с 100 шагами на интервал'),
        ],
      ),
    );
  }

  /// Строит таблицу интервалов ошибки.
  /// Принимает:
  /// - [theme] - текущая тема
  Widget _buildErrorIntervalsTable(ThemeData theme) {
    final info = _theoreticalErrorInfo!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Вклад интервалов в общую ошибку:',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: theme.colorScheme.outline),
            columnWidths: const {
              0: FixedColumnWidth(80),
              1: FixedColumnWidth(80),
              2: FixedColumnWidth(80),
              3: FixedColumnWidth(100),
              4: FixedColumnWidth(80),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest),
                children: [
                  _buildTableCell(theme, 'Начало'),
                  _buildTableCell(theme, 'Конец'),
                  _buildTableCell(theme, 'Ошибка'),
                  _buildTableCell(theme, 'Проигрывающий класс'),
                  _buildTableCell(theme, 'Вклад %'),
                ],
              ),
              for (final interval in info.intervals)
                TableRow(
                  children: [
                    _buildTableCell(theme, interval.start.toStringAsFixed(2)),
                    _buildTableCell(theme, interval.end.toStringAsFixed(2)),
                    _buildTableCell(theme, interval.error.toStringAsFixed(4)),
                    _buildTableCell(theme, interval.losingClass, color: interval.losingClass == widget.classifier.class1Name ? theme.colorScheme.primary : theme.colorScheme.error),
                    _buildTableCell(theme, '${interval.errorPercentage(info.totalError).toStringAsFixed(1)}%', fontWeight: FontWeight.bold),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Общая вероятность ошибки:',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${(info.totalError * 100).toStringAsFixed(2)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Строит ячейку таблицы.
  /// Принимает:
  /// - [theme] - тема
  /// - [text] - текст
  /// - [color] - цвет (опционально)
  /// - [fontWeight] - жирность (опционально)
  Widget _buildTableCell(ThemeData theme, String text, {Color? color, FontWeight? fontWeight}) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ),
    );
  }

  /// Показывает диалог выбора значения для просмотра.
  void _showValueSelection() {
    if (_testResult == null) return;

    final samples = _testResult!.classifiedSamples;
    
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 600,
          height: 500,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.list_alt, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Выберите значение для детального просмотра',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: samples.length,
                  itemBuilder: (context, index) {
                    final sample = samples[index] as DetailedClassifiedSample;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: sample.isCorrect ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sample.isCorrect ? Colors.green : Colors.red,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              sample.value.toStringAsFixed(2),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: sample.isCorrect ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ),
                        title: Text('Значение: ${sample.value.toStringAsFixed(4)}', style: theme.textTheme.bodyMedium),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Истинный: ${sample.trueClass ? widget.classifier.class1Name : widget.classifier.class2Name}'),
                            Text('Прогноз: ${sample.predictedClass ? widget.classifier.class1Name : widget.classifier.class2Name}'),
                            Text(
                              sample.isCorrect ? '✓ Правильно' : '✗ Ошибка',
                              style: TextStyle(
                                color: sample.isCorrect ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
                        onTap: () {
                          Navigator.pop(context);
                          _showValueDetails(sample);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Закрыть'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Показывает экран деталей значения.
  /// Принимает:
  /// - [sample] - классифицированный сэмпл
  void _showValueDetails(DetailedClassifiedSample sample) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ValueDetailsScreen(
          classifier: widget.classifier,
          sample: sample,
          intersectionPoints: _intersectionPoints,
          theoreticalErrorInfo: _theoreticalErrorInfo,
        ),
      ),
    );
  }

  /// Строит сводку результатов теста.
  /// Принимает:
  /// - [theme] - текущая тема
  /// - [result] - результат классификации
  Widget _buildTestSummary(ThemeData theme, ClassificationResult result) {
    final errorColor = _getErrorRateColor(result.errorRate, theme);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Частота ошибок: ${(result.errorRate * 100).toStringAsFixed(2)}%',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Правильно классифицировано: ${result.correctClassifications}/${result.totalSamples}',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Определяет цвет для частоты ошибок.
  /// Принимает:
  /// - [errorRate] - частота ошибок
  /// - [theme] - тема
  Color _getErrorRateColor(double errorRate, ThemeData theme) {
    if (errorRate < 0.05) return theme.colorScheme.primary;
    if (errorRate < 0.15) return theme.colorScheme.secondary;
    return theme.colorScheme.error;
  }

  /// Запускает асинхронный тест классификации.
  Future<void> _runClassificationTest() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final result = await widget.classifier.calculateDetailedErrorRateAsync(
        samplesPerClass: 200,
      );
      
      if (mounted) {
        setState(() {
          _testResult = result;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при тестировании: $error', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
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

  /// Показывает диалог с детальными результатами теста.
  /// Принимает:
  /// - [result] - результат классификации
  void _showDetailedResults(ClassificationResult result) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Детальные результаты тестирования',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildConfusionMatrix(theme, result),
              const SizedBox(height: 20),
              _buildClassStatistics(theme, result),
              const SizedBox(height: 20),
              _buildIntersectionInfo(theme, result),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Закрыть'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Строит матрицу ошибок.
  /// Принимает:
  /// - [theme] - тема
  /// - [result] - результат
  Widget _buildConfusionMatrix(ThemeData theme, ClassificationResult result) {
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
        Text('Матрица ошибок:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: theme.colorScheme.outline),
            columnWidths: const {
              0: FixedColumnWidth(100),
              1: FixedColumnWidth(80),
              2: FixedColumnWidth(80),
            },
            children: [
              TableRow(children: [
                const TableCell(child: SizedBox()),
                _buildHeaderCell(theme, 'К1'),
                _buildHeaderCell(theme, 'К2'),
              ]),
              TableRow(children: [
                _buildHeaderCell(theme, 'К1'),
                _buildMatrixCell(theme, truePositive, 'TP', Colors.green),
                _buildMatrixCell(theme, falseNegative, 'FN', Colors.red),
              ]),
              TableRow(children: [
                _buildHeaderCell(theme, 'К2'),
                _buildMatrixCell(theme, falsePositive, 'FP', Colors.red),
                _buildMatrixCell(theme, trueNegative, 'TN', Colors.green),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  /// Строит заголовочную ячейку матрицы.
  /// Принимает:
  /// - [theme] - тема
  /// - [text] - текст
  Widget _buildHeaderCell(ThemeData theme, String text) {
    return TableCell(
      child: Container(
        color: theme.colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(text, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  /// Строит ячейку матрицы.
  /// Принимает:
  /// - [theme] - тема
  /// - [value] - значение
  /// - [label] - метка
  /// - [color] - цвет
  Widget _buildMatrixCell(ThemeData theme, int value, String label, Color color) {
    return TableCell(
      child: Container(
        color: color.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            children: [
              Text('$value', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }

  /// Строит статистику по классам.
  /// Принимает:
  /// - [theme] - тема
  /// - [result] - результат
  Widget _buildClassStatistics(ThemeData theme, ClassificationResult result) {
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
        Text('Статистика по классам:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildClassAccuracy(theme, widget.classifier.class1Name, class1Correct, class1Total, class1Accuracy.toDouble()),
        const SizedBox(height: 8),
        _buildClassAccuracy(theme, widget.classifier.class2Name, class2Correct, class2Total, class2Accuracy.toDouble()),
      ],
    );
  }

  /// Строит точность класса.
  /// Принимает:
  /// - [theme] - тема
  /// - [className] - название класса
  /// - [correct] - количество правильных
  /// - [total] - общее количество
  /// - [accuracy] - точность
  Widget _buildClassAccuracy(ThemeData theme, String className, int correct, int total, double accuracy) {
    final color = accuracy > 0.8 ? theme.colorScheme.primary : accuracy > 0.6 ? theme.colorScheme.secondary : theme.colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$className: $correct/$total (${(accuracy * 100).toStringAsFixed(1)}%)', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: accuracy,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  /// Строит информацию о границах решений.
  /// Принимает:
  /// - [theme] - тема
  /// - [result] - результат
  Widget _buildIntersectionInfo(ThemeData theme, ClassificationResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Границы решений:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (result.intersectionPoints.isEmpty)
          Text('Границы не найдены', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
        for (final point in result.intersectionPoints)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('x = ${point.toStringAsFixed(4)}', style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
          ),
      ],
    );
  }

  /// Показывает детальную проверку классификации для нескольких тестовых значений.
  void _showClassificationDebug() {
    final testSamples = <TestSample>[
      TestSample(value: 2.5, trueClass: false),
      TestSample(value: 3.5, trueClass: true),
      TestSample(value: 4.0, trueClass: true),
      TestSample(value: 4.5, trueClass: true),
      TestSample(value: 5.5, trueClass: false),
      TestSample(value: 6.0, trueClass: false),
    ];

    final debugResults = <ClassificationDebugResult>[];

    for (final sample in testSamples) {
      final x = sample.value;
      
      final density1 = _calculateDensity(widget.classifier.class1, x) * widget.classifier.p1;
      final density2 = _calculateDensity(widget.classifier.class2, x) * widget.classifier.p2;
      
      final predictedClass = density1 >= density2;
      
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

    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Детальная проверка классификации',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._buildDebugResults(theme, debugResults),
              const SizedBox(height: 20),
              _buildDebugSummary(theme, debugResults),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Закрыть'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Строит список результатов отладки.
  /// Принимает:
  /// - [theme] - тема
  /// - [results] - результаты отладки
  List<Widget> _buildDebugResults(ThemeData theme, List<ClassificationDebugResult> results) {
    return results.map((result) => _buildDebugResultCard(theme, result)).toList();
  }

  /// Строит карточку результата отладки.
  /// Принимает:
  /// - [theme] - тема
  /// - [result] - результат отладки
  Widget _buildDebugResultCard(ThemeData theme, ClassificationDebugResult result) {
    final cardColor = result.isCorrect ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1);
    final borderColor = result.isCorrect ? Colors.green : Colors.red;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'x = ${result.value.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
            const SizedBox(height: 12),
            
            Table(
              columnWidths: const {
                0: FixedColumnWidth(120),
                1: FixedColumnWidth(100),
                2: FixedColumnWidth(100),
              },
              children: [
                TableRow(children: [
                  TableCell(child: Text('Параметр', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
                  TableCell(child: Text(widget.classifier.class1Name, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold))),
                  TableCell(child: Text(widget.classifier.class2Name, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.bold))),
                ]),
                TableRow(children: [
                  const TableCell(child: Text('p(ωᵢ)·fᵢ(x)')),
                  TableCell(child: Text(result.density1.toStringAsFixed(4))),
                  TableCell(child: Text(result.density2.toStringAsFixed(4))),
                ]),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              'Правило: ${result.decisionRule}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            
            Row(
              children: [
                Text('Результат: ', style: theme.textTheme.bodyMedium),
                Text(
                  'Истинный класс: ${result.trueClass ? widget.classifier.class1Name : widget.classifier.class2Name}',
                  style: TextStyle(
                    color: result.trueClass ? theme.colorScheme.primary : theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(' → ', style: theme.textTheme.bodyMedium),
                Text(
                  'Предсказанный: ${result.predictedClass ? widget.classifier.class1Name : widget.classifier.class2Name}',
                  style: TextStyle(
                    color: result.predictedClass ? theme.colorScheme.primary : theme.colorScheme.error,
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

  /// Строит сводку отладки.
  /// Принимает:
  /// - [theme] - тема
  /// - [results] - результаты
  Widget _buildDebugSummary(ThemeData theme, List<ClassificationDebugResult> results) {
    final correctCount = results.where((r) => r.isCorrect).length;
    final totalCount = results.length;
    final accuracy = correctCount / totalCount;

    final summaryColor = accuracy > 0.8 ? theme.colorScheme.primaryContainer : accuracy > 0.6 ? theme.colorScheme.secondaryContainer : theme.colorScheme.errorContainer;
    final textColor = accuracy > 0.8 ? theme.colorScheme.onPrimaryContainer : accuracy > 0.6 ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: summaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сводка проверки:',
            style: theme.textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Правильно классифицировано: $correctCount/$totalCount', style: theme.textTheme.bodyMedium?.copyWith(color: textColor)),
          Text('Точность: ${(accuracy * 100).toStringAsFixed(1)}%', style: theme.textTheme.bodyMedium?.copyWith(color: textColor)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: accuracy,
            backgroundColor: textColor.withValues(alpha: 0.3),
            color: textColor,
            borderRadius: BorderRadius.circular(4),
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