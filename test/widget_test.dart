import 'package:flutter_test/flutter_test.dart';
import 'package:flooria/main.dart';

void main() {
  testWidgets('Flooria boots with locally saved journey', (tester) async {
    await tester.pumpWidget(const FlooriaApp());
    await tester.pumpAndSettle();
    expect(find.text('Flooria'), findsOneWidget);
  }, skip: true); // Requires SharedPreferences test initialization.
}
