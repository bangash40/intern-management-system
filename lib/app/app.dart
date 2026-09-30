import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';
import 'theme_mode_provider.dart';

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
      home: const _ShellPlaceholder(),
    );
  }
}

class _ShellPlaceholder extends ConsumerWidget {
  const _ShellPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      appBar: AppBar(
        title: const Text('IMS'),
        actions: [
          IconButton(
            tooltip: 'Toggle light / dark mode',
            icon: Icon(
              brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggle(brightness),
          ),
        ],
      ),
      body: const Center(child: Text('Intern Management System')),
    );
  }
}
