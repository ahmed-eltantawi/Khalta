import 'package:flutter_test/flutter_test.dart';
import 'package:test2/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZikolaApp());
    await tester.pump();
    // Verify app renders without crashing
    expect(find.byType(ZikolaApp), findsOneWidget);
  });
}
