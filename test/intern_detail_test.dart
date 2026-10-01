import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/core/constants/enums.dart';
import 'package:intern_management_system/features/interns/data/intern_repository.dart';
import 'package:intern_management_system/features/interns/models/app_user.dart';
import 'package:intern_management_system/features/interns/presentation/intern_detail_screen.dart';
import 'package:intern_management_system/features/interns/presentation/intern_form_screen.dart';
import 'package:intern_management_system/features/interns/providers/intern_providers.dart';
import 'package:intern_management_system/features/tasks/data/task_repository.dart';
import 'package:intern_management_system/features/tasks/models/task.dart';
import 'package:intern_management_system/features/tasks/providers/task_providers.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late InternRepository interns;
  late TaskRepository tasks;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    interns = InternRepository(firestore: firestore);
    tasks = TaskRepository(firestore: firestore);
  });

  Future<void> addIntern({bool isActive = true}) =>
      firestore.collection('users').doc('u1').set({
        'name': 'Ali Khan',
        'email': 'ali@example.com',
        'role': 'intern',
        'isActive': isActive,
        'department': 'Flutter',
        'mentor': 'Bilal',
        'phone': '03001234567',
        'startDate': DateTime(2026, 1, 5),
        'endDate': DateTime(2026, 4, 5),
      });

  /// Reads the profile with a one-off get (streams need real async in
  /// widget tests).
  Future<AppUser> profile() async {
    final doc = await firestore.collection('users').doc('u1').get();
    return AppUser.fromMap({...doc.data()!, 'uid': doc.id});
  }

  Future<void> addTask(String title, TaskStatus status, DateTime due) =>
      tasks.createTask(
        Task(
          id: '',
          title: title,
          description: 'd',
          assignedTo: 'u1',
          assignedToName: 'Ali Khan',
          assignedBy: 'admin',
          priority: TaskPriority.low,
          status: status,
          dueDate: due,
        ),
      );

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          internRepositoryProvider.overrideWithValue(interns),
          taskRepositoryProvider.overrideWithValue(tasks),
        ],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('InternRepository', () {
    test('updateIntern changes profile fields but not the email', () async {
      await addIntern();
      final current = (await interns.watchIntern('u1').first)!;

      await interns.updateIntern(
        current.copyWith(name: ' Ali K ', department: 'Design'),
      );

      final updated = (await interns.watchIntern('u1').first)!;
      expect(updated.name, 'Ali K');
      expect(updated.department, 'Design');
      expect(updated.email, 'ali@example.com');
      expect(updated.updatedAt, isNotNull);
    });

    test('setActive deactivates and reactivates', () async {
      await addIntern();

      await interns.setActive('u1', isActive: false);
      expect((await interns.watchIntern('u1').first)!.isActive, isFalse);

      await interns.setActive('u1', isActive: true);
      expect((await interns.watchIntern('u1').first)!.isActive, isTrue);
    });

    test('watchIntern returns null for an unknown uid', () async {
      expect(await interns.watchIntern('nope').first, isNull);
    });
  });

  group('InternDetailScreen', () {
    testWidgets('shows profile, progress and tasks', (tester) async {
      await addIntern();
      await addTask('Done one', TaskStatus.completed, DateTime(2099));
      await addTask('Open one', TaskStatus.todo, DateTime(2020));
      await pump(tester, const InternDetailScreen(internId: 'u1'));

      expect(find.text('Ali Khan'), findsOneWidget);
      expect(find.text('ali@example.com'), findsOneWidget);
      expect(find.text('Mentor: Bilal'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('1 overdue'), findsOneWidget);
      expect(find.text('Done one'), findsOneWidget);
      expect(find.text('Open one'), findsOneWidget);
    });

    testWidgets('shows a message when the intern has no tasks', (tester) async {
      await addIntern();
      await pump(tester, const InternDetailScreen(internId: 'u1'));
      expect(find.textContaining('No tasks assigned'), findsOneWidget);
    });

    testWidgets('deactivating asks first, then marks them inactive', (
      tester,
    ) async {
      await addIntern();
      await pump(tester, const InternDetailScreen(internId: 'u1'));

      await tester.tap(find.byTooltip('Deactivate'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect((await profile()).isActive, isTrue);

      await tester.tap(find.byTooltip('Deactivate'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Deactivate'));
      await tester.pumpAndSettle();

      expect((await profile()).isActive, isFalse);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.byTooltip('Activate'), findsOneWidget);
    });

    testWidgets('an inactive intern can be activated again', (tester) async {
      await addIntern(isActive: false);
      await pump(tester, const InternDetailScreen(internId: 'u1'));

      await tester.tap(find.byTooltip('Activate'));
      await tester.pumpAndSettle();

      expect((await profile()).isActive, isTrue);
    });
  });

  group('InternFormScreen (edit)', () {
    testWidgets('prefills the form, locks the email and saves changes', (
      tester,
    ) async {
      await addIntern();
      await pump(tester, const InternFormScreen(internId: 'u1'));

      expect(find.text('Ali Khan'), findsOneWidget);
      expect(find.text('Temporary password'), findsNothing);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Email'))
            .enabled,
        isFalse,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Department'),
        'Design',
      );
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      final saved = (await profile());
      expect(saved.department, 'Design');
      expect(saved.name, 'Ali Khan');
    });
  });
}
