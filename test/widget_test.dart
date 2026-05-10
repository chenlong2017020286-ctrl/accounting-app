import "package:flutter_test/flutter_test.dart";
import "package:accounting_app/main.dart";

void main() {
  testWidgets("App loads", (tester) async {
    await tester.pumpWidget(const AccountingApp());
    expect(find.text("我的账本"), findsOneWidget);
  });
}
