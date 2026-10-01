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

/// Admin list of every task with a status filter.
class AllTasksScreen extends ConsumerStatefulWidget {
  const AllTasksScreen({super.key});

  @override
  ConsumerState<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends ConsumerState<AllTasksScreen> {
  TaskStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(allTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Tasks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addTask),
        icon: const Icon(Icons.add_task),
        label: const Text('Add task'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final status in <TaskStatus?>[null, ...TaskStatus.values])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(status?.label ?? 'All'),
                      selected: _filter == status,
                      onSelected: (_) => setState(() => _filter = status),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: tasks.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorState(
                message: 'Could not load tasks.',
                onRetry: () => ref.invalidate(allTasksProvider),
              ),
              data: (all) {
                final shown = _filter == null
                    ? all
                    : all.where((t) => t.status == _filter).toList();
                if (shown.isEmpty) {
                  return EmptyState(
                    icon: Icons.task_alt,
                    message: all.isEmpty
                        ? 'No tasks yet. Tap "Add task" to create one.'
                        : 'No ${_filter!.label.toLowerCase()} tasks.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: shown.length,
                  itemBuilder: (_, i) => TaskCard(
                    task: shown[i],
                    showAssignee: true,
                    onTap: () => context.push(AppRoutes.editTask(shown[i].id)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
