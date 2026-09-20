import 'package:flutter_test/flutter_test.dart';
import 'package:careseva_clinical/main.dart';

void main() {
  testWidgets('Clinical App loads cleanly test', (WidgetTester tester) async {
    await tester.pumpWidget(const CareSevaClinicalApp());
    expect(find.textContaining('CareSeva'), findsWidgets);
  });
}
