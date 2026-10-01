import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/core/constants/enums.dart';
import 'package:intern_management_system/features/auth/providers/auth_providers.dart';
import 'package:intern_management_system/features/dashboard/presentation/admin_dashboard_screen.dart';
import 'package:intern_management_system/features/interns/data/intern_repository.dart';
import 'package:intern_management_system/features/interns/models/app_user.dart';
import 'package:intern_management_system/features/interns/providers/intern_providers.dart';
import 'package:intern_management_system/features/tasks/data/task_repository.dart';
import 'package:intern_management_system/features/tasks/models/task.dart';
import 'package:intern_management_system/features/tasks/providers/task_providers.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late TaskRepository tasks;

  const admin = AppUser(
    uid: 'admin1',
    name: 'Boss',
    email: 'boss@example.com',
    role: UserRole.admin,
    isActive: true,
  );

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

  Future<void> addTask(String to, TaskStatus status, DateTime due) =>
      tasks.createTask(
        Task(
          id: '',
          title: 'Task for $to',
          description: 'd',
          assignedTo: to,
          assignedToName: to,
          assignedBy: 'admin1',
          priority: TaskPriority.low,
          status: status,
          dueDate: due,
        ),
      );

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3000);
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
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows zeros and empty states with no data', (tester) async {
    await pump(tester);

    expect(find.text('Hi, Boss'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.text('No tasks to rank yet.'), findsOneWidget);
    expect(find.text('No overdue tasks. Great!'), findsOneWidget);
    expect(find.textContaining('waiting for review'), findsNothing);
  });

  testWidgets('shows totals, completion and overdue counts', (tester) async {
    await addIntern('a', 'Ali');
    await addIntern('b', 'Sara', isActive: false);
    await addTask('a', TaskStatus.completed, DateTime(2099));
    await addTask('a', TaskStatus.todo, DateTime(2020));
    await addTask('b', TaskStatus.completed, DateTime(2099));
    await addTask('b', TaskStatus.inProgress, DateTime(2099));
    await pump(tester);

    expect(find.text('1 active'), findsOneWidget);
    expect(find.text('2 done'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);
    // Overdue: 1. Appears in the stat card and the ranking row.
    expect(find.text('1 overdue'), findsOneWidget);
  });

  testWidgets('ranks top interns and those with the most overdue', (
    tester,
  ) async {
    await addIntern('a', 'Ali');
    await addIntern('b', 'Sara');
    await addTask('a', TaskStatus.todo, DateTime(2020));
    await addTask('a', TaskStatus.todo, DateTime(2020));
    await addTask('b', TaskStatus.completed, DateTime(2099));
    await pump(tester);

    expect(find.text('100% (1/1)'), findsOneWidget);
    expect(find.text('2 overdue'), findsOneWidget);
  });

  testWidgets('flags tasks waiting for review', (tester) async {
    await addIntern('a', 'Ali');
    await addTask('a', TaskStatus.submitted, DateTime(2099));
    await pump(tester);

    expect(find.text('1 task is waiting for review'), findsOneWidget);
  });
}
