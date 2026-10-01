import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/app/app.dart';
import 'package:intern_management_system/app/router.dart';
import 'package:intern_management_system/features/auth/data/auth_repository.dart';
import 'package:intern_management_system/features/auth/providers/auth_providers.dart';
import 'package:intern_management_system/features/tasks/data/task_repository.dart';
import 'package:intern_management_system/features/tasks/providers/task_providers.dart';
import 'package:intern_management_system/features/interns/data/intern_repository.dart';
import 'package:intern_management_system/features/interns/models/app_user.dart';
import 'package:intern_management_system/features/interns/providers/intern_providers.dart';
import 'package:intern_management_system/core/constants/enums.dart';

AsyncValue<AppUser?> sessionOf({String? role, bool active = true}) {
  if (role == null) return const AsyncData(null);
  return AsyncData(
    AppUser(
      uid: 'u1',
      name: 'Ali',
      email: 'ali@example.com',
      role: UserRole.fromValue(role),
      isActive: active,
    ),
  );
}

void main() {
  group('resolveRedirect', () {
    test('shows the loader while the session loads', () {
      const loading = AsyncLoading<AppUser?>();
      expect(resolveRedirect(loading, '/admin'), AppRoutes.loading);
      expect(resolveRedirect(loading, AppRoutes.loading), isNull);
    });

    test('keeps the login screen during a sign-in check', () {
      const loading = AsyncLoading<AppUser?>();
      expect(resolveRedirect(loading, AppRoutes.login), isNull);
    });

    test('signed-out users are sent to login', () {
      expect(resolveRedirect(sessionOf(), '/admin'), AppRoutes.login);
      expect(resolveRedirect(sessionOf(), AppRoutes.login), isNull);
    });

    test('admins land on /admin and cannot open /intern', () {
      final admin = sessionOf(role: 'admin');
      expect(resolveRedirect(admin, AppRoutes.login), AppRoutes.admin);
      expect(resolveRedirect(admin, AppRoutes.admin), isNull);
      expect(resolveRedirect(admin, AppRoutes.intern), AppRoutes.admin);
    });

    test('interns land on /intern and cannot open /admin', () {
      final intern = sessionOf(role: 'intern');
      expect(resolveRedirect(intern, AppRoutes.login), AppRoutes.intern);
      expect(resolveRedirect(intern, AppRoutes.intern), isNull);
      expect(resolveRedirect(intern, AppRoutes.admin), AppRoutes.intern);
    });
  });

  group('app routing', () {
    late FakeFirebaseFirestore firestore;

    setUp(() => firestore = FakeFirebaseFirestore());

    Future<ProviderContainer> pumpApp(
      WidgetTester tester, {
      required bool signedIn,
    }) async {
      final auth = MockFirebaseAuth(
        signedIn: signedIn,
        mockUser: MockUser(uid: 'u1', email: 'ali@example.com'),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(auth: auth, firestore: firestore),
          ),
          taskRepositoryProvider.overrideWithValue(
            TaskRepository(firestore: firestore),
          ),
          internRepositoryProvider.overrideWithValue(
            InternRepository(firestore: firestore),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const InternManagementApp(),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    Future<void> addProfile({required String role, bool isActive = true}) =>
        firestore.collection('users').doc('u1').set({
          'name': 'Ali',
          'email': 'ali@example.com',
          'role': role,
          'isActive': isActive,
        });

    testWidgets('signed-out user starts on the login screen', (tester) async {
      await pumpApp(tester, signedIn: false);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('signed-in admin goes straight to the admin dashboard', (
      tester,
    ) async {
      await addProfile(role: 'admin');
      await pumpApp(tester, signedIn: true);
      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.text('Hi, Ali'), findsOneWidget);
    });

    testWidgets('signed-in intern goes to the intern dashboard', (
      tester,
    ) async {
      await addProfile(role: 'intern');
      await pumpApp(tester, signedIn: true);
      expect(find.text('Hi, Ali'), findsOneWidget);
    });

    testWidgets('intern is bounced back from the admin route', (tester) async {
      await addProfile(role: 'intern');
      final container = await pumpApp(tester, signedIn: true);

      container.read(routerProvider).go(AppRoutes.admin);
      await tester.pumpAndSettle();

      expect(find.text('Hi, Ali'), findsOneWidget);
      expect(find.text('Admin Dashboard'), findsNothing);
    });

    testWidgets('deactivated user on app start lands on login', (tester) async {
      await addProfile(role: 'intern', isActive: false);
      await pumpApp(tester, signedIn: true);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('signing out returns to the login screen', (tester) async {
      await addProfile(role: 'admin');
      await pumpApp(tester, signedIn: true);

      await tester.tap(find.byTooltip('Sign out'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsOneWidget);
    });
  });
}
