import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../../models/task.dart';
import 'task_card.dart';

/// The read-only details of a task, shared by the intern and admin screens.
class TaskInfo extends StatelessWidget {
  const TaskInfo({
    super.key,
    required this.task,
    this.submissionNoteTitle = 'Your submission note',
  });

  final Task task;
  final String submissionNoteTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final overdue = task.isOverdue();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(task.title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            TaskStatusChip(status: task.status),
            const SizedBox(width: 8),
            Text('${task.priority.label} priority'),
          ],
        ),
        const SizedBox(height: 16),
        _InfoRow(
          icon: Icons.event_outlined,
          label: 'Due',
          value:
              AppDateUtils.formatDate(task.dueDate) +
              (overdue ? '  (Overdue)' : ''),
          color: overdue ? scheme.error : null,
        ),
        if (task.assignedToName.isNotEmpty)
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Assigned to',
            value: task.assignedToName,
          ),
        const SizedBox(height: 16),
        Text('Description', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(task.description),
        if (task.adminRemarks.isNotEmpty) ...[
          const SizedBox(height: 16),
          _NoteCard(title: 'Admin remarks', text: task.adminRemarks),
        ],
        if (task.submissionNote.isNotEmpty) ...[
          const SizedBox(height: 16),
          _NoteCard(title: submissionNoteTitle, text: task.submissionNote),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: resolved),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: resolved)),
          Expanded(
            child: Text(value, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(text),
          ],
        ),
      ),
    );
  }
}
