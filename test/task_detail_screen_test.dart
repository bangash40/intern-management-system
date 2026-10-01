import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/core/constants/enums.dart';
import 'package:intern_management_system/features/tasks/data/task_repository.dart';
import 'package:intern_management_system/features/tasks/models/task.dart';
import 'package:intern_management_system/features/tasks/presentation/task_detail_screen.dart';
import 'package:intern_management_system/features/tasks/providers/task_providers.dart';

Task task({
  TaskStatus status = TaskStatus.todo,
  String adminRemarks = '',
  String submissionNote = '',
}) => Task(
  id: '',
  title: 'Build login screen',
  description: 'Use Material 3',
  assignedTo: 'u1',
  assignedToName: 'Ali',
  assignedBy: 'admin1',
  priority: TaskPriority.high,
  status: status,
  dueDate: DateTime(2099, 1, 1),
  adminRemarks: adminRemarks,
  submissionNote: submissionNote,
);

void main() {
  late TaskRepository repo;

  setUp(() => repo = TaskRepository(firestore: FakeFirebaseFirestore()));

  Future<String> pumpDetail(WidgetTester tester, Task t) async {
    final id = await repo.createTask(t);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [taskRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: TaskDetailScreen(taskId: id)),
      ),
    );
    await tester.pumpAndSettle();
    return id;
  }

  testWidgets('shows the task details', (tester) async {
    await pumpDetail(tester, task());

    expect(find.text('Build login screen'), findsOneWidget);
    expect(find.text('Use Material 3'), findsOneWidget);
    expect(find.text('High priority'), findsOneWidget);
    expect(find.text('01 Jan 2099'), findsOneWidget);
    expect(find.text('To Do'), findsOneWidget);
  });

  testWidgets('a to-do task can be started', (tester) async {
    final id = await pumpDetail(tester, task());

    await tester.tap(find.text('Start task'));
    await tester.pumpAndSettle();

    expect((await repo.getTask(id))!.status, TaskStatus.inProgress);
    expect(find.text('Submit for review'), findsOneWidget);
  });

  testWidgets('an in-progress task is submitted with a note', (tester) async {
    final id = await pumpDetail(tester, task(status: TaskStatus.inProgress));

    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'github.com/me/pr/1');
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();

    final saved = (await repo.getTask(id))!;
    expect(saved.status, TaskStatus.submitted);
    expect(saved.submissionNote, 'github.com/me/pr/1');
    expect(find.textContaining('Waiting for the admin'), findsOneWidget);
  });

  testWidgets('cancelling the submit dialog changes nothing', (tester) async {
    final id = await pumpDetail(tester, task(status: TaskStatus.inProgress));

    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect((await repo.getTask(id))!.status, TaskStatus.inProgress);
  });

  testWidgets('admin remarks are shown after a task is returned', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      task(status: TaskStatus.inProgress, adminRemarks: 'Fix the layout'),
    );

    expect(find.text('Admin remarks'), findsOneWidget);
    expect(find.text('Fix the layout'), findsOneWidget);
  });

  testWidgets('submitted and completed tasks have no action button', (
    tester,
  ) async {
    await pumpDetail(tester, task(status: TaskStatus.submitted));
    expect(find.byType(FilledButton), findsNothing);
    expect(find.textContaining('Waiting for the admin'), findsOneWidget);
  });

  testWidgets('a completed task is read-only', (tester) async {
    await pumpDetail(tester, task(status: TaskStatus.completed));
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('This task is completed.'), findsOneWidget);
  });

  testWidgets('shows a message when the task was deleted', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [taskRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: TaskDetailScreen(taskId: 'missing')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This task no longer exists.'), findsOneWidget);
  });
}
