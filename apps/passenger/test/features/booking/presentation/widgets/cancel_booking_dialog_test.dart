import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/booking/presentation/widgets/cancel_booking_dialog.dart';

void main() {
  testWidgets(
    'renders driver search cancellation confirmation and returns chosen action',
    (tester) async {
      bool? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  confirmed = await showCancelBookingDialog(
                    context,
                    destinationName: 'Robinsons Place',
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel driver search?'), findsOneWidget);
      expect(find.textContaining('Robinsons Place'), findsOneWidget);
      expect(find.text('Keep searching'), findsOneWidget);
      expect(find.text('Cancel search'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('keep-booking-button')),
      );
      await tester.pumpAndSettle();
      expect(confirmed, isFalse);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('confirm-cancel-booking-button')),
      );
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    },
  );

  testWidgets('adapts copy for active ride requests waiting for a driver', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: const Scaffold(
          body: CancelBookingDialog(
            isActiveRequest: true,
            destinationName: 'City Hall',
          ),
        ),
      ),
    );

    expect(find.text('Cancel ride request?'), findsOneWidget);
    expect(find.textContaining('City Hall'), findsOneWidget);
    expect(find.text('Keep waiting'), findsOneWidget);
    expect(find.text('Cancel request'), findsOneWidget);
  });
}
