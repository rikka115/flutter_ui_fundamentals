import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui_fundamentals/main.dart';

void main() {
  testWidgets('KosFinder app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KosFinderApp());
    expect(find.text('Login KosFinder'), findsOneWidget);
    expect(find.textContaining('Kadek Rica Cahyani'), findsOneWidget);
  });
}
