import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import 'dashboard_placeholder.dart';

/// Placeholder until the admin dashboard is built.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardPlaceholder(
      title: 'Admin Dashboard',
      actions: [
        FilledButton.icon(
          onPressed: () => context.push(AppRoutes.interns),
          icon: const Icon(Icons.people_outline),
          label: const Text('Interns'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
