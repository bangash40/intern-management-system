import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_mode_provider.dart';

/// App bar button that switches between light and dark mode.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    return IconButton(
      tooltip: 'Toggle light / dark mode',
      icon: Icon(
        brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
      ),
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(brightness),
    );
  }
}
