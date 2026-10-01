import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/intern_repository.dart';
import '../models/app_user.dart';

final internRepositoryProvider = Provider<InternRepository>(
  (ref) => InternRepository(),
);

/// Live list of all interns, sorted by name (admin).
final internsProvider = StreamProvider.autoDispose<List<AppUser>>(
  (ref) => ref.watch(internRepositoryProvider).watchInterns(),
);

/// Live profile of one intern (admin).
final internProvider = StreamProvider.autoDispose.family<AppUser?, String>(
  (ref, uid) => ref.watch(internRepositoryProvider).watchIntern(uid),
);
