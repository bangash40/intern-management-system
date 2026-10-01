import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../interns/models/app_user.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

/// Emits the signed-in Firebase user, or null when signed out.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// The profile of the signed-in user, or null when signed out.
///
/// A missing or deactivated profile also gives null: the repository signs
/// the user out, so the app falls back to the login screen.
final sessionProvider = FutureProvider<AppUser?>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return null;
  try {
    return await ref.read(authRepositoryProvider).loadCurrentProfile();
  } on AuthException {
    return null;
  } on FirebaseException {
    return null;
  }
});
