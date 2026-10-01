import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/core/constants/enums.dart';
import 'package:intern_management_system/features/auth/data/auth_repository.dart';
import 'package:intern_management_system/features/interns/data/intern_repository.dart';
import 'package:intern_management_system/features/interns/presentation/intern_form_screen.dart';
import 'package:intern_management_system/features/interns/presentation/interns_list_screen.dart';
import 'package:intern_management_system/features/interns/providers/intern_providers.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  Future<void> addUser(
    String uid,
    String name, {
    String role = 'intern',
    bool isActive = true,
    String department = 'Flutter',
  }) => firestore.collection('users').doc(uid).set({
    'name': name,
    'email': '${name.toLowerCase()}@example.com',
    'role': role,
    'isActive': isActive,
    'department': department,
  });

  group('InternRepository', () {
    test('createIntern makes the login and the profile', () async {
      String? seenEmail;
      final repo = InternRepository(
        firestore: firestore,
        createAuthUser: (email, password) async {
          seenEmail = email;
          return 'new-uid';
        },
      );

      final intern = await repo.createIntern(
        name: ' Sara Khan ',
        email: ' Sara@Example.com ',
        password: 'secret1',
        department: 'Design',
        startDate: DateTime(2026, 1, 5),
        endDate: DateTime(2026, 4, 5),
        mentor: 'Bilal',
      );

      expect(seenEmail, 'sara@example.com');
      expect(intern.uid, 'new-uid');

      final doc = await firestore.collection('users').doc('new-uid').get();
      expect(doc.data()!['name'], 'Sara Khan');
      expect(doc.data()!['email'], 'sara@example.com');
      expect(doc.data()!['role'], 'intern');
      expect(doc.data()!['isActive'], true);
      expect(doc.data()!['mentor'], 'Bilal');
      expect(doc.data()!['createdAt'], isNotNull);
    });

    test('createIntern shows a readable error for a used email', () async {
      final repo = InternRepository(
        firestore: firestore,
        createAuthUser: (_, _) async =>
            throw FirebaseAuthException(code: 'email-already-in-use'),
      );

      await expectLater(
        repo.createIntern(
          name: 'Sara',
          email: 'sara@example.com',
          password: 'secret1',
          department: 'Design',
          startDate: DateTime(2026),
          endDate: DateTime(2026, 6),
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'This email is already in use.',
          ),
        ),
      );
      expect((await firestore.collection('users').get()).docs, isEmpty);
    });

    test('watchInterns lists only interns, sorted by name', () async {
      await addUser('1', 'Zara');
      await addUser('2', 'Ali');
      await addUser('3', 'Boss', role: 'admin');

      final interns = await InternRepository(firestore: firestore)
          .watchInterns()
          .first;

      expect(interns.map((u) => u.name), ['Ali', 'Zara']);
      expect(interns.first.role, UserRole.intern);
    });
  });

  group('InternsListScreen', () {
    Future<void> pumpList(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            internRepositoryProvider.overrideWithValue(
              InternRepository(firestore: firestore),
            ),
          ],
          child: const MaterialApp(home: InternsListScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows an empty state with a hint', (tester) async {
      await pumpList(tester);
      expect(find.textContaining('No interns yet'), findsOneWidget);
    });

    testWidgets('lists interns and searches by name or email', (tester) async {
      await addUser('1', 'Ali');
      await addUser('2', 'Zara');
      await pumpList(tester);

      expect(find.text('Ali'), findsOneWidget);
      expect(find.text('Zara'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zar');
      await tester.pumpAndSettle();
      expect(find.text('Ali'), findsNothing);
      expect(find.text('Zara'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'nobody');
      await tester.pumpAndSettle();
      expect(find.text('No interns match your search.'), findsOneWidget);
    });

    testWidgets('filters by active and inactive', (tester) async {
      await addUser('1', 'Ali');
      await addUser('2', 'Zara', isActive: false);
      await pumpList(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Inactive'));
      await tester.pumpAndSettle();
      expect(find.text('Ali'), findsNothing);
      expect(find.text('Zara'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Active'));
      await tester.pumpAndSettle();
      expect(find.text('Ali'), findsOneWidget);
      expect(find.text('Zara'), findsNothing);
    });
  });

  group('InternFormScreen', () {
    Future<void> pumpForm(
      WidgetTester tester, {
      CreateAuthUser? createAuthUser,
    }) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            internRepositoryProvider.overrideWithValue(
              InternRepository(
                firestore: firestore,
                createAuthUser: createAuthUser ?? (_, _) async => 'new-uid',
              ),
            ),
          ],
          child: const MaterialApp(home: InternFormScreen()),
        ),
      );
    }

    Future<void> field(WidgetTester tester, String label, String text) =>
        tester.enterText(find.widgetWithText(TextFormField, label), text);

    /// Opens the first date field that still says "Select a date" and
    /// accepts the picker's default (today).
    Future<void> pickNextDate(WidgetTester tester) async {
      await tester.tap(find.text('Select a date').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    testWidgets('validates required fields', (tester) async {
      await pumpForm(tester);

      await tester.tap(find.text('Create intern'));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Department is required'), findsOneWidget);
      expect(find.text('Select a start date'), findsOneWidget);
      expect(find.text('Select an end date'), findsOneWidget);
      expect((await firestore.collection('users').get()).docs, isEmpty);
    });

    testWidgets('saves a valid intern', (tester) async {
      await pumpForm(tester);

      await field(tester, 'Full name', 'Sara Khan');
      await field(tester, 'Email', 'sara@example.com');
      await field(tester, 'Temporary password', 'secret1');
      await field(tester, 'Department', 'Design');
      await pickNextDate(tester);
      await pickNextDate(tester);

      await tester.tap(find.text('Create intern'));
      await tester.pumpAndSettle();

      final doc = await firestore.collection('users').doc('new-uid').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['name'], 'Sara Khan');
      expect(doc.data()!['department'], 'Design');
    });

    testWidgets('shows the error when the email is already used', (
      tester,
    ) async {
      await pumpForm(
        tester,
        createAuthUser: (_, _) async =>
            throw FirebaseAuthException(code: 'email-already-in-use'),
      );

      await field(tester, 'Full name', 'Sara Khan');
      await field(tester, 'Email', 'sara@example.com');
      await field(tester, 'Temporary password', 'secret1');
      await field(tester, 'Department', 'Design');
      await pickNextDate(tester);
      await pickNextDate(tester);

      await tester.tap(find.text('Create intern'));
      await tester.pumpAndSettle();

      expect(find.text('This email is already in use.'), findsOneWidget);
    });
  });
}
