import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/core/constants/enums.dart';
import 'package:intern_management_system/core/utils/date_utils.dart';
import 'package:intern_management_system/core/utils/validators.dart';
import 'package:intern_management_system/core/widgets/empty_state.dart';
import 'package:intern_management_system/core/widgets/error_state.dart';
import 'package:intern_management_system/core/widgets/primary_button.dart';

void main() {
  group('Validators', () {
    test('required', () {
      expect(Validators.required('  ', 'Name'), 'Name is required');
      expect(Validators.required('Ali'), isNull);
    });

    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('intern@example.com'), isNull);
    });

    test('password needs at least 6 characters', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('phone is optional but validated when given', () {
      expect(Validators.optionalPhone(''), isNull);
      expect(Validators.optionalPhone('abc'), isNotNull);
      expect(Validators.optionalPhone('+92 300 1234567'), isNull);
    });

    test('task title is required and capped at 100 characters', () {
      expect(Validators.taskTitle(''), isNotNull);
      expect(Validators.taskTitle('a' * 101), isNotNull);
      expect(Validators.taskTitle('a' * 100), isNull);
    });
  });

  group('Enums', () {
    test('TaskStatus round-trips through its stored value', () {
      for (final s in TaskStatus.values) {
        expect(TaskStatus.fromValue(s.value), s);
      }
      expect(TaskStatus.inProgress.value, 'in_progress');
    });

    test('unknown values fall back to a safe default', () {
      expect(UserRole.fromValue('hacker'), UserRole.intern);
      expect(TaskStatus.fromValue(null), TaskStatus.todo);
      expect(TaskPriority.fromValue('urgent'), TaskPriority.medium);
    });
  });

  test('date helpers', () {
    final d = DateTime(2026, 3, 5, 14, 30);
    expect(AppDateUtils.formatDate(d), '05 Mar 2026');
    expect(AppDateUtils.dateOnly(d), DateTime(2026, 3, 5));
  });

  group('Shared widgets', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('EmptyState shows its message', (tester) async {
      await tester.pumpWidget(wrap(const EmptyState(message: 'No tasks yet')));
      expect(find.text('No tasks yet'), findsOneWidget);
    });

    testWidgets('ErrorState retry callback fires', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        wrap(ErrorState(message: 'Oops', onRetry: () => retried = true)),
      );
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });

    testWidgets('PrimaryButton ignores taps while loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          PrimaryButton(label: 'Go', isLoading: true, onPressed: () => taps++),
        ),
      );
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
