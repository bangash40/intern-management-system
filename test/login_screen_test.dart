import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/app/app.dart';
import 'package:intern_management_system/features/auth/data/auth_repository.dart';
import 'package:intern_management_system/features/auth/providers/auth_providers.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'u1', email: 'ali@example.com'),
    );
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepository(auth: auth, firestore: firestore),
          ),
        ],
        child: const InternManagementApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String email, String password) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      password,
    );
  }

  Future<void> addProfile({required bool isActive}) =>
      firestore.collection('users').doc('u1').set({
        'name': 'Ali',
        'email': 'ali@example.com',
        'role': 'intern',
        'isActive': isActive,
      });

  testWidgets('shows validation errors for empty and invalid input', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    await enter(tester, 'not-an-email', '123');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.textContaining('at least 6'), findsOneWidget);
  });

  testWidgets('password can be shown and hidden', (tester) async {
    await pumpApp(tester);

    bool obscured() => tester
        .widget<TextField>(find.widgetWithText(TextField, 'Password'))
        .obscureText;

    expect(obscured(), isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(obscured(), isFalse);
  });

  testWidgets('wrong credentials show a readable error', (tester) async {
    whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
        .on(auth)
        .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
    await pumpApp(tester);

    await enter(tester, 'ali@example.com', 'wrongpass');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('deactivated user sees a message and stays on login', (
    tester,
  ) async {
    await addProfile(isActive: false);
    await pumpApp(tester);

    await enter(tester, 'ali@example.com', 'secret1');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Your account has been deactivated.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('active user signs in and leaves the login screen', (
    tester,
  ) async {
    await addProfile(isActive: true);
    await pumpApp(tester);

    await enter(tester, 'ali@example.com', 'secret1');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Intern Dashboard'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
  });
}
