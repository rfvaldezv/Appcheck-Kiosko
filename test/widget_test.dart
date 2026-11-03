import 'package:flutter_test/flutter_test.dart';
import 'package:appcheck_kiosko/main.dart';

void main() {
  testWidgets('La app carga el SplashScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const AppCheckKioskoApp());
    expect(find.text('AppCheck'), findsOneWidget);
  });
}
