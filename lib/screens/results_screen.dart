import 'dart:math' show sqrt, pow;

import 'package:flutter/material.dart' hide Interval;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/distribution_bloc/distribution_bloc.dart';
import '../blocs/distribution_bloc/distribution_event.dart';
import '../models/distribution_parameters.dart';
import '../models/generation_result.dart';
import '../models/interval.dart';

/// {@template results_screen}
/// Экран отображения результатов генерации распределения.
/// Предоставляет различные представления данных: графики, таблицы и значения,
/// а также возможность сохранения результатов.
/// {@endtemplate}
class ResultsScreen extends StatelessWidget {
  /// Результат генерации для отображения.
  final GenerationResult generatedResult;

  /// {@macro results_screen}
  /// Принимает:
  /// - [generatedResult] - результат генерации значений распределения
  const ResultsScreen({super.key, required this.generatedResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _showSaveDialog(context),
            tooltip: 'Сохранить результат',
          ),
        ],
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.bar_chart), text: 'Гистограмма'),
                Tab(icon: Icon(Icons.table_chart), text: 'Таблица'),
                Tab(icon: Icon(Icons.list), text: 'Значения'),
                Tab(icon: Icon(Icons.analytics), text: 'Статистика'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildHistogramTab(),
                  _buildTableTab(),
                  _buildResultsTab(),
                  _buildStatisticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Получает заголовок AppBar на основе типа распределения.
  /// Возвращает:
  /// - [String] - заголовок экрана
  String _getAppBarTitle() {
    // if (generatedResult.parameters is BinomialParameters) {
    //   final params = generatedResult.parameters as BinomialParameters;
    //   return 'Результаты: Биномиальное (n=${params.n}, p=${params.p.toStringAsFixed(2)})';
    // } else if (generatedResult.parameters is UniformParameters) {
    //   final params = generatedResult.parameters as UniformParameters;
    //   return 'Результаты: Равномерное [${params.a}, ${params.b}]';
    // } else if (generatedResult.parameters is NormalParameters) {
    //   final params = generatedResult.parameters as NormalParameters;
    //   return 'Результаты: Нормальное (μ=${params.m}, σ=${params.sigma.toStringAsFixed(2)})';
    // }
    return 'Результаты генерации';
  }

  /// Строит вкладку с гистограммой.
  /// Возвращает:
  /// - [Widget] - гистограмму распределения
  Widget _buildHistogramTab() {
    if (generatedResult.parameters is BinomialParameters) {
      final params = generatedResult.parameters as BinomialParameters;
      return _buildBinominalHistogram(
        params.n,
        params.p,
        generatedResult.sampleSize,
      );
    } else if (generatedResult.parameters is UniformParameters) {
      final params = generatedResult.parameters as UniformParameters;
      return _buildUniformHistogram(
        params,
        generatedResult.intervalData,
      );
    } else if (generatedResult.parameters is NormalParameters) {
      final params = generatedResult.parameters as NormalParameters;
      return _buildNormalHistogram(
        params,
        generatedResult.intervalData,
      );
    } else {
      return const Center(
        child: Text('Гистограмма не поддерживается для данного распределения'),
      );
    }
  }

  /// Строит вкладку со значениями для дискретных распределений.
  /// Возвращает:
  /// - [Widget] - сетку сгенерированных значений
  Widget _buildResultsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Сгенерированные значения',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Всего значений: ${generatedResult.results.length}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: generatedResult.results.length,
              itemBuilder: (context, index) {
                final value = generatedResult.results[index].value;
                return GestureDetector(
                  onTap: () => _showValueDetails(context, index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Center(
                      child: Text(
                        value.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Строит вкладку со статистикой.
  /// Возвращает:
  /// - [Widget] - панель со статистическими данными
  Widget _buildStatisticsTab() {
    final mean = generatedResult.results.map((e) => e.value).reduce((a, b) => a + b) / generatedResult.results.length;
    final variance = generatedResult.results.map((e) => pow(e.value - mean, 2)).reduce((a, b) => a + b) / generatedResult.results.length;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Статистические характеристики', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Среднее: ${mean.toStringAsFixed(4)}'),
              Text('Дисперсия: ${variance.toStringAsFixed(4)}'),
              Text('Стандартное отклонение: ${sqrt(variance).toStringAsFixed(4)}'),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Создает данные для графика распределения.
  /// Возвращает:
  /// - [List<FlSpot>] - список точек для построения графика
  List<FlSpot> _createChartData() {
    
    final spots = <FlSpot>[];
    final sortedKeys = generatedResult.frequencyDict.keys.toList()..sort();
    
    for (final key in sortedKeys) {
      final frequency = generatedResult.frequencyDict[key]!;
      spots.add(FlSpot(key.toDouble(), (frequency / generatedResult.results.length).toDouble()));
    }
    
    return spots;
  }

  /// Показывает диалоговое окно с детальной информацией о значении.
  /// Принимает:
  /// - [context] - контекст построения виджета
  /// - [index] - индекс значения в результатах
  void _showValueDetails(BuildContext context, int index) {
    final generatedValue = generatedResult.results[index];
    final cumulativeProbabilities = generatedResult.cumulativeProbabilities;
    
    if (cumulativeProbabilities == null) {
      // Для непрерывных распределений показываем другую информацию
      _showContinuousValueDetails(context, index);
      return;
    }

    final n = cumulativeProbabilities.length - 1;
    String cumulativeRange = '';
    if (generatedValue.value == 0) {
      cumulativeRange = '0 ≤ u ≤ ${generatedResult.cumulativeProbabilities![0].toStringAsFixed(6)}';
    } else {
      cumulativeRange = '${generatedResult.cumulativeProbabilities![generatedValue.value.toInt() - 1].toStringAsFixed(6)} < u ≤ ${generatedResult.cumulativeProbabilities![generatedValue.value.toInt()].toStringAsFixed(6)}';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Информация о значении'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Значение: ${generatedValue.value}'),
              Text('Случайное число u: ${generatedValue.randomU?.toStringAsFixed(6)}'),
              const SizedBox(height: 8),
              const Text('Интервал  вероятностей:',
                style: TextStyle(fontWeight: FontWeight.bold)),
              Text(cumulativeRange),
              const SizedBox(height: 8),
              const Text('Вероятности:',
                style: TextStyle(fontWeight: FontWeight.bold)),
              for (int i = 0; i <= n; i++)
                Text('a$i = ${generatedResult.cumulativeProbabilities![i].toStringAsFixed(6)}${i == generatedValue.value ? '  ←' : ''}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  /// Показывает диалоговое окно с информацией о значении для непрерывных распределений.
  /// Принимает:
  /// - [context] - контекст построения виджета
  /// - [index] - индекс значения в результатах
  void _showContinuousValueDetails(BuildContext context, int index) {
    final generatedValue = generatedResult.results[index];
    final intervalData = generatedResult.intervalData;
    
    // Находим в каком интервале находится значение
    Interval? containingInterval;
    if (intervalData != null) {
      for (final interval in intervalData.intervals) {
        if (generatedValue.value >= interval.start && generatedValue.value < interval.end) {
          containingInterval = interval;
          break;
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Информация о значении'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Основная информация о значении
              _buildInfoRow('Значение:', generatedValue.value.toStringAsFixed(4)),
              if (generatedValue.randomU != null)
                _buildInfoRow('Случайное число u:', generatedValue.randomU!.toStringAsFixed(6)),
              
              const SizedBox(height: 12),
              
              // Информация об интервале
              if (containingInterval != null) ...[
                const Text('Интервальная информация:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                _buildInfoRow('Интервал:', '[${containingInterval.start.toStringAsFixed(2)}, ${containingInterval.end.toStringAsFixed(2)})'),
                _buildInfoRow('Середина интервала:', containingInterval.midpoint.toStringAsFixed(2)),
                _buildInfoRow('Частота в интервале:', '${containingInterval.frequency}'),
                _buildInfoRow('Относительная частота:', '${(containingInterval.relativeFrequency(generatedResult.sampleSize) * 100).toStringAsFixed(1)}%'),
              ] else ...[
                const Text('Интервальная информация:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                _buildInfoRow('Интервал:', 'Не найден'),
              ],
              
              const SizedBox(height: 12),
              
              // Дополнительная информация из additionalInfo
              if (generatedValue.additionalInfo.isNotEmpty) ...[
                const Text('Дополнительная информация:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                for (final entry in generatedValue.additionalInfo.entries)
                  if (entry.value != null)
                    _buildInfoRow('${entry.key}:', entry.value.toString()),
              ],
              
              // Информация о распределении
              const SizedBox(height: 12),
              const Text('Параметры распределения:',
                style: TextStyle(fontWeight: FontWeight.bold)),
              _buildDistributionInfo(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  /// Вспомогательный метод для создания строки информации.
  /// Принимает:
  /// - [label] - метка информации
  /// - [value] - значение информации
  /// Возвращает:
  /// - [Widget] - строку с меткой и значением
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// Строит информацию о параметрах распределения.
  /// Возвращает:
  /// - [Widget] - информацию о параметрах распределения
  Widget _buildDistributionInfo() {
    final parameters = generatedResult.parameters;
    
    return switch (parameters) {
      UniformParameters p => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Тип:', 'Равномерное распределение'),
            _buildInfoRow('Нижняя граница (a):', p.a.toStringAsFixed(2)),
            _buildInfoRow('Верхняя граница (b):', p.b.toStringAsFixed(2)),
            _buildInfoRow('Теоретическая плотность:', '${(1/(p.b - p.a)).toStringAsFixed(4)}'),
          ],
        ),
      NormalParameters p => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Тип:', 'Нормальное распределение'),
            _buildInfoRow('Математическое ожидание (m):', p.m.toStringAsFixed(2)),
            _buildInfoRow('Стандартное отклонение (σ):', p.sigma.toStringAsFixed(2)),
          ],
        ),
      _ => _buildInfoRow('Тип:', 'Неизвестное распределение'),
    };
  }

  /// Показывает диалоговое окно для сохранения результата.
  /// Принимает:
  /// - [context] - контекст построения виджета
  void _showSaveDialog(BuildContext context) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить результат'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Название сохранения',
            hintText: 'Например: "Биномиальное n=10 p=0.5"',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                context.read<DistributionBloc>().add(
                  SaveCurrentResult(textController.text.trim()),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Результат сохранен!')),
                );
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
  


  /// Строит интерфейс результатов для биномиального распределения.
  /// Принимает:
  /// - [context] - контекст построения виджета
  /// Возвращает:
  /// - [Widget] - интерфейс с вкладками для биномиального распределения
  Widget _buildBinominalResults(BuildContext context){
    /// индекс для выбора таблицы
    int selectedTab = 0;
    final currentParameters = generatedResult.parameters as BinomialParameters;
    final n = currentParameters.n;
    final p = currentParameters.p;
    
    return DefaultTabController(
      length: 3,
      initialIndex: selectedTab,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: TabBar(
              onTap: (index) => selectedTab = index,
              tabs: const [
                Tab(text: 'График'),
                Tab(text: 'Таблица'),
                Tab(text: 'Значения'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildBinominalHistogram(n, p, generatedResult.sampleSize),
                _buildTableTab(),
                _buildResultsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Строит интерфейс результатов для равномерного распределения.
  /// Принимает:
  /// - [context] - контекст построения виджета
  /// Возвращает:
  /// - [Widget] - интерфейс с вкладками для равномерного распределения
  Widget _buildUniformResults(BuildContext context) {
    final uniformParameters = generatedResult.parameters as UniformParameters;
    final intervalData = generatedResult.intervalData;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: const TabBar(
              tabs: [
                Tab(text: 'Гистограмма'),
                Tab(text: 'Интервальный ряд'),
                Tab(text: 'Значения'),
              ],
            ),
          ),
          Expanded(
            child:  TabBarView(
              children: [
                _buildUniformHistogram(uniformParameters, intervalData),
                _buildIntervalSeriesTable(intervalData),
                _buildValuesTab(),
              ],  
            ),
          ),
        ],
      )
    );
  }

  /// Строит гистограмму для равномерного распределения.
  /// Принимает:
  /// - [parameters] - параметры равномерного распределения
  /// - [intervalData] - данные интервалов
  /// Возвращает:
  /// - [Widget] - гистограмму равномерного распределения
  Widget _buildUniformHistogram(UniformParameters parameters, IntervalData? intervalData) {
  if (intervalData == null) {
    return const Center(child: Text('Нет данных для гистограммы'));
  }

  final chartData = _createUniformChartData(parameters, intervalData);

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        Text(
          'Равномерное распределение U(${parameters.a}, ${parameters.b})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Размер выборки: ${generatedResult.sampleSize}, Интервалов: ${intervalData.numberOfIntervals}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Text(
          'Ширина интервала: ${intervalData.intervalWidth.toStringAsFixed(4)}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceBetween,
              maxY: _calculateMaxYForUniform(parameters, intervalData),
              groupsSpace: 0,
              barGroups: chartData.asMap().entries.map((entry) {
                final index = entry.key;
                final spot = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: spot.y,
                      width: 116,
                      color: Colors.green,
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                  showingTooltipIndicators: [0],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (intervalData.intervals.length > value.toInt()) {
                        final interval = intervalData.intervals[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${interval.start.toStringAsFixed(2)}-${interval.end.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return Text(value.toInt().toString());
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 35),
                ),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
      ],
    ),
  );
}

  /// Строит интерфейс результатов для нормального распределения.
  /// Принимает:
  /// - [context] - контекст построения виджета
  /// Возвращает:
  /// - [Widget] - интерфейс с вкладками для нормального распределения
  Widget _buildNormalResults(BuildContext context) {
    final normalParameters = generatedResult.parameters as NormalParameters;
    final intervalData = generatedResult.intervalData;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: const TabBar(
              tabs: [
                Tab(text: 'Гистограмма'),
                Tab(text: 'Интервальный ряд'),
                Tab(text: 'Значения'),
              ],
            ),
          ),
          Expanded(
            child:  TabBarView(
              children: [
                _buildNormalHistogram(normalParameters, intervalData),
                _buildIntervalSeriesTable(intervalData),
                _buildValuesTab(),
              ],  
            ),
          ),
        ],
      )
    );
  }

  /// Строит гистограмму для нормального распределения.
  /// Принимает:
  /// - [parameters] - параметры нормального распределения
  /// - [intervalData] - данные интервалов
  /// Возвращает:
  /// - [Widget] - гистограмму нормального распределения
  Widget _buildNormalHistogram(NormalParameters parameters, IntervalData? intervalData) {
    if (intervalData == null) {
      return const Center(child: Text('Нет данных для гистограммы'));
    }

    final chartData = _createNormalChartData(intervalData);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Нормальное распределение N(${parameters.m}, ${parameters.sigma})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Размер выборки: ${generatedResult.sampleSize}, Интервалов: ${intervalData.numberOfIntervals}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            'Ширина интервала: ${intervalData.intervalWidth.toStringAsFixed(4)}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: _calculateMaxYForNormal(parameters, intervalData),
                groupsSpace: 0,
                barGroups: chartData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final spot = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: spot.y,
                        width: 116,
                        color: Colors.green,
                        borderRadius: BorderRadius.zero,
                      ),
                    ],
                    showingTooltipIndicators: [],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (intervalData.intervals.length > value.toInt()) {
                          final interval = intervalData.intervals[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${interval.start.toStringAsFixed(2)}-${interval.end.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return Text(value.toInt().toString());
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 35),
                  ),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Вычисляет максимальное значение Y для гистограммы равномерного распределения.
  /// Принимает:
  /// - [parameters] - параметры равномерного распределения
  /// - [intervalData] - данные интервалов
  /// Возвращает:
  /// - [double] - максимальное значение Y для оси графика
  double _calculateMaxYForUniform(UniformParameters parameters ,IntervalData intervalData) {
    double maxY = 0;
    for (final interval in intervalData.intervals) {
      final relativeFrequency = interval.frequency / (generatedResult.sampleSize * ((parameters.b - parameters.a) / intervalData.numberOfIntervals));
      if (relativeFrequency > maxY) {
        maxY = relativeFrequency;
      }
    }
    return maxY * 1.6;
  }

  /// Вычисляет максимальное значение Y для гистограммы нормального распределения.
  /// Принимает:
  /// - [parameters] - параметры нормального распределения
  /// - [intervalData] - данные интервалов
  /// Возвращает:
  /// - [double] - максимальное значение Y для оси графика
  double _calculateMaxYForNormal(NormalParameters parameters ,IntervalData intervalData) {
    double maxY = 0;
    for (final interval in intervalData.intervals) {
      final relativeFrequency = interval.frequency / (generatedResult.sampleSize * ((12) / intervalData.numberOfIntervals));
      if (relativeFrequency > maxY) {
        maxY = relativeFrequency;
      }
    }
    return maxY * 1.6;
  }

  /// Строит таблицу интервального вариационного ряда.
  /// Принимает:
  /// - [intervalData] - данные интервалов
  /// Возвращает:
  /// - [Widget] - таблицу интервального ряда
  Widget _buildIntervalSeriesTable(IntervalData? intervalData) {
    if (intervalData == null) {
      return const Center(child: Text('Нет данных интервального ряда'));
    }

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        const Text(
          'Интервальный вариационный ряд',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Количество интервалов: ${intervalData.numberOfIntervals}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: intervalData.intervals.length,
            itemBuilder: (context, index) {
              final interval = intervalData.intervals[index];
              final relativeFreq = interval.relativeFrequency(generatedResult.sampleSize);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(
                    'Интервал ${index + 1}: [${interval.start.toStringAsFixed(2)}, ${interval.end.toStringAsFixed(2)})',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Середина: ${interval.midpoint.toStringAsFixed(2)}'),
                      Text('Частота: ${interval.frequency}'),
                      LinearProgressIndicator(
                        value: relativeFreq,
                        backgroundColor: Colors.grey[200],
                        color: Colors.green,
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${(relativeFreq * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

  /// Создает данные для гистограммы равномерного распределения.
  /// Принимает:
  /// - [parameters] - параметры равномерного распределения
  /// - [intervalData] - данные интервалов
  /// Возвращает:
  /// - [List<FlSpot>] - список точек для построения гистограммы
  List<FlSpot> _createUniformChartData(UniformParameters parameters, IntervalData intervalData) {
    final spots = <FlSpot>[];
    
    for (final interval in intervalData.intervals) {
      final relativeFrequency = interval.frequency / (generatedResult.sampleSize * (parameters.b - parameters.a) / intervalData.numberOfIntervals);
      spots.add(FlSpot(interval.index.toDouble(), relativeFrequency));
    }
    
    return spots;
  }

  /// Создает данные для гистограммы нормального распределения.
  /// Принимает:
  /// - [intervalData] - данные интервалов
  /// Возвращает:
  /// - [List<FlSpot>] - список точек для построения гистограммы
  List<FlSpot> _createNormalChartData(IntervalData intervalData) {
    final spots = <FlSpot>[];
    
    for (final interval in intervalData.intervals) {
      final relativeFrequency = interval.frequency / (generatedResult.sampleSize * intervalData.intervalWidth);
      spots.add(FlSpot(interval.index.toDouble(), relativeFrequency));
    }
    
    return spots;
  }

  /// Строит вкладку со значениями для непрерывных распределений.
  /// Возвращает:
  /// - [Widget] - сетку сгенерированных значений
  Widget _buildValuesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Сгенерированные значения',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Всего значений: ${generatedResult.results.length}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: generatedResult.results.length,
              itemBuilder: (context, index) {
                final value = generatedResult.results[index].value;
                return GestureDetector(
                  onTap: () => _showValueDetails(context, index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Center(
                      child: Text(
                        value.toStringAsFixed(generatedResult.parameters is UniformParameters ? 2 : 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Строит гистограмму для биномиального распределения.
  /// Принимает:
  /// - [n] - количество испытаний
  /// - [p] - вероятность успеха
  /// - [sampleSize] - размер выборки
  /// Возвращает:
  /// - [Widget] - гистограмму биномиального распределения
  Widget _buildBinominalHistogram(int n, double p, int sampleSize) {
    final chartData = _createChartData();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Биномиальное распределение: n=$n, p=${p.toStringAsFixed(3)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Размер выборки: $sampleSize значений',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.0,
                barGroups: chartData.map((spot){
                  return BarChartGroupData(
                    x: spot.x.toInt(),
                    barRods: [
                      BarChartRodData(
                        toY: spot.y,
                        width: 20,
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 1.0,
                          color: Colors.grey[200],
                        ),
                      ),
                    ]
                  );
                }).toList(),
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString());
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, color: Colors.blue, size: 12),
              SizedBox(width: 4),
              Text('B(n,p)', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  /// Строит таблицу частотного распределения с интервалами для непрерывных данных.
  /// Возвращает:
  /// - [Widget] - таблицу частот с интервалами
  Widget _buildTableTab() {
    // Получаем отсортированные ключи (интервалы)
    final sortedKeys = generatedResult.frequencyDict.keys.toList()..sort();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Таблица частотного распределения',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Всего значений: ${generatedResult.results.length}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          
          // Заголовок таблицы
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Интервал',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Частота',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Относительная частота',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '%',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final interval = sortedKeys[index];
                final value = generatedResult.frequencyDict[interval] ?? 0;
                final relativeFrequency = value / generatedResult.results.length;
                final percentage = relativeFrequency * 100;
                
                // Форматируем интервал для отображения
                final intervalText = _formatInterval(interval);
                
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      children: [
                        // Интервал
                        Expanded(
                          flex: 2,
                          child: Text(
                            intervalText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        // Частота
                        Expanded(
                          flex: 1,
                          child: Text(
                            value.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        
                        // Относительная частота (прогресс-бар)
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: LinearProgressIndicator(
                              value: relativeFrequency,
                              backgroundColor: Colors.grey[200],
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        
                        // Проценты
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${percentage.toStringAsFixed(1)}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

/// Форматирует интервал для отображения в таблице
String _formatInterval(dynamic interval) {
  if (interval is String) {
    return interval;
  } else if (interval is RangeValues) {
    return '${interval.start.toStringAsFixed(1)} - ${interval.end.toStringAsFixed(1)}';
  } else if (interval is List && interval.length == 2) {
    return '${interval[0].toStringAsFixed(1)} - ${interval[1].toStringAsFixed(1)}';
  } else {
    return interval.toString();
  }
}
}