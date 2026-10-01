import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../core/constants/enums.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../firebase_options.dart';
import '../../auth/data/auth_repository.dart';
import '../models/app_user.dart';

/// Creates a Firebase Auth account and returns its uid, without signing the
/// current user out.
typedef CreateAuthUser = Future<String> Function(String email, String password);

/// Default [CreateAuthUser].
///
/// `createUserWithEmailAndPassword` signs the new user in, which would sign
/// the admin out. Using a second Firebase app instance keeps the admin
/// signed in on the main one.
Future<String> createUserOnSecondaryApp(String email, String password) async {
  const appName = 'secondary';
  FirebaseApp app;
  try {
    app = Firebase.app(appName);
  } on FirebaseException {
    app = await Firebase.initializeApp(
      name: appName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  final auth = FirebaseAuth.instanceFor(app: app);
  try {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!.uid;
  } finally {
    await auth.signOut();
  }
}

/// All Firestore calls for intern profiles live here.
class InternRepository {
  InternRepository({
    FirebaseFirestore? firestore,
    CreateAuthUser? createAuthUser,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _createAuthUser = createAuthUser ?? createUserOnSecondaryApp;

  final FirebaseFirestore _firestore;
  final CreateAuthUser _createAuthUser;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  /// All interns, sorted by name. Sorting happens here rather than in the
  /// query so no composite index is needed.
  Stream<List<AppUser>> watchInterns() {
    return _users
        .where('role', isEqualTo: UserRole.intern.value)
        .snapshots()
        .map((snapshot) {
          final interns = snapshot.docs
              .map((d) => AppUser.fromMap({...d.data(), 'uid': d.id}))
              .toList();
          interns.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          return interns;
        });
  }

  /// One intern's profile, live. Null when it does not exist.
  Stream<AppUser?> watchIntern(String uid) =>
      _users.doc(uid).snapshots().map((doc) {
        final data = doc.data();
        if (!doc.exists || data == null) return null;
        return AppUser.fromMap({...data, 'uid': doc.id});
      });

  /// Edits the profile fields. The email cannot be changed.
  Future<void> updateIntern(AppUser intern) => _users.doc(intern.uid).update({
    'name': intern.name.trim(),
    'phone': intern.phone.trim(),
    'department': intern.department.trim(),
    'mentor': intern.mentor.trim(),
    'startDate': intern.startDate == null
        ? null
        : Timestamp.fromDate(intern.startDate!),
    'endDate': intern.endDate == null
        ? null
        : Timestamp.fromDate(intern.endDate!),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  /// Deactivated interns cannot use the app, but their history is kept.
  Future<void> setActive(String uid, {required bool isActive}) =>
      _users.doc(uid).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Creates the intern's login and profile. Returns the new profile.
  ///
  /// Throws an [AuthException] with a readable message on failure.
  Future<AppUser> createIntern({
    required String name,
    required String email,
    required String password,
    required String department,
    required DateTime startDate,
    required DateTime endDate,
    String phone = '',
    String mentor = '',
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    final String uid;
    try {
      uid = await _createAuthUser(cleanEmail, password);
    } on FirebaseException catch (e) {
      throw AuthException.fromCode(e.code);
    }

    final intern = AppUser(
      uid: uid,
      name: name.trim(),
      email: cleanEmail,
      role: UserRole.intern,
      isActive: true,
      phone: phone.trim(),
      department: department.trim(),
      mentor: mentor.trim(),
      startDate: startDate,
      endDate: endDate,
    );

    try {
      await _users.doc(uid).set({
        ...intern.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AuthException.fromCode(e.code);
    }
    return intern;
  }
}
