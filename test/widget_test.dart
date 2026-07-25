// This is a basic Flutter widget test for Bharat Pray application.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:bharat_pray/main.dart';

void main() {
  testWidgets('Bharat Pray App Login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BharatPrayApp());

    // Verify that the Login screen element is displayed.
    expect(find.text('Email Address'), findsOneWidget);
  });
}
