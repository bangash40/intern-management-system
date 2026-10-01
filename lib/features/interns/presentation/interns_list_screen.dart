import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../models/app_user.dart';
import '../providers/intern_providers.dart';

enum _ActiveFilter { all, active, inactive }

/// Admin list of interns with search and an active/inactive filter.
class InternsListScreen extends ConsumerStatefulWidget {
  const InternsListScreen({super.key});

  @override
  ConsumerState<InternsListScreen> createState() => _InternsListScreenState();
}

class _InternsListScreenState extends ConsumerState<InternsListScreen> {
  String _query = '';
  _ActiveFilter _filter = _ActiveFilter.all;

  List<AppUser> _apply(List<AppUser> interns) {
    final query = _query.trim().toLowerCase();
    return interns.where((u) {
      final matchesQuery =
          query.isEmpty ||
          u.name.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        _ActiveFilter.all => true,
        _ActiveFilter.active => u.isActive,
        _ActiveFilter.inactive => !u.isActive,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final interns = ref.watch(internsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Interns')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addIntern),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add intern'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final (filter, label) in [
                  (_ActiveFilter.all, 'All'),
                  (_ActiveFilter.active, 'Active'),
                  (_ActiveFilter.inactive, 'Inactive'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: interns.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorState(
                message: 'Could not load interns.',
                onRetry: () => ref.invalidate(internsProvider),
              ),
              data: (all) {
                final shown = _apply(all);
                if (shown.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline,
                    message: all.isEmpty
                        ? 'No interns yet. Tap "Add intern" to create one.'
                        : 'No interns match your search.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: shown.length,
                  itemBuilder: (_, i) => _InternTile(intern: shown[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InternTile extends StatelessWidget {
  const _InternTile({required this.intern});

  final AppUser intern;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = intern.name.isEmpty ? '?' : intern.name[0].toUpperCase();
    return ListTile(
      onTap: () => context.push(AppRoutes.internDetail(intern.uid)),
      leading: CircleAvatar(
        backgroundColor: intern.isActive
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        child: Text(initial),
      ),
      title: Text(intern.name),
      subtitle: Text(
        [
          intern.email,
          if (intern.department.isNotEmpty) intern.department,
        ].join(' · '),
      ),
      trailing: intern.isActive
          ? null
          : Text('Inactive', style: TextStyle(color: scheme.error)),
    );
  }
}
