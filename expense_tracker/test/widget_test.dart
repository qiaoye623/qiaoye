import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/screens/main_shell.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    // Verify MainShell renders
    expect(find.byType(MainShell), findsOneWidget);
  });
}
