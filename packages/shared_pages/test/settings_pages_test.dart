import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_pages/shared_pages.dart';

void main() {
  testWidgets('terms page exposes completed legal sections', (tester) async {
    var backCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: AppTermsOfServicePage(onBack: () => backCount++),
      ),
    );
    expect(find.text('EasyRide Terms of Service'), findsOneWidget);
    expect(
      find.text('Account responsibility', skipOffstage: false),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Back'));
    expect(backCount, 1);
    expect(tester.takeException(), isNull);
  });
}
