import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/core/constants/enums.dart';
import 'package:intern_management_system/features/auth/providers/auth_providers.dart';
import 'package:intern_management_system/features/interns/models/app_user.dart';
import 'package:intern_management_system/features/tasks/data/task_repository.dart';
import 'package:intern_management_system/features/tasks/models/task.dart';
import 'package:intern_management_system/features/tasks/presentation/my_tasks_screen.dart';
import 'package:intern_management_system/features/tasks/providers/task_providers.dart';

Task task(
  String title, {
  String assignedTo = 'u1',
  TaskStatus status = TaskStatus.todo,
  DateTime? dueDate,
}) => Task(
  id: '',
  title: title,
  description: 'desc',
  assignedTo: assignedTo,
  assignedToName: 'Ali',
  assignedBy: 'admin1',
  priority: TaskPriority.medium,
  status: status,
  dueDate: dueDate ?? DateTime(2099, 1, 1),
);

void main() {
  late TaskRepository repo;

  setUp(() => repo = TaskRepository(firestore: FakeFirebaseFirestore()));

  Future<void> pumpScreen(WidgetTester tester) async {
    const intern = AppUser(
      uid: 'u1',
      name: 'Ali',
      email: 'ali@example.com',
      role: UserRole.intern,
      isActive: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(repo),
          sessionProvider.overrideWith((ref) async => intern),
        ],
        child: const MaterialApp(home: MyTasksScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows an empty state when there are no tasks', (tester) async {
    await pumpScreen(tester);
    expect(find.text('No tasks assigned to you yet.'), findsOneWidget);
  });

  testWidgets('lists only my tasks, soonest due date first', (tester) async {
    await repo.createTask(task('Later', dueDate: DateTime(2099, 5, 1)));
    await repo.createTask(task('Sooner', dueDate: DateTime(2099, 2, 1)));
    await repo.createTask(task('Not mine', assignedTo: 'u2'));

    await pumpScreen(tester);

    expect(find.text('Not mine'), findsNothing);
    final sooner = tester.getTopLeft(find.text('Sooner')).dy;
    final later = tester.getTopLeft(find.text('Later')).dy;
    expect(sooner, lessThan(later));
  });

  testWidgets('status chips filter the list', (tester) async {
    await repo.createTask(task('Fresh'));
    await repo.createTask(task('Busy', status: TaskStatus.inProgress));
    await pumpScreen(tester);

    expect(find.text('Fresh'), findsOneWidget);
    expect(find.text('Busy'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'In Progress'));
    await tester.pumpAndSettle();

    expect(find.text('Fresh'), findsNothing);
    expect(find.text('Busy'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
    await tester.pumpAndSettle();
    expect(find.text('No completed tasks.'), findsOneWidget);
  });

  testWidgets('overdue tasks are flagged', (tester) async {
    await repo.createTask(task('Late', dueDate: DateTime(2020, 1, 1)));
    await repo.createTask(
      task(
        'Late but done',
        dueDate: DateTime(2020, 1, 1),
        status: TaskStatus.completed,
      ),
    );
    await pumpScreen(tester);

    expect(find.text('Overdue'), findsOneWidget);
  });

  testWidgets('new tasks appear in real time', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Brand new'), findsNothing);

    await repo.createTask(task('Brand new'));
    await tester.pumpAndSettle();

    expect(find.text('Brand new'), findsOneWidget);
  });
}
