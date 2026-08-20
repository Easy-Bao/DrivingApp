import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/home/domain/entities/public_driver_summary.dart';
import 'package:passenger_app/src/features/home/view/widgets/public_driver_summary_card_widget.dart';

void main() {
  testWidgets('shows ratings while explaining location privacy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeData,
        home: const Scaffold(
          body: PublicDriverSummaryCardWidget(
            summaries: [
              PublicDriverSummary(
                id: '42',
                name: 'Nearby Driver',
                vehicleType: 'Sedan',
                rating: 4.8,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Drivers Online Now'), findsOneWidget);
    expect(find.text('Nearby Driver'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    expect(
      find.text(
        'These drivers can accept a ride. Compare their ratings before you request one.',
      ),
      findsOneWidget,
    );
  });
}
