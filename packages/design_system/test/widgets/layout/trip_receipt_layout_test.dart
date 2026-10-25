import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'receipt date stays centered across the toolbar at scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var wentBack = false;
        const date = 'Oct 24, 2026 · 12:21 PM';
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.main,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: TripReceiptLayout(
                dateLabel: date,
                onBack: () => wentBack = true,
                child: const Text('Receipt'),
              ),
            ),
          ),
        );
        final toolbar = tester.getRect(find.byType(AppBar));
        final title = tester.getRect(find.text(date));
        expect(title.center.dx, closeTo(toolbar.center.dx, 0.5));
        expect(title.center.dy, closeTo(toolbar.center.dy, 0.5));
        await tester.tap(find.byTooltip('Back'));
        expect(wentBack, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
