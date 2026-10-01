import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/loading_indicator.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_providers.dart';
import 'theme.dart';
import 'theme_mode_provider.dart';
import 'theme_toggle_button.dart';

class InternManagementApp extends ConsumerWidget {
  const InternManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Intern Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      home: const _AuthGate(),
    );
  }
}

/// Temporary entry point: login when signed out, a placeholder when signed in.
/// Role-based routing replaces this.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (e, _) => const LoginScreen(),
      data: (user) =>
          user == null ? const LoginScreen() : _SignedInPlaceholder(user.email),
    );
  }
}

class _SignedInPlaceholder extends ConsumerWidget {
  const _SignedInPlaceholder(this.email);

  final String? email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IMS'),
        actions: const [ThemeToggleButton()],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Signed in as ${email ?? 'unknown'}'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
