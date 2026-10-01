import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/core/constants/enums.dart';
import 'package:intern_management_system/core/utils/progress.dart';
import 'package:intern_management_system/features/tasks/models/task.dart';

Task task(TaskStatus status, DateTime due) => Task(
  id: '',
  title: 't',
  description: 'd',
  assignedTo: 'u1',
  assignedToName: 'Ali',
  assignedBy: 'a',
  priority: TaskPriority.low,
  status: status,
  dueDate: due,
);

void main() {
  final now = DateTime(2026, 6, 1);
  final past = DateTime(2026, 5, 1);
  final future = DateTime(2026, 7, 1);

  test('no tasks gives zeros and a 0% rate', () {
    final stats = ProgressStats.fromTasks([], now: now);
    expect(stats.total, 0);
    expect(stats.completionRate, 0);
    expect(stats.overdue, 0);
  });

  test('counts each status and the completion rate', () {
    final stats = ProgressStats.fromTasks([
      task(TaskStatus.todo, future),
      task(TaskStatus.inProgress, future),
      task(TaskStatus.submitted, future),
      task(TaskStatus.completed, future),
    ], now: now);

    expect(stats.total, 4);
    expect(stats.todo, 1);
    expect(stats.inProgress, 1);
    expect(stats.submitted, 1);
    expect(stats.completed, 1);
    expect(stats.pending, 3);
    expect(stats.completionRate, 25);
  });

  test('overdue means past due and not completed', () {
    final stats = ProgressStats.fromTasks([
      task(TaskStatus.todo, past),
      task(TaskStatus.submitted, past),
      task(TaskStatus.completed, past),
      task(TaskStatus.todo, future),
    ], now: now);

    expect(stats.overdue, 2);
  });

  test('all completed is 100%', () {
    final stats = ProgressStats.fromTasks([
      task(TaskStatus.completed, past),
      task(TaskStatus.completed, future),
    ], now: now);
    expect(stats.completionRate, 100);
  });
}
