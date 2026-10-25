import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'receipt reference wraps and copies only its booking identifier',
    (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: const TripReference(
                    id: '701629644613868',
                    expanded: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Booking ID'), findsOneWidget);
      expect(find.text('701629644613868'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Booking ID')).style?.fontSize,
        tester
            .widget<SelectableText>(find.byType(SelectableText))
            .style
            ?.fontSize,
      );
      final row = tester.getRect(find.byType(TripReference));
      final copyButton = find.widgetWithIcon(IconButton, Icons.copy_rounded);
      expect(tester.getRect(copyButton).right, row.right);
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).textAlign,
        TextAlign.end,
      );
      await tester.tap(find.byTooltip('Copy Booking ID'));
      await tester.pump();
      expect(copied, '701629644613868');
      expect(tester.takeException(), isNull);
    },
  );
}
