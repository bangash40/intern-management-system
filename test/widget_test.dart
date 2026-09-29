import 'package:flutter_test/flutter_test.dart';

import 'package:intern_management_system/main.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const InternManagementApp());
    expect(find.text('Intern Management System'), findsOneWidget);
  });
}
