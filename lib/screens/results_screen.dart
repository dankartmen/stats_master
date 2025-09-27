import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stats_master/models/distribution_parameters.dart';
import '../models/generated_value.dart';

class ResultsScreen extends StatelessWidget {
  ResultsScreen(
    {
      super.key, 
      required this.generatedValues, 
      required this.parameters, 
      required this.sampleSize,
      required this.cumulativeProbabilities,
      required this.frequencyDict,
      }
    );

  final List<GeneratedValue> generatedValues; 

  final DistributionParameters parameters;


  final int sampleSize;

  /// Словарь частот {значение: количество}
  final Map<int, int> frequencyDict;

  /// Кумулятивные вероятности [a_0, a_1, ..., a_n]
  final List<double> cumulativeProbabilities;

  /// Создание данных для графика
  List<FlSpot> _createChartData() {
    
    final spots = <FlSpot>[];
    final sortedKeys = frequencyDict.keys.toList()..sort();
    
    for (final key in sortedKeys) {
      final frequency = frequencyDict[key]!;
      spots.add(FlSpot(key.toDouble(), (frequency / generatedValues.length).toDouble()));
    }
    
    return spots;
  }


  // Показ диалога с информацией о выбранном значении
  void _showValueDetails(BuildContext context, int index) {
    final generatedValue = generatedValues[index];
    final n = cumulativeProbabilities.length - 1;
    
    String cumulativeRange = '';
    if (generatedValue.value == 0) {
      cumulativeRange = '0 ≤ u ≤ ${cumulativeProbabilities[0].toStringAsFixed(6)}';
    } else {
      cumulativeRange = '${cumulativeProbabilities[generatedValue.value - 1].toStringAsFixed(6)} < u ≤ ${cumulativeProbabilities[generatedValue.value].toStringAsFixed(6)}';
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
                Text('a$i = ${cumulativeProbabilities[i].toStringAsFixed(6)}${i == generatedValue.value ? '  ←' : ''}'),
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

  @override
  Widget build(BuildContext context) {
    /// индекс для выбора таблицы
    int selectedTab = 0;
    if (parameters is BinomialParameters){
      final currentParameters = parameters as BinomialParameters;
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
                    _buildChartTab(n, p, sampleSize),
                    _buildTableTab(),
                    _buildValuesTab(),
                  ],
                ),
        ),
      );
    }
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Это распределение пока не поддерживается')],);
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
              itemCount: frequencyDict.keys.length,
              itemBuilder: (context, index) {
                final key = frequencyDict.keys.elementAt(index);
                final value = frequencyDict[key] ?? 0;
                final percentage = (value / generatedValues.length) * 100;
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text('Значение: $key'),
                    subtitle: LinearProgressIndicator(
                      value: value / generatedValues.length,
                      backgroundColor: Colors.grey[200],
                      color: Colors.blue,
                    ),
                    trailing: Text('$value (${percentage.toStringAsFixed(1)}%)'),
                    onTap: () {
                      // Находим первое значение с этим ключом
                      final firstIndex = generatedValues.indexWhere((v) => v.value == key);
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
            'Всего значений: ${generatedValues.length}',
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
              itemCount: generatedValues.length,
              itemBuilder: (context, index) {
                final value = generatedValues[index].value;
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