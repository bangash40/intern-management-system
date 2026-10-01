import '../../features/interns/models/app_user.dart';
import '../../features/tasks/models/task.dart';
import 'progress.dart';

/// One intern's progress, for the admin's ranking lists.
class InternPerformance {
  const InternPerformance({required this.intern, required this.stats});

  final AppUser intern;
  final ProgressStats stats;
}

/// Numbers for the admin dashboard, calculated from the live lists.
class AdminStats {
  const AdminStats({
    required this.totalInterns,
    required this.activeInterns,
    required this.overall,
    required this.perIntern,
  });

  factory AdminStats.compute(
    List<AppUser> interns,
    List<Task> tasks, {
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    final byIntern = <String, List<Task>>{};
    for (final task in tasks) {
      byIntern.putIfAbsent(task.assignedTo, () => []).add(task);
    }
    return AdminStats(
      totalInterns: interns.length,
      activeInterns: interns.where((u) => u.isActive).length,
      overall: ProgressStats.fromTasks(tasks, now: time),
      perIntern: [
        for (final intern in interns)
          InternPerformance(
            intern: intern,
            stats: ProgressStats.fromTasks(
              byIntern[intern.uid] ?? const [],
              now: time,
            ),
          ),
      ],
    );
  }

  final int totalInterns;
  final int activeInterns;
  final ProgressStats overall;
  final List<InternPerformance> perIntern;

  /// Tasks waiting for an admin decision.
  int get awaitingReview => overall.submitted;

  /// Interns with the best completion rate. Interns without tasks are left
  /// out, and ties are broken by the number of completed tasks.
  List<InternPerformance> topByCompletion([int count = 3]) {
    final ranked = perIntern.where((p) => p.stats.total > 0).toList()
      ..sort((a, b) {
        final byRate = b.stats.completionRate.compareTo(a.stats.completionRate);
        return byRate != 0
            ? byRate
            : b.stats.completed.compareTo(a.stats.completed);
      });
    return ranked.take(count).toList();
  }

  /// Interns with the most overdue tasks (only those with at least one).
  List<InternPerformance> mostOverdue([int count = 3]) {
    final ranked = perIntern.where((p) => p.stats.overdue > 0).toList()
      ..sort((a, b) => b.stats.overdue.compareTo(a.stats.overdue));
    return ranked.take(count).toList();
  }
}
