import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// {@template generated_value}
/// Класс для хранения информации о каждом сгенерированном значении.
/// Содержит итоговое значение, случайное число и индекс в кумулятивных вероятностях.
/// {@endtemplate}
class GeneratedValue {
  /// Итоговое сгенерированное значение
  final int value;

  /// Случайное число использованное для генерации
  final double randomU;

  /// Индекс в массиве вероятностей, куда попало случайное число
  final int indexInCumulative;

  GeneratedValue(this.value, this.randomU, this.indexInCumulative);
}

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

/// {@template results_screen}
/// Экран для отображения результатов генерации биномиального распределения.
/// Показывает график, таблицу частот и сгенерированные значения.
/// {@endtemplate}
class _ResultsScreenState extends State<ResultsScreen> {
  /// Список сгенерированных значений
  List<GeneratedValue>? _generatedValues; 

  bool _isLoading = false;

  /// Словарь частот значений (ключ - значение, значение - количество повторений)
  Map<int, int>? _frequencyDict; 

  /// Массив кумулятивных вероятностей [a_0, a_1, ..., a_n]
  List<double>? _cumulativeProbabilities;

  /// индекс для выбора таблицы
  int _selectedTab = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_generatedValues == null) {
      _generateResults(); 
    }
  }

  /// Вычисление биномиального коэффициента C(n, m)
  /// Используется итеративный подход для избежания переполнения целых чисел.
  /// Принимает:
  /// - [n] - общее количество элементов
  /// - [m] - количество выбираемых элементов
  /// Возвращает:
  /// - биномиальный коэффициент C(n, m)
  /// При невалидных параметрах возвращает 0
  int _binomialCoefficient(int n, int m) {
    if (m < 0 || m > n) return 0;
    if (m == 0 || m == n) return 1;
    
    // Используем свойство симметрии для уменьшения количества итераций
    if (m > n - m) {
      m = n - m;
    }
    
    int result = 1;
    for (int i = 1; i <= m; i++) {
      result = result * (n - i + 1) ~/ i;
    }
    return result;
  }

  /// Метод для расчета вероятности биномиального распределения.
  ///  Принимает:
  /// - [n] - количество испытаний
  /// - [p] - вероятность успеха в одном испытании
  /// - [m] - количество успехов
  /// Возвращает:
  /// - вероятность P(ξ = m)
  /// При граничных условиях (p=0 или p=1) возвращает соответствующие значения
  double _binomialProbability(int n, double p, int m) {
    if (m < 0 || m > n) return 0.0;
    if (p == 0.0) return (m == 0) ? 1.0 : 0.0; 
    if (p == 1.0) return (m == n) ? 1.0 : 0.0;
    
    final q = 1 - p;
    
    final coefficient = _binomialCoefficient(n, m);
    return (coefficient * pow(p, m) * pow(q, n - m)).toDouble();
    
  }

  /// Метод для создания массива кумулятивных вероятностей.
  /// Строит последовательность a_0, a_1, ..., a_n где a_i = ∑_{i=1}^{n} P_i (сумма вероятностей от 1 до i-той)
  /// Принимает:
  /// - [n] - количество испытаний
  /// - [p] - вероятность успеха
  /// Возвращает:
  /// - массив кумулятивных вероятностей длиной n+1
  List<double> _createProbabilities(int n, double p) {
    final probabilities = List<double>.generate(n + 1, (m) => _binomialProbability(n, p, m));
    
    // Нормализуем вероятности (из-за ошибок округления сумма может быть ≠ 1)
    final sum = probabilities.reduce((a, b) => a + b);
    final normalized = probabilities.map((prob) => prob / sum).toList();
    
    // Строим кумулятивные вероятности
    final cumulative = List<double>.filled(n + 1, 0.0);
    cumulative[0] = normalized[0];
    debugPrint('Вероятность для X = 0 равна ${normalized[0]}');
    
    for (int i = 1; i <= n; i++) {
      debugPrint('Вероятность для X = $i равна ${normalized[i]}');
      cumulative[i] = cumulative[i - 1] + normalized[i];
      debugPrint('Кумулятивная вероятность для X = $i равна ${cumulative[i]}');
    }
    
    // Гарантируем, что последнее значение равно 1.0
    cumulative[n] = 1.0;
    
    return cumulative;
  }

  /// Основной метод генерации результатов распределения.
  Future<void> _generateResults() async {
    setState(() => _isLoading = true);
    
    // просто получаем введенные значения значения 
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    final n = args['n'] as int;
    final p = args['p'] as double;
    final sampleSize = args['sampleSize'] as int;

    // Создаем кумулятивные вероятности для алгоритма обратного преобразования
    _cumulativeProbabilities = _createProbabilities(n, p);
    
    // Инициализируем словарь для подсчета частот
    final frequencyDict = <int, int>{};
    for (int i = 0; i <= n; i++) {
      frequencyDict[i] = 0;
    }
    
    final random = Random();
    final generatedValues = <GeneratedValue>[];
    
    for (int i = 0; i < sampleSize; i++) {
      final u = random.nextDouble(); // случайное число от 0 до 1
      
      int left = 0;
      int right = n;
      int selectedValue = n;
      int selectedIndex = n;
      
      // бинарным поиском ищем между какими вероятностями попала случ. вел.
      while (left <= right) {
        final mid = (left + right) ~/ 2;
        if (u <= _cumulativeProbabilities![mid]) {
          selectedValue = mid;
          selectedIndex = mid;
          right = mid - 1;
        } else {
          left = mid + 1;
        }
      }
      
      generatedValues.add(GeneratedValue(selectedValue, u, selectedIndex));
      frequencyDict[selectedValue] = frequencyDict[selectedValue]! + 1;
    }
    
    setState(() {
      _generatedValues = generatedValues;
      _frequencyDict = frequencyDict;
      _isLoading = false;
    });
  }

  /// Создание данных для графика
  List<FlSpot> _createChartData() {
    if (_frequencyDict == null) return [];
    
    final spots = <FlSpot>[];
    final sortedKeys = _frequencyDict!.keys.toList()..sort();
    
    for (final key in sortedKeys) {
      final frequency = _frequencyDict![key]!;
      spots.add(FlSpot(key.toDouble(), (frequency / _generatedValues!.length).toDouble()));
    }
    
    return spots;
  }


  // Показ диалога с информацией о выбранном значении
  void _showValueDetails(int index) {
    final generatedValue = _generatedValues![index];
    final n = _cumulativeProbabilities!.length - 1;
    
    String cumulativeRange = '';
    if (generatedValue.indexInCumulative == 0) {
      cumulativeRange = '0 ≤ u ≤ ${_cumulativeProbabilities![0].toStringAsFixed(6)}';
    } else {
      cumulativeRange = '${_cumulativeProbabilities![generatedValue.indexInCumulative - 1].toStringAsFixed(6)} < u ≤ ${_cumulativeProbabilities![generatedValue.indexInCumulative].toStringAsFixed(6)}';
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
                Text('a$i = ${_cumulativeProbabilities![i].toStringAsFixed(6)}${i == generatedValue.indexInCumulative ? '  ←' : ''}'),
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
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final n = args?['n'] as int? ?? 0;
    final p = args?['p'] as double? ?? 0.0;
    final sampleSize = args?['sampleSize'] as int? ?? 100;

    return DefaultTabController(
      length: 3,
      initialIndex: _selectedTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Результаты биномиального распределения'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              onTap: (index) => setState(() => _selectedTab = index),
              tabs: const [
                Tab(text: 'График'),
                Tab(text: 'Таблица'),
                Tab(text: 'Значения'),
              ],
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _generatedValues == null
                ? const Center(child: Text('Данные не сгенерированы'))
                : TabBarView(
                    children: [
                      _buildChartTab(n, p, sampleSize),
                      _buildTableTab(),
                      _buildValuesTab(),
                    ],
                  ),
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
              itemCount: _frequencyDict!.keys.length,
              itemBuilder: (context, index) {
                final key = _frequencyDict!.keys.elementAt(index);
                final value = _frequencyDict![key] ?? 0;
                final percentage = (value / _generatedValues!.length) * 100;
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text('Значение: $key'),
                    subtitle: LinearProgressIndicator(
                      value: value / _generatedValues!.length,
                      backgroundColor: Colors.grey[200],
                      color: Colors.blue,
                    ),
                    trailing: Text('$value (${percentage.toStringAsFixed(1)}%)'),
                    onTap: () {
                      // Находим первое значение с этим ключом
                      final firstIndex = _generatedValues!.indexWhere((v) => v.value == key);
                      if (firstIndex != -1) {
                        _showValueDetails(firstIndex);
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
            'Всего значений: ${_generatedValues!.length}',
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
              itemCount: _generatedValues!.length,
              itemBuilder: (context, index) {
                final value = _generatedValues![index].value;
                return GestureDetector(
                  onTap: () => _showValueDetails(index),
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