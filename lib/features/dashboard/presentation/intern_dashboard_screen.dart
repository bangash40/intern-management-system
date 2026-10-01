import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import 'dashboard_placeholder.dart';

/// Placeholder until the intern dashboard is built.
class InternDashboardScreen extends StatelessWidget {
  const InternDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardPlaceholder(
      title: 'Intern Dashboard',
      actions: [
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.myTasks),
          icon: const Icon(Icons.checklist),
          label: const Text('My Tasks'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
