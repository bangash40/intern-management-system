import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/core/constants/enums.dart';
import 'package:intern_management_system/features/auth/providers/auth_providers.dart';
import 'package:intern_management_system/features/dashboard/presentation/intern_dashboard_screen.dart';
import 'package:intern_management_system/features/interns/models/app_user.dart';
import 'package:intern_management_system/features/interns/presentation/my_profile_screen.dart';
import 'package:intern_management_system/features/tasks/data/task_repository.dart';
import 'package:intern_management_system/features/tasks/models/task.dart';
import 'package:intern_management_system/features/tasks/providers/task_providers.dart';

void main() {
  late TaskRepository tasks;

  final intern = AppUser(
    uid: 'u1',
    name: 'Ali Khan',
    email: 'ali@example.com',
    role: UserRole.intern,
    isActive: true,
    phone: '03001234567',
    department: 'Flutter',
    mentor: 'Bilal',
    startDate: DateTime(2026, 1, 5),
    endDate: DateTime(2026, 4, 5),
  );

  setUp(() => tasks = TaskRepository(firestore: FakeFirebaseFirestore()));

  Future<void> addTask(String title, TaskStatus status, DateTime due) =>
      tasks.createTask(
        Task(
          id: '',
          title: title,
          description: 'd',
          assignedTo: 'u1',
          assignedToName: 'Ali Khan',
          assignedBy: 'admin',
          priority: TaskPriority.medium,
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
          taskRepositoryProvider.overrideWithValue(tasks),
          sessionProvider.overrideWith((ref) async => intern),
        ],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('InternDashboardScreen', () {
    testWidgets('greets the intern and handles having no tasks', (
      tester,
    ) async {
      await pump(tester, const InternDashboardScreen());

      expect(find.text('Hi, Ali Khan'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('No tasks assigned to you yet.'), findsOneWidget);
    });

    testWidgets('shows counts, completion and overdue tasks', (tester) async {
      await addTask('Done', TaskStatus.completed, DateTime(2099, 1, 1));
      await addTask('Working', TaskStatus.inProgress, DateTime(2099, 2, 1));
      await addTask('Late', TaskStatus.todo, DateTime(2020, 1, 1));
      await addTask('Waiting', TaskStatus.submitted, DateTime(2099, 3, 1));
      await pump(tester, const InternDashboardScreen());

      expect(find.text('25%'), findsOneWidget);
      expect(find.text('1 overdue'), findsOneWidget);
      expect(find.text('4'), findsOneWidget); // total
      expect(find.text('3'), findsOneWidget); // pending
    });

    testWidgets('upcoming deadlines list the 3 soonest open tasks', (
      tester,
    ) async {
      await addTask('Finished', TaskStatus.completed, DateTime(2098, 1, 1));
      await addTask('First', TaskStatus.todo, DateTime(2099, 1, 1));
      await addTask('Second', TaskStatus.todo, DateTime(2099, 2, 1));
      await addTask('Third', TaskStatus.todo, DateTime(2099, 3, 1));
      await addTask('Fourth', TaskStatus.todo, DateTime(2099, 4, 1));
      await pump(tester, const InternDashboardScreen());

      expect(find.text('Finished'), findsNothing);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
      expect(find.text('Fourth'), findsNothing);
    });

    testWidgets('says so when everything is completed', (tester) async {
      await addTask('Done', TaskStatus.completed, DateTime(2099, 1, 1));
      await pump(tester, const InternDashboardScreen());

      expect(find.text('You are all caught up.'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('MyProfileScreen', () {
    testWidgets('shows the intern profile details', (tester) async {
      await pump(tester, const MyProfileScreen());

      expect(find.text('Ali Khan'), findsOneWidget);
      expect(find.text('ali@example.com'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Bilal'), findsOneWidget);
      expect(find.text('05 Jan 2026'), findsOneWidget);
      expect(find.text('05 Apr 2026'), findsOneWidget);
    });
  });
}
