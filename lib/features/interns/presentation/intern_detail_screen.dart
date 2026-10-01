import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/progress.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../dashboard/presentation/widgets/progress_summary.dart';
import '../../tasks/presentation/widgets/task_card.dart';
import '../../tasks/providers/task_providers.dart';
import '../models/app_user.dart';
import '../providers/intern_providers.dart';

/// Admin view of one intern: profile, progress and their tasks.
class InternDetailScreen extends ConsumerWidget {
  const InternDetailScreen({super.key, required this.internId});

  final String internId;

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    AppUser intern,
  ) async {
    final deactivating = intern.isActive;
    if (deactivating) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Deactivate intern?'),
          content: Text(
            '${intern.name} will no longer be able to sign in. '
            'Their tasks and history are kept.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    try {
      await ref
          .read(internRepositoryProvider)
          .setActive(intern.uid, isActive: !deactivating);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update the intern.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intern = ref.watch(internProvider(internId));
    final value = intern.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intern'),
        actions: [
          if (value != null) ...[
            IconButton(
              tooltip: 'Edit intern',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(AppRoutes.editIntern(internId)),
            ),
            IconButton(
              tooltip: value.isActive ? 'Deactivate' : 'Activate',
              icon: Icon(
                value.isActive
                    ? Icons.person_off_outlined
                    : Icons.person_add_alt_outlined,
              ),
              onPressed: () => _toggleActive(context, ref, value),
            ),
          ],
        ],
      ),
      body: intern.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorState(
          message: 'Could not load this intern.',
          onRetry: () => ref.invalidate(internProvider(internId)),
        ),
        data: (intern) => intern == null
            ? const EmptyState(
                icon: Icons.search_off,
                message: 'This intern no longer exists.',
              )
            : _Body(intern: intern),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.intern});

  final AppUser intern;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasks = ref.watch(tasksOfInternProvider(intern.uid));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _Profile(intern: intern),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: tasks.when(
            loading: () =>
                const SizedBox(height: 80, child: LoadingIndicator()),
            error: (e, _) => const Text('Could not load progress.'),
            data: (list) =>
                ProgressSummary(stats: ProgressStats.fromTasks(list)),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Tasks', style: theme.textTheme.titleMedium),
        ),
        tasks.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
          data: (list) => list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: EmptyState(
                    icon: Icons.task_alt,
                    message: 'No tasks assigned to this intern yet.',
                  ),
                )
              : Column(
                  children: [
                    for (final task in list)
                      TaskCard(
                        task: task,
                        onTap: () => context.push(AppRoutes.adminTask(task.id)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Profile extends StatelessWidget {
  const _Profile({required this.intern});

  final AppUser intern;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(intern.name, style: theme.textTheme.headlineSmall),
            ),
            if (!intern.isActive)
              Text('Inactive', style: TextStyle(color: scheme.error)),
          ],
        ),
        const SizedBox(height: 12),
        _row(context, Icons.email_outlined, intern.email),
        if (intern.phone.isNotEmpty)
          _row(context, Icons.phone_outlined, intern.phone),
        if (intern.department.isNotEmpty)
          _row(context, Icons.work_outline, intern.department),
        if (intern.mentor.isNotEmpty)
          _row(
            context,
            Icons.supervisor_account_outlined,
            'Mentor: ${intern.mentor}',
          ),
        if (intern.startDate != null && intern.endDate != null)
          _row(
            context,
            Icons.event_outlined,
            '${AppDateUtils.formatDate(intern.startDate!)} - '
            '${AppDateUtils.formatDate(intern.endDate!)}',
          ),
      ],
    );
  }

  Widget _row(BuildContext context, IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
