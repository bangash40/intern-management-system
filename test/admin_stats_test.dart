import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/core/constants/enums.dart';
import 'package:intern_management_system/core/utils/admin_stats.dart';
import 'package:intern_management_system/features/interns/models/app_user.dart';
import 'package:intern_management_system/features/tasks/models/task.dart';

AppUser intern(String uid, String name, {bool active = true}) => AppUser(
  uid: uid,
  name: name,
  email: '$name@example.com',
  role: UserRole.intern,
  isActive: active,
);

Task task(String to, TaskStatus status, DateTime due) => Task(
  id: '',
  title: 't',
  description: 'd',
  assignedTo: to,
  assignedToName: to,
  assignedBy: 'a',
  priority: TaskPriority.low,
  status: status,
  dueDate: due,
);

void main() {
  final now = DateTime(2026, 6, 1);
  final past = DateTime(2026, 5, 1);
  final future = DateTime(2026, 7, 1);

  test('empty data gives zeros', () {
    final stats = AdminStats.compute([], [], now: now);
    expect(stats.totalInterns, 0);
    expect(stats.overall.completionRate, 0);
    expect(stats.topByCompletion(), isEmpty);
    expect(stats.mostOverdue(), isEmpty);
  });

  test('counts interns, active interns and overall progress', () {
    final stats = AdminStats.compute(
      [intern('a', 'A'), intern('b', 'B', active: false)],
      [
        task('a', TaskStatus.completed, future),
        task('a', TaskStatus.todo, past),
        task('b', TaskStatus.submitted, future),
        task('b', TaskStatus.completed, future),
      ],
      now: now,
    );

    expect(stats.totalInterns, 2);
    expect(stats.activeInterns, 1);
    expect(stats.overall.total, 4);
    expect(stats.overall.completionRate, 50);
    expect(stats.overall.overdue, 1);
    expect(stats.awaitingReview, 1);
  });

  test(
    'top interns are ranked by completion rate, skipping those with no tasks',
    () {
      final stats = AdminStats.compute(
        [intern('a', 'A'), intern('b', 'B'), intern('c', 'C')],
        [
          task('a', TaskStatus.completed, future),
          task('a', TaskStatus.todo, future),
          task('b', TaskStatus.completed, future),
        ],
        now: now,
      );

      final top = stats.topByCompletion();
      expect(top.map((p) => p.intern.name), ['B', 'A']);
    },
  );

  test('ties on rate are broken by completed count', () {
    final stats = AdminStats.compute(
      [intern('a', 'A'), intern('b', 'B')],
      [
        task('a', TaskStatus.completed, future),
        task('b', TaskStatus.completed, future),
        task('b', TaskStatus.completed, future),
      ],
      now: now,
    );
    expect(stats.topByCompletion().map((p) => p.intern.name), ['B', 'A']);
  });

  test('most overdue lists only interns with overdue tasks, worst first', () {
    final stats = AdminStats.compute(
      [intern('a', 'A'), intern('b', 'B'), intern('c', 'C')],
      [
        task('a', TaskStatus.todo, past),
        task('b', TaskStatus.todo, past),
        task('b', TaskStatus.inProgress, past),
        task('c', TaskStatus.completed, past),
      ],
      now: now,
    );

    expect(stats.mostOverdue().map((p) => p.intern.name), ['B', 'A']);
  });

  test('the lists are capped', () {
    final interns = [for (var i = 0; i < 5; i++) intern('$i', 'I$i')];
    final tasks = [
      for (var i = 0; i < 5; i++) task('$i', TaskStatus.todo, past),
    ];
    final stats = AdminStats.compute(interns, tasks, now: now);
    expect(stats.mostOverdue().length, 3);
    expect(stats.mostOverdue(2).length, 2);
  });
}
