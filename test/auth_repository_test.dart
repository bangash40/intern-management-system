import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:intern_management_system/core/constants/enums.dart';
import 'package:intern_management_system/features/auth/data/auth_repository.dart';
import 'package:intern_management_system/features/interns/models/app_user.dart';

void main() {
  group('AppUser', () {
    test('toMap and fromMap round-trip', () {
      final user = AppUser(
        uid: 'u1',
        name: 'Ali',
        email: 'Ali@Example.com',
        role: UserRole.intern,
        isActive: true,
        department: 'Flutter',
        startDate: DateTime(2026, 1, 10),
      );

      final copy = AppUser.fromMap(user.toMap());

      expect(copy.uid, 'u1');
      expect(copy.email, 'ali@example.com');
      expect(copy.role, UserRole.intern);
      expect(copy.department, 'Flutter');
      expect(copy.startDate, DateTime(2026, 1, 10));
      expect(copy.endDate, isNull);
    });

    test('fromMap falls back safely on missing fields', () {
      final user = AppUser.fromMap({});
      expect(user.isActive, isFalse);
      expect(user.role, UserRole.intern);
    });
  });

  group('AuthException', () {
    test('maps Firebase codes to readable messages', () {
      expect(
        AuthException.fromCode('invalid-credential').message,
        'Incorrect email or password.',
      );
      expect(
        AuthException.fromCode('network-request-failed').message,
        'No internet connection.',
      );
      expect(
        AuthException.fromCode('permission-denied').message,
        contains('Firestore rules'),
      );
      expect(AuthException.fromCode('unknown').message, contains('wrong'));
    });
  });

  group('AuthRepository', () {
    late FakeFirebaseFirestore firestore;

    setUp(() => firestore = FakeFirebaseFirestore());

    Future<void> addProfile({required bool isActive, String role = 'intern'}) {
      return firestore.collection('users').doc('u1').set({
        'name': 'Ali',
        'email': 'ali@example.com',
        'role': role,
        'isActive': isActive,
      });
    }

    AuthRepository repo(MockFirebaseAuth auth) =>
        AuthRepository(auth: auth, firestore: firestore);

    MockFirebaseAuth signedOutAuth() => MockFirebaseAuth(
      mockUser: MockUser(uid: 'u1', email: 'ali@example.com'),
    );

    test('signIn returns the profile of an active user', () async {
      await addProfile(isActive: true);

      final profile = await repo(signedOutAuth())
          .signIn(email: 'ali@example.com', password: 'secret1');

      expect(profile.uid, 'u1');
      expect(profile.name, 'Ali');
      expect(profile.role, UserRole.intern);
    });

    test('signIn signs out and throws for a deactivated user', () async {
      await addProfile(isActive: false);
      final auth = signedOutAuth();

      await expectLater(
        repo(auth).signIn(email: 'ali@example.com', password: 'secret1'),
        throwsA(isA<AuthException>()),
      );
      expect(auth.currentUser, isNull);
    });

    test('signIn signs out and throws when the profile is missing', () async {
      final auth = signedOutAuth();

      await expectLater(
        repo(auth).signIn(email: 'ali@example.com', password: 'secret1'),
        throwsA(isA<AuthException>()),
      );
      expect(auth.currentUser, isNull);
    });

    test('signIn turns a Firebase error into an AuthException', () async {
      final auth = MockFirebaseAuth();
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'invalid-credential'));

      await expectLater(
        repo(auth).signIn(email: 'a@b.com', password: 'bad'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Incorrect email or password.',
          ),
        ),
      );
    });

    test('fetchProfile returns null for an unknown uid', () async {
      expect(await repo(signedOutAuth()).fetchProfile('nobody'), isNull);
    });

    test('signOut clears the current user', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1'),
      );
      await repo(auth).signOut();
      expect(auth.currentUser, isNull);
    });
  });
}
