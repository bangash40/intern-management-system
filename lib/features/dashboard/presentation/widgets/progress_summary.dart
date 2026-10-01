import 'package:flutter/material.dart';

import '../../../../core/utils/progress.dart';

/// Counts by status plus a completion bar. Used on the intern dashboard and
/// on the admin's intern detail screen.
class ProgressSummary extends StatelessWidget {
  const ProgressSummary({super.key, required this.stats});

  final ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = stats.completionRate.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Completion', style: theme.textTheme.titleSmall),
            const Spacer(),
            Text('$percent%', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: stats.completionRate / 100,
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _Tile(label: 'Total', value: stats.total),
            _Tile(label: 'Pending', value: stats.pending),
            _Tile(label: 'In progress', value: stats.inProgress),
            _Tile(label: 'Completed', value: stats.completed),
          ],
        ),
        if (stats.overdue > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: scheme.error),
              const SizedBox(width: 6),
              Text(
                '${stats.overdue} overdue',
                style: TextStyle(color: scheme.error),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text('$value', style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
