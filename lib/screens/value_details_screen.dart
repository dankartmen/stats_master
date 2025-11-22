import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/bayesian_classifier.dart';
import '../models/classification_models.dart';
import '../models/distribution_parameters.dart';

/// {@template value_details_screen}
/// Экран деталей классификации конкретного значения.
/// Отображает подробную информацию о классификации, включая графики плотностей,
/// вероятности принадлежности классам и детали принятия решения классификатором.
/// {@endtemplate}
class ValueDetailsScreen extends StatelessWidget {
  /// Классификатор, использованный для классификации значения.
  final BayesianClassifier classifier;

  /// Детализированная информация о классифицированном значении.
  final DetailedClassifiedSample sample;

  /// Точки пересечения плотностей распределений (границы решений).
  final List<double> intersectionPoints;

  /// Теоретическая информация об ошибках классификации.
  final TheoreticalErrorInfo? theoreticalErrorInfo;

  /// {@macro value_details_screen}
  /// Принимает:
  /// - [classifier] - байесовский классификатор
  /// - [sample] - детали классифицированного значения
  /// - [intersectionPoints] - точки пересечения плотностей
  /// - [theoreticalErrorInfo] - теоретическая информация об ошибках
  const ValueDetailsScreen({
    super.key,
    required this.classifier,
    required this.sample,
    required this.intersectionPoints,
    this.theoreticalErrorInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали классификации значения'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildValueInfo(theme),
            const SizedBox(height: 20),
            _buildDetailedChart(theme),
            const SizedBox(height: 20),
            _buildClassificationInfo(theme),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Строит информацию о значении.
  /// Принимает:
  /// - [theme] - текущая тема приложения
  /// Возвращает:
  /// - [Widget] - карточку с информацией о значении и его классификации
  Widget _buildValueInfo(ThemeData theme) {
    final trueClassColor = sample.trueClass ? theme.colorScheme.primary : theme.colorScheme.error;
    final predictedClassColor = sample.predictedClass ? theme.colorScheme.primary : theme.colorScheme.error;
    final resultColor = sample.isCorrect ? Colors.green : Colors.red;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Значение: ${sample.value.toStringAsFixed(4)}',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(theme, 'Истинный класс', sample.trueClass ? classifier.class1Name : classifier.class2Name, trueClassColor),
                  const SizedBox(width: 20),
                  _buildInfoItem(theme, 'Прогнозируемый класс', sample.predictedClass ? classifier.class1Name : classifier.class2Name, predictedClassColor),
                  const SizedBox(width: 20),
                  _buildInfoItem(theme, 'Результат', sample.isCorrect ? 'Правильно' : 'Ошибка', resultColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Строит элемент информации.
  /// Принимает:
  /// - [theme] - тема приложения
  /// - [label] - метка элемента
  /// - [value] - значение элемента
  /// - [color] - цвет элемента
  /// Возвращает:
  /// - [Widget] - контейнер с информацией
  Widget _buildInfoItem(ThemeData theme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Строит детальный график с положением значения.
  /// Принимает:
  /// - [theme] - тема приложения
  /// Возвращает:
  /// - [Widget] - карточку с графиком плотностей и положением значения
  Widget _buildDetailedChart(ThemeData theme) {
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
                  Icon(Icons.analytics, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Положение значения на графике плотностей',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildValueChart(theme)),
              const SizedBox(height: 16),
              _buildChartLegend(theme),
            ],
          ),
        ),
      ),
    );
  }

  /// Строит график значения.
  /// Принимает:
  /// - [theme] - тема приложения
  /// Возвращает:
  /// - [Widget] - график с плотностями распределений и значением
  Widget _buildValueChart(ThemeData theme) {
    final minX = _getMinX();
    final maxX = _getMaxX();
    final maxY = _getMaxY();

    final class1Spots = _generateSpotsForClass(classifier.class1, classifier.p1);
    final class2Spots = _generateSpotsForClass(classifier.class2, classifier.p2);
    
    final valueSpot = FlSpot(sample.value, 0);
    final valueDensitySpot = FlSpot(sample.value, max(sample.density1, sample.density2));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxY / 5,
          verticalInterval: _calculateXInterval(minX, maxX),
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withOpacity(0.3),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withOpacity(0.3),
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
            isCurved: classifier.class1 is NormalParameters,
            color: theme.colorScheme.primary.withOpacity(0.6),
            barWidth: 2,
            isStrokeCapRound: true,
          ),
          LineChartBarData(
            spots: class2Spots,
            isCurved: classifier.class2 is NormalParameters,
            color: theme.colorScheme.error.withOpacity(0.6),
            barWidth: 2,
            isStrokeCapRound: true,
          ),
          LineChartBarData(
            spots: [valueSpot, valueDensitySpot],
            isCurved: false,
            color: Colors.green,
            barWidth: 1,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
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
                  color: sample.favorsClass1 ? theme.colorScheme.primary : theme.colorScheme.error,
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
                    color = theme.colorScheme.primary;
                  case 1:
                    text = '${classifier.class2Name}: ${touchedSpot.y.toStringAsFixed(4)}';
                    color = theme.colorScheme.error;
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
                    color = sample.favorsClass1 ? theme.colorScheme.primary : theme.colorScheme.error;
                  default:
                    text = '${touchedSpot.y.toStringAsFixed(4)}';
                    color = Colors.grey;
                }
                
                return LineTooltipItem(
                  text,
                  theme.textTheme.bodySmall!.copyWith(color: color, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// Строит легенду графика.
  /// Принимает:
  /// - [theme] - тема приложения
  /// Возвращает:
  /// - [Widget] - легенду с пояснениями цветов на графике
  Widget _buildChartLegend(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(theme, classifier.class1Name, theme.colorScheme.primary),
          const SizedBox(width: 16),
          _buildLegendItem(theme, classifier.class2Name, theme.colorScheme.error),
          const SizedBox(width: 16),
          _buildLegendItem(theme, 'Текущее значение', Colors.green),
        ],
      ),
    );
  }

  /// Строит элемент легенды.
  /// Принимает:
  /// - [theme] - тема приложения
  /// - [text] - текст элемента
  /// - [color] - цвет элемента
  /// Возвращает:
  /// - [Widget] - элемент легенды
  Widget _buildLegendItem(ThemeData theme, String text, Color color) {
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
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }

  /// Строит информацию о классификации.
  /// Принимает:
  /// - [theme] - тема приложения
  /// Возвращает:
  /// - [Widget] - карточку с детальной информацией о классификации
  Widget _buildClassificationInfo(ThemeData theme) {
    final favoredColor = sample.favorsClass1 ? theme.colorScheme.primaryContainer : theme.colorScheme.errorContainer;
    final favoredTextColor = sample.favorsClass1 ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onErrorContainer;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Информация о классификации',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (theoreticalErrorInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calculate, size: 16, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      'Теоретическая ошибка: ${(theoreticalErrorInfo!.totalError * 100).toStringAsFixed(2)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(150),
                  1: FixedColumnWidth(120),
                },
                children: [
                  _buildTableRow(theme, 'p(ω₁)·f₁(x)', sample.density1.toStringAsFixed(6)),
                  _buildTableRow(theme, 'p(ω₂)·f₂(x)', sample.density2.toStringAsFixed(6)),
                  _buildTableRow(theme, 'Разность', sample.decisionBoundary.toStringAsFixed(6), color: sample.decisionBoundary >= 0 ? theme.colorScheme.primary : theme.colorScheme.error),
                  _buildTableRow(theme, 'Уверенность', '${(sample.confidence * 100).toStringAsFixed(2)}%', color: sample.confidence > 0.1 ? theme.colorScheme.primary : theme.colorScheme.secondary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: favoredColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sample.favorsClass1 
                    ? '✓ Значение классифицировано в пользу ${classifier.class1Name}'
                    : '✓ Значение классифицировано в пользу ${classifier.class2Name}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: favoredTextColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (!sample.isCorrect) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: theme.colorScheme.onError, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠ Ошибка классификации: истинный класс отличается от прогнозируемого',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onError, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (intersectionPoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Границы решений: ${intersectionPoints.map((x) => 'x = ${x.toStringAsFixed(3)}').join(', ')}',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Строит строку таблицы.
  /// Принимает:
  /// - [theme] - тема приложения
  /// - [label] - метка строки
  /// - [value] - значение строки
  /// - [color] - цвет значения (опционально)
  /// Возвращает:
  /// - [TableRow] - строку таблицы
  TableRow _buildTableRow(ThemeData theme, String label, String value, {Color? color}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label, 
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// Генерирует точки для графика на основе типа распределения.
  /// Принимает:
  /// - [params] - параметры распределения
  /// - [probability] - априорная вероятность
  /// Возвращает:
  /// - [List<FlSpot>] - список точек для построения графика
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

  /// Генерирует точки для нормального распределения.
  /// Принимает:
  /// - [params] - параметры нормального распределения
  /// - [probability] - априорная вероятность
  /// Возвращает:
  /// - [List<FlSpot>] - список точек нормального распределения
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

  /// Генерирует точки для равномерного распределения.
  /// Принимает:
  /// - [params] - параметры равномерного распределения
  /// - [probability] - априорная вероятность
  /// Возвращает:
  /// - [List<FlSpot>] - список точек равномерного распределения
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

  /// Генерирует точки для биномиального распределения.
  /// Принимает:
  /// - [params] - параметры биномиального распределения
  /// - [probability] - априорная вероятность
  /// Возвращает:
  /// - [List<FlSpot>] - список точек биномиального распределения
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

  /// Вычисляет плотность нормального распределения.
  /// Принимает:
  /// - [x] - значение
  /// - [m] - математическое ожидание
  /// - [sigma] - стандартное отклонение
  /// Возвращает:
  /// - [double] - значение плотности в точке x
  double _normalDensity(double x, double m, double sigma) {
    final exponent = -0.5 * pow((x - m) / sigma, 2);
    return (1 / (sigma * sqrt(2 * 3.1415926535))) * exp(exponent);
  }

  /// Вычисляет вероятность биномиального распределения.
  /// Принимает:
  /// - [n] - количество испытаний
  /// - [p] - вероятность успеха
  /// - [k] - количество успехов
  /// Возвращает:
  /// - [double] - вероятность P(X = k)
  double _binomialProbability(int n, double p, int k) {
    if (k < 0 || k > n) return 0.0;
    final coefficient = _binomialCoefficient(n, k);
    return (coefficient * pow(p, k) * pow(1 - p, n - k)).toDouble();
  }

  /// Вычисляет биномиальный коэффициент.
  /// Принимает:
  /// - [n] - общее количество элементов
  /// - [k] - количество выбираемых элементов
  /// Возвращает:
  /// - [int] - биномиальный коэффициент C(n, k)
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

  /// Вычисляет минимальное значение X для графика.
  /// Возвращает:
  /// - [double] - минимальное значение X
  double _getMinX() {
    final min1 = _getDistributionMin(classifier.class1);
    final min2 = _getDistributionMin(classifier.class2);
    return (min(min1, min2) - 1).clamp(-5.0, 0.0);
  }

  /// Вычисляет максимальное значение X для графика.
  /// Возвращает:
  /// - [double] - максимальное значение X
  double _getMaxX() {
    final max1 = _getDistributionMax(classifier.class1);
    final max2 = _getDistributionMax(classifier.class2);
    return (max(max1, max2) + 1).clamp(0.0, 50.0);
  }

  /// Вычисляет минимальное значение для распределения.
  /// Принимает:
  /// - [params] - параметры распределения
  /// Возвращает:
  /// - [double] - минимальное значение распределения
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
  /// Возвращает:
  /// - [double] - максимальное значение распределения
  double _getDistributionMax(DistributionParameters params) {
    return switch (params) {
      NormalParameters p => p.m + 3 * p.sigma,
      UniformParameters p => p.b,
      BinomialParameters p => p.n.toDouble(),
      _ => 1,
    };
  }

  /// Вычисляет максимальное значение Y для графика.
  /// Возвращает:
  /// - [double] - максимальное значение Y
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

  /// Вычисляет плотность распределения в точке x.
  /// Принимает:
  /// - [params] - параметры распределения
  /// - [x] - точка, в которой вычисляется плотность
  /// Возвращает:
  /// - [double] - значение плотности
  double _calculateDensity(DistributionParameters params, double x) {
    return switch (params) {
      NormalParameters p => _normalDensity(x, p.m, p.sigma),
      UniformParameters p => (x >= p.a && x <= p.b) ? 1 / (p.b - p.a) : 0,
      BinomialParameters p => _binomialProbability(p.n, p.p, x.round()),
      _ => 0,
    };
  }

  /// Вычисляет интервал для оси X.
  /// Принимает:
  /// - [minX] - минимальное значение X
  /// - [maxX] - максимальное значение X
  /// Возвращает:
  /// - [double] - интервал для делений оси X
  double _calculateXInterval(double minX, double maxX) {
    final range = maxX - minX;
    if (range <= 5) return 0.5;
    if (range <= 10) return 1.0;
    if (range <= 20) return 2.0;
    return 5.0;
  }
}
