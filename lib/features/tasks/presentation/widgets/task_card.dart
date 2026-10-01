import 'package:flutter/material.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/utils/date_utils.dart';
import '../../models/task.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.showAssignee = false,
  });

  final Task task;
  final VoidCallback? onTap;

  /// Shows who the task is assigned to (used in the admin list).
  final bool showAssignee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final overdue = task.isOverdue();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TaskStatusChip(status: task.status),
                ],
              ),
              if (showAssignee && task.assignedToName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.assignedToName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: overdue ? scheme.error : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppDateUtils.formatDate(task.dueDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: overdue ? scheme.error : scheme.onSurfaceVariant,
                    ),
                  ),
                  if (overdue) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Overdue',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.flag_outlined,
                    size: 16,
                    color: _priorityColor(scheme),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.priority.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _priorityColor(scheme),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(ColorScheme scheme) => switch (task.priority) {
    TaskPriority.high => scheme.error,
    TaskPriority.medium => scheme.tertiary,
    TaskPriority.low => scheme.onSurfaceVariant,
  };
}

class TaskStatusChip extends StatelessWidget {
  const TaskStatusChip({super.key, required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      TaskStatus.todo => (scheme.surfaceContainerHighest, scheme.onSurface),
      TaskStatus.inProgress => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      TaskStatus.submitted => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      TaskStatus.completed => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: foreground),
      ),
    );
  }
}
