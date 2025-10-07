import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/distribution_bloc/distribution_bloc.dart';
import '../blocs/distribution_bloc/distribution_event.dart';
import '../models/distribution_parameters.dart';
import '../models/generation_result.dart';
import '../models/interval.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.generatedResult});

  final GenerationResult generatedResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _showSaveDialog(context),
            tooltip: 'Сохранить результат',
          ),
        ],
      ),
      body: generatedResult.parameters is BinomialParameters
        ? _buildBinominalResults(context)
        : generatedResult.parameters is UniformParameters
            ? _buildUniformResults(context)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Это распределение пока не поддерживается'),
                ],
              ),
    );
  }
  
  /// Создание данных для графика
  List<FlSpot> _createChartData() {
    
    final spots = <FlSpot>[];
    final sortedKeys = generatedResult.frequencyDict.keys.toList()..sort();
    
    for (final key in sortedKeys) {
      final frequency = generatedResult.frequencyDict[key]!;
      spots.add(FlSpot(key.toDouble(), (frequency / generatedResult.results.length).toDouble()));
    }
    
    return spots;
  }


  // Показ диалога с информацией о выбранном значении
  void _showValueDetails(BuildContext context, int index) {
    final generatedValue = generatedResult.results[index];
    final n = generatedResult.cumulativeProbabilities.length - 1;
    
    String cumulativeRange = '';
    if (generatedValue.value == 0) {
      cumulativeRange = '0 ≤ u ≤ ${generatedResult.cumulativeProbabilities[0].toStringAsFixed(6)}';
    } else {
      cumulativeRange = '${generatedResult.cumulativeProbabilities[generatedValue.value.toInt() - 1].toStringAsFixed(6)} < u ≤ ${generatedResult.cumulativeProbabilities[generatedValue.value.toInt()].toStringAsFixed(6)}';
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
              Text('Случайное число u: ${generatedValue.randomU.toStringAsFixed(6)}'),
              const SizedBox(height: 8),
              const Text('Интервал  вероятностей:',
                style: TextStyle(fontWeight: FontWeight.bold)),
              Text(cumulativeRange),
              const SizedBox(height: 8),
              const Text('Вероятности:',
                style: TextStyle(fontWeight: FontWeight.bold)),
              for (int i = 0; i <= n; i++)
                Text('a$i = ${generatedResult.cumulativeProbabilities[i].toStringAsFixed(6)}${i == generatedValue.value ? '  ←' : ''}'),
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
  
  String _getAppBarTitle() {
    return switch (generatedResult.parameters) {
      BinomialParameters() => 'Результаты биномиального распределения',
      UniformParameters() => 'Результаты равномерного распределения',
      _ => 'Результаты',
    };
  }

  Widget _buildBinominalResults(BuildContext context){
    /// индекс для выбора таблицы
    int selectedTab = 0;
    final currentParameters = generatedResult.parameters as BinomialParameters;
    final n = currentParameters.n;
    final p = currentParameters.p;
    
    return DefaultTabController(
      length: 3,
      initialIndex: selectedTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Результаты биномиального распределения'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              onTap: (index) =>  selectedTab = index,
              tabs: const [
                Tab(text: 'График'),
                Tab(text: 'Таблица'),
                Tab(text: 'Значения'),
              ],
            ),
          ),
        ),
        body: TabBarView(
                children: [
                  _buildChartTab(n, p, generatedResult.sampleSize),
                  _buildTableTab(),
                  _buildResultsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildUniformResults(BuildContext context) {
    final uniformParameters = generatedResult.parameters as UniformParameters;
    final intervalData = generatedResult.intervalData;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Гистограмма'),
              Tab(text: 'Интервальный ряд'),
              Tab(text: 'Значения'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUniformHistogram(uniformParameters, intervalData),
            _buildIntervalSeriesTable(intervalData),
            _buildValuesTab(),
          ],  
        ),
      ),
    );
  }

  /// Гистограмма для равномерного распределения
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
              maxY: 1,
              groupsSpace: 0,
              barGroups: chartData.asMap().entries.map((entry) {
                final index = entry.key;
                debugPrint('Индекс для таблицы равен ${index}');
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

  /// Таблица интервального вариационного ряда
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
              final cumulativeProb = intervalData.cumulativeProbabilities[index];

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
                      Text('Кум: ${cumulativeProb.toStringAsFixed(3)}'),
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

  /// Создает данные для гистограммы равномерного распределения
  List<FlSpot> _createUniformChartData(UniformParameters parameters, IntervalData intervalData) {
  final spots = <FlSpot>[];
  
  for (final interval in intervalData.intervals) {
    final relativeFrequency = interval.frequency / (generatedResult.sampleSize * (parameters.b - parameters.a) / intervalData.numberOfIntervals);
    spots.add(FlSpot(interval.index.toDouble(), relativeFrequency));
  }
  
  return spots;
}

  /// Вычисляет максимальную частоту для шкалы Y
  double _calculateMaxFrequency(IntervalData intervalData) {
    double maxFreq = 0.0;
    for (final interval in intervalData.intervals) {
      final relativeFreq = interval.frequency / generatedResult.sampleSize;
      if (relativeFreq > maxFreq) {
        maxFreq = relativeFreq;
      }
    }
    return maxFreq;
  }

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
  /// Cоздание гистограммы для функции плотности распределения 
  Widget _buildChartTab(int n, double p, int sampleSize) {
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

  /// Cоздание таблицы с частотой распределения
  Widget _buildTableTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Таблица частотного распределения',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: generatedResult.frequencyDict.keys.length,
              itemBuilder: (context, index) {
                final key = generatedResult.frequencyDict.keys.elementAt(index);
                final value = generatedResult.frequencyDict[key] ?? 0;
                final percentage = (value / generatedResult.results.length) * 100;
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text('Значение: $key'),
                    subtitle: LinearProgressIndicator(
                      value: value / generatedResult.results.length,
                      backgroundColor: Colors.grey[200],
                      color: Colors.blue,
                    ),
                    trailing: Text('$value (${percentage.toStringAsFixed(1)}%)'),
                    onTap: () {
                      // Находим первое значение с этим ключом
                      final firstIndex = generatedResult.results.indexWhere((v) => v.value == key);
                      if (firstIndex != -1) {
                        _showValueDetails(context, firstIndex);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Cоздание с сгенерированными значениями
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
}