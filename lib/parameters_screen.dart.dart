import 'package:flutter/material.dart';

/// {@template parameters_screen}
/// Экран для ввода параметров биномиального распределения.
/// Позволяет пользователю задать количество испытаний, вероятность успеха
/// и размер выборки для генерации случайных значений.
/// {@endtemplate}
class ParametersScreen extends StatefulWidget {
  const ParametersScreen({super.key});

  @override
  State<ParametersScreen> createState() => _ParametersScreenState();
}

/// {@template parameters_screen_state}
/// Состояние экрана параметров, управляющее вводом данных и валидацией.
/// {@endtemplate}
class _ParametersScreenState extends State<ParametersScreen> {
  /// Ключ для управления состоянием формы
  final _formKey = GlobalKey<FormState>();

  /// Контроллер для ввода количества испытаний (n)
  final TextEditingController _nController = TextEditingController(text: '10');
  
  /// Контроллер для ввода вероятности успеха (p)
  final TextEditingController _pController = TextEditingController(text: '0.5');
  
  /// Контроллер для ввода размера выборки
  final TextEditingController _sampleSizeController = TextEditingController(text: '100');

  @override
  void dispose() {
    _nController.dispose();
    _pController.dispose();
    _sampleSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Параметры распределений'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nController,
                decoration: const InputDecoration(
                  labelText: 'n (Число испытаний)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста введите значение n';
                  }
                  final n = int.tryParse(value);
                  if (n == null || n <= 0) {
                    return 'n должен быть положительным целым числом';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pController,
                decoration: const InputDecoration(
                  labelText: 'p (вероятность успеха)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста введите значение p';
                  }
                  final p = double.tryParse(value);
                  if (p == null || p < 0 || p > 1) {
                    return 'p должна быть между 0 и 1';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sampleSizeController,
                decoration: const InputDecoration(
                  labelText: 'Размер выборки',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста введите размер выборки';
                  }
                  final size = int.tryParse(value);
                  if (size == null || size <= 0) {
                    return 'Размер выборки должен быть положительным целым числом';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final n = int.parse(_nController.text);
                    final p = double.parse(_pController.text);
                    final sampleSize = int.parse(_sampleSizeController.text);
                    
                    Navigator.pushNamed(
                      context,
                      '/results',
                      arguments: {
                        'n': n,
                        'p': p,
                        'sampleSize': sampleSize,
                      },
                    );
                  }
                },
                child: const Text('Сгенерировать значение'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}