import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(),
);
