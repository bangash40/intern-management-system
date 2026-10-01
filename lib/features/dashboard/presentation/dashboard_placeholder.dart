import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme_toggle_button.dart';
import '../../auth/providers/auth_providers.dart';

/// Temporary dashboard body: greets the user and lets them sign out.
class DashboardPlaceholder extends ConsumerWidget {
  const DashboardPlaceholder({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(sessionProvider).value?.name ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: const [ThemeToggleButton()]),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome, $name'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
