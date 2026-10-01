import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/enums.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../models/task.dart';
import '../providers/task_providers.dart';
import 'widgets/task_info.dart';

/// An admin's view of one task. Submitted tasks can be approved or returned.
class AdminTaskDetailScreen extends ConsumerStatefulWidget {
  const AdminTaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<AdminTaskDetailScreen> createState() =>
      _AdminTaskDetailScreenState();
}

class _AdminTaskDetailScreenState extends ConsumerState<AdminTaskDetailScreen> {
  bool _isBusy = false;

  Future<void> _run(Future<void> Function() action, String doneMessage) async {
    setState(() => _isBusy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(doneMessage)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update the task.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _approve(Task task) async {
    final remarks = await showDialog<String>(
      context: context,
      builder: (_) => const _RemarksDialog(
        title: 'Approve task',
        label: 'Remarks (optional)',
        confirmLabel: 'Approve',
        required: false,
      ),
    );
    if (remarks == null) return;
    await _run(
      () => ref
          .read(taskRepositoryProvider)
          .approveTask(task.id, remarks: remarks),
      'Task approved.',
    );
  }

  Future<void> _return(Task task) async {
    final remarks = await showDialog<String>(
      context: context,
      builder: (_) => const _RemarksDialog(
        title: 'Return to intern',
        label: 'What needs to change?',
        confirmLabel: 'Return',
        required: true,
      ),
    );
    if (remarks == null) return;
    await _run(
      () => ref
          .read(taskRepositoryProvider)
          .returnTask(task.id, remarks: remarks),
      'Task returned to the intern.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(taskProvider(widget.taskId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          IconButton(
            tooltip: 'Edit task',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(AppRoutes.editTask(widget.taskId)),
          ),
        ],
      ),
      body: task.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorState(
          message: 'Could not load this task.',
          onRetry: () => ref.invalidate(taskProvider(widget.taskId)),
        ),
        data: (task) {
          if (task == null) {
            return const EmptyState(
              icon: Icons.search_off,
              message: 'This task no longer exists.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TaskInfo(task: task, submissionNoteTitle: 'Intern submission'),
              if (task.status == TaskStatus.submitted) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isBusy ? null : () => _approve(task),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : () => _return(task),
                  icon: const Icon(Icons.undo),
                  label: const Text('Return with remarks'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RemarksDialog extends StatefulWidget {
  const _RemarksDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.required,
  });

  final String title;
  final String label;
  final String confirmLabel;
  final bool required;

  @override
  State<_RemarksDialog> createState() => _RemarksDialogState();
}

class _RemarksDialogState extends State<_RemarksDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final text = _controller.text.trim();
    if (widget.required && text.isEmpty) {
      setState(() => _error = 'Remarks are required');
      return;
    }
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: widget.label,
          errorText: _error,
          alignLabelWithHint: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _confirm, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
