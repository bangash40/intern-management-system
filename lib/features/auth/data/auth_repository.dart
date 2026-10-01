import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../interns/models/app_user.dart';

/// A readable error that can be shown directly to the user.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  /// Maps a Firebase error code to a message for the user.
  factory AuthException.fromCode(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
        return const AuthException('Incorrect email or password.');
      case 'user-not-found':
        return const AuthException('No account found with this email.');
      case 'invalid-email':
        return const AuthException('Enter a valid email address.');
      case 'user-disabled':
        return const AuthException('This account has been disabled.');
      case 'too-many-requests':
        return const AuthException('Too many attempts. Try again later.');
      case 'network-request-failed':
        return const AuthException('No internet connection.');
      case 'email-already-in-use':
        return const AuthException('This email is already in use.');
      case 'permission-denied':
        return const AuthException(
          'Access to the database was denied. Check the Firestore rules.',
        );
      case 'unavailable':
        return const AuthException(
          'Service unavailable. Check your connection.',
        );
      default:
        return const AuthException('Something went wrong. Please try again.');
    }
  }

  @override
  String toString() => message;
}

/// All Firebase Authentication calls for login live here.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Signs in, then loads the matching `users/{uid}` profile.
  ///
  /// If the profile is missing or the account is deactivated the user is
  /// signed out again and an [AuthException] is thrown.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return await _requireActiveProfile(credential.user!.uid);
    } on FirebaseException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  /// Loads the profile of the signed-in user, for checks on app start.
  /// Signs out and throws if the profile is missing or deactivated.
  Future<AppUser> loadCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('You are not signed in.');
    }
    return _requireActiveProfile(user.uid);
  }

  Future<AppUser?> fetchProfile(String uid) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return AppUser.fromMap({...data, 'uid': doc.id});
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseException catch (e) {
      throw AuthException.fromCode(e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<AppUser> _requireActiveProfile(String uid) async {
    final AppUser? profile;
    try {
      profile = await fetchProfile(uid);
    } on FirebaseException catch (e) {
      await _auth.signOut();
      throw AuthException.fromCode(e.code);
    }
    if (profile == null) {
      await _auth.signOut();
      throw const AuthException('Your account is not set up. Contact admin.');
    }
    if (!profile.isActive) {
      await _auth.signOut();
      throw const AuthException('Your account has been deactivated.');
    }
    return profile;
  }
}
