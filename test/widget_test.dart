import 'package:flutter_test/flutter_test.dart';
import 'package:reskyo_finale/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ReskyoApp());
    expect(find.text('Sign In'), findsOneWidget);
  });
}
