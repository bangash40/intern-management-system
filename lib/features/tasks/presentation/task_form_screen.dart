import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/providers/auth_providers.dart';
import '../../interns/models/app_user.dart';
import '../../interns/providers/intern_providers.dart';
import '../models/task.dart';
import '../providers/task_providers.dart';

/// Admin form to create a task, or edit one when [taskId] is given.
class TaskFormScreen extends ConsumerWidget {
  const TaskFormScreen({super.key, this.taskId});

  final String? taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = taskId;
    if (id == null) return const _TaskForm();

    final task = ref.watch(taskProvider(id));
    return task.when(
      loading: () => Scaffold(appBar: AppBar(), body: const LoadingIndicator()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(message: 'Could not load this task.'),
      ),
      data: (task) => task == null
          ? Scaffold(
              appBar: AppBar(),
              body: const EmptyState(
                icon: Icons.search_off,
                message: 'This task no longer exists.',
              ),
            )
          : _TaskForm(initial: task),
    );
  }
}

class _TaskForm extends ConsumerStatefulWidget {
  const _TaskForm({this.initial});

  final Task? initial;

  @override
  ConsumerState<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(
    text: widget.initial?.title,
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.initial?.description,
  );

  late String? _assigneeId = widget.initial?.assignedTo;
  late TaskPriority _priority = widget.initial?.priority ?? TaskPriority.medium;
  late DateTime? _dueDate = widget.initial?.dueDate;

  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.initial != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save(List<AppUser> interns) async {
    if (!_formKey.currentState!.validate()) return;
    final assignee = interns.firstWhere((u) => u.uid == _assigneeId);
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(taskRepositoryProvider);
      final admin = await ref.read(sessionProvider.future);
      final initial = widget.initial;
      final task = Task(
        id: initial?.id ?? '',
        title: _title.text,
        description: _description.text,
        assignedTo: assignee.uid,
        assignedToName: assignee.name,
        assignedBy: initial?.assignedBy ?? admin?.uid ?? '',
        priority: _priority,
        status: initial?.status ?? TaskStatus.todo,
        dueDate: _dueDate!,
      );
      if (initial == null) {
        await repo.createTask(task);
      } else {
        await repo.updateTask(task);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Task updated.' : 'Task created.')),
      );
      Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not save the task. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(taskRepositoryProvider).deleteTask(widget.initial!.id);
      if (mounted) Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the task.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final interns = ref.watch(internsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit task' : 'Add task'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete task',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: interns.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorState(
          message: 'Could not load interns.',
          onRetry: () => ref.invalidate(internsProvider),
        ),
        data: (all) {
          // Only active interns can be picked, but keep the current assignee
          // visible when editing, even if they were deactivated since.
          final choices = all
              .where((u) => u.isActive || u.uid == widget.initial?.assignedTo)
              .toList();
          if (choices.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              message: 'Add an intern first, then you can assign tasks.',
            );
          }
          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _title,
                    maxLength: AppConstants.taskTitleMaxLength,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: Validators.taskTitle,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes),
                    ),
                    validator: (v) => Validators.required(v, 'Description'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _assigneeId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Assign to',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      for (final u in choices)
                        DropdownMenuItem(
                          value: u.uid,
                          child: Text(
                            u.isActive ? u.name : '${u.name} (inactive)',
                          ),
                        ),
                    ],
                    onChanged: (v) => _assigneeId = v,
                    validator: (v) => v == null ? 'Select an intern' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TaskPriority>(
                    initialValue: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: [
                      for (final p in TaskPriority.values)
                        DropdownMenuItem(value: p, child: Text(p.label)),
                    ],
                    onChanged: (v) => _priority = v ?? _priority,
                  ),
                  const SizedBox(height: 16),
                  DateField(
                    label: 'Due date',
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialValue: _dueDate,
                    onChanged: (d) => _dueDate = d,
                    validator: (v) => v == null ? 'Select a due date' : null,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _isEditing ? 'Save changes' : 'Create task',
                    isLoading: _isSaving,
                    onPressed: () => _save(choices),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
