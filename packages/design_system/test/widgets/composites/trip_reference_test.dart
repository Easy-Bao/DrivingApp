import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'receipt reference wraps, copies only its identifier, and shows inline confirmation',
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
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                child: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: TripReference(id: '701629644613868', expanded: true),
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
      final copyButton = find.widgetWithIcon(IconButton, LucideIcons.copy);
      expect(tester.getRect(copyButton).right, row.right);
      expect(
        tester.widget<SelectableText>(find.byType(SelectableText)).textAlign,
        TextAlign.end,
      );
      await tester.tap(find.byTooltip('Copy Booking ID'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(copied, '701629644613868');
      expect(find.byTooltip('Booking ID copied'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(
        tester.widget<Icon>(find.byIcon(LucideIcons.check)).color,
        AppSemanticColors.defaults.success,
      );

      await tester.pump(TripReference.copiedResetDuration);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byTooltip('Copy Booking ID'), findsOneWidget);
      expect(find.byIcon(LucideIcons.copy), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
