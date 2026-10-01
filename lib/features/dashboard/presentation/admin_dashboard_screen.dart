import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/utils/admin_stats.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/auth_providers.dart';
import '../../interns/providers/intern_providers.dart';
import '../../tasks/providers/task_providers.dart';
import 'widgets/status_pie_chart.dart';

/// The admin's home screen: program-wide progress at a glance.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(sessionProvider).value?.name ?? '';
    final interns = ref.watch(internsProvider);
    final tasks = ref.watch(allTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: switch ((interns, tasks)) {
        (AsyncData(value: final i), AsyncData(value: final t)) => _Content(
          name: name,
          stats: AdminStats.compute(i, t),
        ),
        (AsyncError(), _) || (_, AsyncError()) => ErrorState(
          message: 'Could not load the dashboard.',
          onRetry: () {
            ref.invalidate(internsProvider);
            ref.invalidate(allTasksProvider);
          },
        ),
        _ => const LoadingIndicator(),
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.name, required this.stats});

  final String name;
  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final overall = stats.overall;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Hi, $name', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatCard(
              label: 'Interns',
              value: '${stats.totalInterns}',
              caption: '${stats.activeInterns} active',
            ),
            _StatCard(
              label: 'Tasks',
              value: '${overall.total}',
              caption: '${overall.completed} done',
            ),
          ],
        ),
        Row(
          children: [
            _StatCard(
              label: 'Completion',
              value: '${overall.completionRate.round()}%',
            ),
            _StatCard(
              label: 'Overdue',
              value: '${overall.overdue}',
              valueColor: overall.overdue > 0 ? scheme.error : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => context.push(AppRoutes.interns),
                icon: const Icon(Icons.people_outline),
                label: const Text('Interns'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => context.push(AppRoutes.allTasks),
                icon: const Icon(Icons.checklist),
                label: const Text('All Tasks'),
              ),
            ),
          ],
        ),
        if (stats.awaitingReview > 0) ...[
          const SizedBox(height: 16),
          Card(
            color: scheme.tertiaryContainer,
            child: ListTile(
              leading: Icon(
                Icons.rate_review_outlined,
                color: scheme.onTertiaryContainer,
              ),
              title: Text(
                '${stats.awaitingReview} '
                '${stats.awaitingReview == 1 ? 'task is' : 'tasks are'} '
                'waiting for review',
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.reviewQueue),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text('Tasks by status', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        StatusPieChart(stats: overall),
        const SizedBox(height: 24),
        _RankingSection(
          title: 'Top interns',
          emptyText: 'No tasks to rank yet.',
          rows: [
            for (final p in stats.topByCompletion())
              _RankRow(
                intern: p,
                trailing:
                    '${p.stats.completionRate.round()}% '
                    '(${p.stats.completed}/${p.stats.total})',
              ),
          ],
        ),
        const SizedBox(height: 24),
        _RankingSection(
          title: 'Most overdue tasks',
          emptyText: 'No overdue tasks. Great!',
          rows: [
            for (final p in stats.mostOverdue())
              _RankRow(intern: p, trailing: '${p.stats.overdue} overdue'),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.caption,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? caption;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: valueColor,
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankRow {
  const _RankRow({required this.intern, required this.trailing});

  final InternPerformance intern;
  final String trailing;
}

class _RankingSection extends StatelessWidget {
  const _RankingSection({
    required this.title,
    required this.emptyText,
    required this.rows,
  });

  final String title;
  final String emptyText;
  final List<_RankRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Text(
            emptyText,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          Card(
            child: Column(
              children: [
                for (final row in rows)
                  ListTile(
                    title: Text(row.intern.intern.name),
                    trailing: Text(row.trailing),
                    onTap: () => context.push(
                      AppRoutes.internDetail(row.intern.intern.uid),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
