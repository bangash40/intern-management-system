import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

import '../../../core/constants/enums.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/task_providers.dart';
import 'widgets/task_card.dart';

/// The intern's task list, filtered by status and sorted by due date.
class MyTasksScreen extends ConsumerStatefulWidget {
  const MyTasksScreen({super.key});

  @override
  ConsumerState<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends ConsumerState<MyTasksScreen> {
  TaskStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(myTasksProvider(_filter));

    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: Column(
        children: [
          _FilterBar(
            selected: _filter,
            onSelected: (status) => setState(() => _filter = status),
          ),
          Expanded(
            child: tasks.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorState(
                message: 'Could not load your tasks.',
                onRetry: () => ref.invalidate(myTasksProvider(_filter)),
              ),
              data: (list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.task_alt,
                      message: _filter == null
                          ? 'No tasks assigned to you yet.'
                          : 'No ${_filter!.label.toLowerCase()} tasks.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) => TaskCard(
                        task: list[i],
                        onTap: () =>
                            context.push(AppRoutes.taskDetail(list[i].id)),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final TaskStatus? selected;
  final ValueChanged<TaskStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _chip('All', selected == null, () => onSelected(null)),
          for (final status in TaskStatus.values)
            _chip(status.label, selected == status, () => onSelected(status)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool isSelected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    ),
  );
}
