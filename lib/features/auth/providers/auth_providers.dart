import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

/// Emits the signed-in Firebase user, or null when signed out.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
