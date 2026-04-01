// Basic smoke test for Spend Gremlin app.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spend_gremlin/src/app.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpendGremlinApp()));
    // Just verify the app renders without error.
    expect(find.textContaining('Spend Gremlin'), findsAny);
  });
}
