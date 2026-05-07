import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    await tester.pumpWidget(const ZiraatApp());
  });
}
