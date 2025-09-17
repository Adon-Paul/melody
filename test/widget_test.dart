// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:melody/main.dart';

void main() {
  testWidgets('Melody app initializes without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MelodyApp());

    // Verify app loads without exceptions
    expect(tester.takeException(), isNull);
  });
}
