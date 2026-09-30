import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/app/app.dart';

void main() {
  testWidgets('app starts with Material 3 theme', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: InternManagementApp()));

    expect(find.text('Intern Management System'), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.useMaterial3, isTrue);
    expect(app.darkTheme!.brightness, Brightness.dark);
  });

  testWidgets('toggle button switches between light and dark', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: InternManagementApp()));

    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.light,
    );
    await tester.tap(find.byIcon(Icons.dark_mode));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.byIcon(Icons.light_mode));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.light,
    );
  });
}
