import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intern_management_system/app/app.dart';
import 'package:intern_management_system/features/auth/data/auth_repository.dart';
import 'package:intern_management_system/features/auth/providers/auth_providers.dart';

Widget buildApp({
  required MockFirebaseAuth auth,
  required FakeFirebaseFirestore firestore,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        AuthRepository(auth: auth, firestore: firestore),
      ),
    ],
    child: const InternManagementApp(),
  );
}

MockFirebaseAuth signedOutAuth() => MockFirebaseAuth(
  mockUser: MockUser(uid: 'u1', email: 'ali@example.com'),
);

void main() {
  testWidgets('app uses a single Material 3 light theme', (tester) async {
    await tester.pumpWidget(
      buildApp(auth: signedOutAuth(), firestore: FakeFirebaseFirestore()),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.useMaterial3, isTrue);
    expect(app.theme!.brightness, Brightness.light);
    expect(app.darkTheme, isNull);
    expect(find.byTooltip('Toggle light / dark mode'), findsNothing);
  });
}
