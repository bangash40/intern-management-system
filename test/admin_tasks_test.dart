import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/core/constants/enums.dart';
import 'package:intern_management_system/features/auth/providers/auth_providers.dart';
import 'package:intern_management_system/features/interns/data/intern_repository.dart';
import 'package:intern_management_system/features/interns/models/app_user.dart';
import 'package:intern_management_system/features/interns/providers/intern_providers.dart';
import 'package:intern_management_system/features/tasks/data/task_repository.dart';
import 'package:intern_management_system/features/tasks/models/task.dart';
import 'package:intern_management_system/features/tasks/presentation/all_tasks_screen.dart';
import 'package:intern_management_system/features/tasks/presentation/task_form_screen.dart';
import 'package:intern_management_system/features/tasks/providers/task_providers.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late TaskRepository tasks;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    tasks = TaskRepository(firestore: firestore);
  });

  Future<void> addIntern(String uid, String name, {bool isActive = true}) =>
      firestore.collection('users').doc(uid).set({
        'name': name,
        'email': '${name.toLowerCase()}@example.com',
        'role': 'intern',
        'isActive': isActive,
      });

  Task sample(String title, {String to = 'u1', TaskStatus? status}) => Task(
    id: '',
    title: title,
    description: 'desc',
    assignedTo: to,
    assignedToName: 'Ali',
    assignedBy: 'admin1',
    priority: TaskPriority.medium,
    status: status ?? TaskStatus.todo,
    dueDate: DateTime(2099, 1, 1),
  );

  const admin = AppUser(
    uid: 'admin1',
    name: 'Boss',
    email: 'boss@example.com',
    role: UserRole.admin,
    isActive: true,
  );

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(tasks),
          internRepositoryProvider.overrideWithValue(
            InternRepository(firestore: firestore),
          ),
          sessionProvider.overrideWith((ref) async => admin),
        ],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AllTasksScreen', () {
    testWidgets('shows an empty state', (tester) async {
      await pump(tester, const AllTasksScreen());
      expect(find.textContaining('No tasks yet'), findsOneWidget);
    });

    testWidgets('lists every task with its assignee and filters', (
      tester,
    ) async {
      await tasks.createTask(sample('First'));
      await tasks.createTask(sample('Second', status: TaskStatus.submitted));
      await pump(tester, const AllTasksScreen());

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Ali'), findsNWidgets(2));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Submitted'));
      await tester.pumpAndSettle();
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
    });
  });

  group('TaskFormScreen', () {
    Future<void> fillAndPickDate(
      WidgetTester tester, {
      required String title,
    }) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        title,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Write the code',
      );
      await tester.tap(find.text('Select a date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    testWidgets('asks to add an intern first when there are none', (
      tester,
    ) async {
      await pump(tester, const TaskFormScreen());
      expect(find.textContaining('Add an intern first'), findsOneWidget);
    });

    testWidgets('validates required fields', (tester) async {
      await addIntern('u1', 'Ali');
      await pump(tester, const TaskFormScreen());

      await tester.tap(find.text('Create task'));
      await tester.pump();

      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Description is required'), findsOneWidget);
      expect(find.text('Select an intern'), findsOneWidget);
      expect(find.text('Select a due date'), findsOneWidget);
      expect((await firestore.collection('tasks').get()).docs, isEmpty);
    });

    testWidgets('creates a task for the chosen intern', (tester) async {
      await addIntern('u1', 'Ali');
      await addIntern('u2', 'Gone', isActive: false);
      await pump(tester, const TaskFormScreen());

      await fillAndPickDate(tester, title: 'Build login');
      await tester.tap(find.text('Assign to'));
      await tester.pumpAndSettle();
      expect(find.text('Gone (inactive)'), findsNothing);
      await tester.tap(find.text('Ali').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create task'));
      await tester.pumpAndSettle();

      final saved = (await firestore.collection('tasks').get()).docs.single;
      expect(saved['title'], 'Build login');
      expect(saved['assignedTo'], 'u1');
      expect(saved['assignedToName'], 'Ali');
      expect(saved['assignedBy'], 'admin1');
      expect(saved['status'], 'todo');
    });

    testWidgets('edits an existing task', (tester) async {
      await addIntern('u1', 'Ali');
      final id = await tasks.createTask(sample('Old title'));
      await pump(tester, TaskFormScreen(taskId: id));

      expect(find.text('Old title'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'New title',
      );
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      final updated = (await tasks.getTask(id))!;
      expect(updated.title, 'New title');
      expect(updated.status, TaskStatus.todo);
    });

    testWidgets('deletes a task after confirming', (tester) async {
      await addIntern('u1', 'Ali');
      final id = await tasks.createTask(sample('Doomed'));
      await pump(tester, TaskFormScreen(taskId: id));

      await tester.tap(find.byTooltip('Delete task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await tasks.getTask(id), isNotNull);

      await tester.tap(find.byTooltip('Delete task'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(await tasks.getTask(id), isNull);
    });
  });
}
