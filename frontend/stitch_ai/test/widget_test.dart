// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_ai/main.dart';

void main() {
  testWidgets('Login navigates to Home (Marketplace visible)', (tester) async {
    // Pump the app with initial route '/login'
    await tester.pumpWidget(const StitchAiApp());

    // Login screen should show a Login button
    expect(find.text('Login'), findsOneWidget);

    // Tap Login to navigate to Home
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Home screen shows Marketplace heading
    expect(find.text('Marketplace'), findsOneWidget);
  });
}
