import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/core/constants/enums.dart';
import 'package:intern_management_system/features/tasks/data/task_repository.dart';
import 'package:intern_management_system/features/tasks/models/task.dart';
import 'package:intern_management_system/features/tasks/presentation/admin_task_detail_screen.dart';
import 'package:intern_management_system/features/tasks/providers/task_providers.dart';

void main() {
  late TaskRepository repo;

  setUp(() => repo = TaskRepository(firestore: FakeFirebaseFirestore()));

  Future<String> pump(WidgetTester tester, TaskStatus status) async {
    final id = await repo.createTask(
      Task(
        id: '',
        title: 'Build login',
        description: 'Use Material 3',
        assignedTo: 'u1',
        assignedToName: 'Ali',
        assignedBy: 'admin1',
        priority: TaskPriority.high,
        status: status,
        dueDate: DateTime(2099, 1, 1),
        submissionNote: 'github.com/pr/1',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [taskRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: AdminTaskDetailScreen(taskId: id)),
      ),
    );
    await tester.pumpAndSettle();
    return id;
  }

  testWidgets('shows the task, assignee and intern submission', (tester) async {
    await pump(tester, TaskStatus.submitted);

    expect(find.text('Build login'), findsOneWidget);
    expect(find.text('Ali'), findsOneWidget);
    expect(find.text('Intern submission'), findsOneWidget);
    expect(find.text('github.com/pr/1'), findsOneWidget);
  });

  testWidgets('review buttons only appear for submitted tasks', (tester) async {
    await pump(tester, TaskStatus.inProgress);
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Return with remarks'), findsNothing);
  });

  testWidgets('approving completes the task', (tester) async {
    final id = await pump(tester, TaskStatus.submitted);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Nice work');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Approve'),
      ),
    );
    await tester.pumpAndSettle();

    final task = (await repo.getTask(id))!;
    expect(task.status, TaskStatus.completed);
    expect(task.adminRemarks, 'Nice work');
    expect(task.completedAt, isNotNull);
    expect(find.text('Approve'), findsNothing);
  });

  testWidgets('returning needs remarks, then sends it back', (tester) async {
    final id = await pump(tester, TaskStatus.submitted);

    await tester.tap(find.text('Return with remarks'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Return'));
    await tester.pumpAndSettle();
    expect(find.text('Remarks are required'), findsOneWidget);
    expect((await repo.getTask(id))!.status, TaskStatus.submitted);

    await tester.enterText(find.byType(TextField), 'Fix the layout');
    await tester.tap(find.widgetWithText(FilledButton, 'Return'));
    await tester.pumpAndSettle();

    final task = (await repo.getTask(id))!;
    expect(task.status, TaskStatus.inProgress);
    expect(task.adminRemarks, 'Fix the layout');
  });

  testWidgets('cancelling a review changes nothing', (tester) async {
    final id = await pump(tester, TaskStatus.submitted);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect((await repo.getTask(id))!.status, TaskStatus.submitted);
  });
}
