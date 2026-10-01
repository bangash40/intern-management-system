import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/task.dart';
import '../providers/task_providers.dart';
import 'widgets/task_card.dart';

/// An intern's view of one task, with the button to move it forward.
class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  bool _isUpdating = false;

  Future<void> _move(Task task, TaskStatus next, {String? note}) async {
    setState(() => _isUpdating = true);
    try {
      await ref
          .read(taskRepositoryProvider)
          .updateStatus(task.id, next, submissionNote: note);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update the task. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _submit(Task task) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _SubmitDialog(initialNote: task.submissionNote),
    );
    if (note != null) {
      await _move(task, TaskStatus.submitted, note: note);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(taskProvider(widget.taskId));

    return Scaffold(
      appBar: AppBar(title: const Text('Task')),
      body: task.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorState(
          message: 'Could not load this task.',
          onRetry: () => ref.invalidate(taskProvider(widget.taskId)),
        ),
        data: (task) => task == null
            ? const EmptyState(
                icon: Icons.search_off,
                message: 'This task no longer exists.',
              )
            : _Body(
                task: task,
                isUpdating: _isUpdating,
                onStart: () => _move(task, TaskStatus.inProgress),
                onSubmit: () => _submit(task),
              ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.task,
    required this.isUpdating,
    required this.onStart,
    required this.onSubmit,
  });

  final Task task;
  final bool isUpdating;
  final VoidCallback onStart;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final overdue = task.isOverdue();

    return ListView(
      padding: const EdgeInsets.all(16),
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
          _NoteCard(title: 'Your submission note', text: task.submissionNote),
        ],
        const SizedBox(height: 24),
        _action(context),
      ],
    );
  }

  Widget _action(BuildContext context) {
    switch (task.status) {
      case TaskStatus.todo:
        return PrimaryButton(
          label: 'Start task',
          isLoading: isUpdating,
          onPressed: onStart,
        );
      case TaskStatus.inProgress:
        return PrimaryButton(
          label: 'Submit for review',
          isLoading: isUpdating,
          onPressed: onSubmit,
        );
      case TaskStatus.submitted:
        return const _StatusMessage(
          icon: Icons.hourglass_top,
          text: 'Submitted. Waiting for the admin to review it.',
        );
      case TaskStatus.completed:
        return const _StatusMessage(
          icon: Icons.check_circle_outline,
          text: 'This task is completed.',
        );
    }
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

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(text, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}

class _SubmitDialog extends StatefulWidget {
  const _SubmitDialog({this.initialNote = ''});

  final String initialNote;

  @override
  State<_SubmitDialog> createState() => _SubmitDialogState();
}

class _SubmitDialogState extends State<_SubmitDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialNote,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Submit for review'),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Note or link (optional)',
          alignLabelWithHint: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
