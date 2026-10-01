import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../auth/providers/auth_providers.dart';

/// The signed-in intern's own profile (read-only).
class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final user = session.value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: user == null
          ? const LoadingIndicator()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(user.name, style: theme.textTheme.headlineSmall),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      _tile(Icons.email_outlined, 'Email', user.email),
                      if (user.phone.isNotEmpty)
                        _tile(Icons.phone_outlined, 'Phone', user.phone),
                      if (user.department.isNotEmpty)
                        _tile(
                          Icons.work_outline,
                          'Department',
                          user.department,
                        ),
                      if (user.mentor.isNotEmpty)
                        _tile(
                          Icons.supervisor_account_outlined,
                          'Mentor',
                          user.mentor,
                        ),
                      if (user.startDate != null)
                        _tile(
                          Icons.event_outlined,
                          'Internship starts',
                          AppDateUtils.formatDate(user.startDate!),
                        ),
                      if (user.endDate != null)
                        _tile(
                          Icons.event_available_outlined,
                          'Internship ends',
                          AppDateUtils.formatDate(user.endDate!),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _tile(IconData icon, String label, String value) =>
      ListTile(leading: Icon(icon), title: Text(label), subtitle: Text(value));
}
