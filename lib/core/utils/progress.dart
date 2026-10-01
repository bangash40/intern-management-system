import '../../features/tasks/models/task.dart';
import '../constants/enums.dart';

/// Task counts and completion rate for a set of tasks.
///
/// This is the single place where progress is calculated, so the intern and
/// admin dashboards always agree.
class ProgressStats {
  const ProgressStats({
    required this.total,
    required this.todo,
    required this.inProgress,
    required this.submitted,
    required this.completed,
    required this.overdue,
  });

  factory ProgressStats.fromTasks(Iterable<Task> tasks, {DateTime? now}) {
    final time = now ?? DateTime.now();
    var total = 0, todo = 0, inProgress = 0, submitted = 0;
    var completed = 0, overdue = 0;
    for (final task in tasks) {
      total++;
      switch (task.status) {
        case TaskStatus.todo:
          todo++;
        case TaskStatus.inProgress:
          inProgress++;
        case TaskStatus.submitted:
          submitted++;
        case TaskStatus.completed:
          completed++;
      }
      if (task.isOverdue(time)) overdue++;
    }
    return ProgressStats(
      total: total,
      todo: todo,
      inProgress: inProgress,
      submitted: submitted,
      completed: completed,
      overdue: overdue,
    );
  }

  final int total;
  final int todo;
  final int inProgress;
  final int submitted;
  final int completed;
  final int overdue;

  /// Tasks not finished yet (everything except completed).
  int get pending => total - completed;

  /// Completed tasks as a percentage of all tasks, 0 when there are none.
  double get completionRate => total == 0 ? 0 : completed / total * 100;
}
