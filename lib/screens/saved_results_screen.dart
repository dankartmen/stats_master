import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/distribution_bloc/distribution_bloc.dart';
import '../blocs/distribution_bloc/distribution_event.dart';
import '../models/distribution_type.dart';
import '../models/saved_result.dart';
import '../repositories/saved_results_repository.dart';
import 'results_screen.dart';

/// {@template saved_results_screen}
/// Экран для просмотра и загрузки сохраненных результатов.
/// Позволяет пользователю загружать и удалять
/// ранее сохраненные результаты генерации.
/// {@endtemplate}
class SavedResultsScreen extends StatelessWidget {
  /// {@macro saved_results_screen}
  const SavedResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сохраненные результаты'),
      ),
      body: FutureBuilder<List<SavedResult>>(
        future: context.read<SavedResultsRepository>().loadAllResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final results = snapshot.data ?? [];

          if (results.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет сохраненных результатов',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return _SavedResultCard(savedResult: result);
            },
          );
        },
      ),
    );
  }
}

/// {@template _saved_result_card}
/// Карточка сохраненного результата.
/// Отображает информацию о сохраненном результате и предоставляет
/// действия для загрузки или удаления.
/// {@endtemplate}
class _SavedResultCard extends StatelessWidget {
  const _SavedResultCard({required this.savedResult});

  /// Сохраненный результат для отображения.
  final SavedResult savedResult;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getColorForType(savedResult.distributionType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconForType(savedResult.distributionType),
            color: _getColorForType(savedResult.distributionType),
          ),
        ),
        title: Text(savedResult.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(savedResult.description),
            const SizedBox(height: 4),
            Text(
              'Создано: ${_formatDate(savedResult.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Значений: ${savedResult.generationResult.sampleSize}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'load', child: Text('Загрузить')),
            const PopupMenuItem(value: 'delete', child: Text('Удалить')),
          ],
        ),
        onTap: () => _loadResult(context),
      ),
    );
  }

  /// Загружает выбранный результат и переходит к экрану результатов.
  /// Принимает:
  /// - [context] - контекст построения виджета
  void _loadResult(BuildContext context) {
    context.read<DistributionBloc>().add(
      SavedResultSelected(savedResult),
    );
    Navigator.of(context).pop(); // Возвращаемся назад
    Navigator.of(context).pushReplacement( // Переходим к результатам
      MaterialPageRoute(
        builder: (context) => ResultsScreen(
          generatedResult: savedResult.generationResult,
        ),
      ),
    );
  }

  /// Обрабатывает действие из меню карточки.
  /// Принимает:
  /// - [context] - контекст построения виджета
  /// - [action] - выбранное действие ('load' или 'delete')
  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'load':
        _loadResult(context);
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  /// Показывает диалоговое окно подтверждения удаления.
  /// Принимает:
  /// - [context] - контекст построения виджета
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сохранение?'),
        content: Text('Вы уверены, что хотите удалить "${savedResult.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.read<SavedResultsRepository>().deleteResult(savedResult.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Сохранение удалено')),
              );
              // Обновляем экран
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const SavedResultsScreen()),
              );
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Получает цвет для типа распределения.
  /// Принимает:
  /// - [type] - тип распределения
  /// Возвращает:
  /// - [Color] - цвет для отображения
  Color _getColorForType(DistributionType type) {
    return switch (type) {
      DistributionType.binomial => Colors.blue,
      DistributionType.uniform => Colors.green,
      DistributionType.normal => Colors.blue,
    };
  }

  /// Получает иконку для типа распределения.
  /// Принимает:
  /// - [type] - тип распределения
  /// Возвращает:
  /// - [IconData] - иконку для отображения
  IconData _getIconForType(DistributionType type) {
    return switch (type) {
      DistributionType.binomial => Icons.bar_chart,
      DistributionType.uniform => Icons.show_chart,
      DistributionType.normal => Icons.show_chart,
    };
  }

  /// Форматирует дату для отображения.
  /// Принимает:
  /// - [date] - дата для форматирования
  /// Возвращает:
  /// - [String] - отформатированную строку даты
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}