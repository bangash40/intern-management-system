import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/enums.dart';
import '../../../core/utils/progress.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/auth_providers.dart';
import '../../tasks/models/task.dart';
import '../../tasks/presentation/widgets/task_card.dart';
import '../../tasks/providers/task_providers.dart';
import 'widgets/progress_summary.dart';

/// The intern's home screen: progress at a glance and upcoming deadlines.
class InternDashboardScreen extends ConsumerWidget {
  const InternDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(sessionProvider).value?.name ?? '';
    final tasks = ref.watch(myTasksProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'My profile',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(AppRoutes.myProfile),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: tasks.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorState(
          message: 'Could not load your tasks.',
          onRetry: () => ref.invalidate(myTasksProvider(null)),
        ),
        data: (list) => _Content(name: name, tasks: list),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.name, required this.tasks});

  final String name;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Tasks arrive sorted by due date, so the first open ones are the soonest.
    final upcoming = tasks
        .where((t) => t.status != TaskStatus.completed)
        .take(3)
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Hi, $name', style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ProgressSummary(stats: ProgressStats.fromTasks(tasks)),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('Upcoming deadlines', style: theme.textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: () => context.push(AppRoutes.myTasks),
                child: const Text('View all tasks'),
              ),
            ],
          ),
        ),
        if (upcoming.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                tasks.isEmpty
                    ? 'No tasks assigned to you yet.'
                    : 'You are all caught up.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          for (final task in upcoming)
            TaskCard(
              task: task,
              onTap: () => context.push(AppRoutes.taskDetail(task.id)),
            ),
      ],
    );
  }
}
