import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/utils/progress.dart';

/// Pie chart of tasks by status, with a legend that shows the counts.
class StatusPieChart extends StatelessWidget {
  const StatusPieChart({super.key, required this.stats});

  final ProgressStats stats;

  static Color colorFor(TaskStatus status, ColorScheme scheme) =>
      switch (status) {
        TaskStatus.todo => scheme.outline,
        TaskStatus.inProgress => scheme.primary,
        TaskStatus.submitted => scheme.tertiary,
        TaskStatus.completed => scheme.secondary,
      };

  int _count(TaskStatus status) => switch (status) {
    TaskStatus.todo => stats.todo,
    TaskStatus.inProgress => stats.inProgress,
    TaskStatus.submitted => stats.submitted,
    TaskStatus.completed => stats.completed,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (stats.total == 0) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No tasks yet',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          height: 140,
          width: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 28,
              sections: [
                for (final status in TaskStatus.values)
                  if (_count(status) > 0)
                    PieChartSectionData(
                      value: _count(status).toDouble(),
                      color: colorFor(status, scheme),
                      title: '${_count(status)}',
                      radius: 38,
                      titleStyle: TextStyle(
                        color: scheme.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final status in TaskStatus.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorFor(status, scheme),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${status.label}: ${_count(status)}'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
