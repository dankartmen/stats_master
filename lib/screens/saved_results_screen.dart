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
/// {@endtemplate}
class _SavedResultCard extends StatelessWidget {
  const _SavedResultCard({required this.savedResult});

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

  Color _getColorForType(DistributionType type) {
    return switch (type) {
      DistributionType.binomial => Colors.blue,
      DistributionType.uniform => Colors.green,
    };
  }

  IconData _getIconForType(DistributionType type) {
    return switch (type) {
      DistributionType.binomial => Icons.bar_chart,
      DistributionType.uniform => Icons.show_chart,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}