import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/task_repository.dart';
import '../models/task.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(),
);

/// Live tasks of the signed-in intern, optionally filtered by status.
final myTasksProvider = StreamProvider.autoDispose
    .family<List<Task>, TaskStatus?>((ref, status) {
      final uid = ref.watch(sessionProvider).value?.uid;
      if (uid == null) return const Stream.empty();
      return ref
          .watch(taskRepositoryProvider)
          .watchInternTasks(uid, status: status);
    });

/// Live view of a single task.
final taskProvider = StreamProvider.autoDispose.family<Task?, String>(
  (ref, id) => ref.watch(taskRepositoryProvider).watchTask(id),
);

/// Live list of every task, soonest due date first (admin).
final allTasksProvider = StreamProvider.autoDispose<List<Task>>(
  (ref) => ref.watch(taskRepositoryProvider).watchAllTasks(),
);
