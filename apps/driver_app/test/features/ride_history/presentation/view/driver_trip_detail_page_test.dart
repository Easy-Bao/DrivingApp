import 'package:driver_app/src/app/theme/app_theme.dart';
import 'package:driver_app/src/features/ride_history/presentation/view/driver_trip_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the hydrated passenger trip detail card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: const DriverTripDetailPage(
          trip: {
            'id': 42,
            'passenger_id': 7,
            'status': 'completed',
            'created_at': '2026-08-19T10:00:00Z',
            'pickup_name': 'Mountain View',
            'dropoff_name': 'Aikido of Mountain View',
            'ride_type': 'solo',
            'fare_centavos': 2973,
            'distance_km': 1.8,
            'duration_minutes': 6,
            'passenger_name': 'Ana Maria',
            'passenger_phone': '+63 917 555 0101',
            'passenger_rating': 4.8,
            'passenger_feedback': 'Friendly passenger and ready at pickup.',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip route'), findsOneWidget);
    expect(find.text('Passenger profile'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('driver-trip-route-dashes')),
      findsOneWidget,
    );
    expect(
      tester
          .renderObject<RenderBox>(
            find.byKey(const ValueKey('driver-trip-route-dashes')),
          )
          .size
          .height,
      24,
    );
    expect(find.text('Ana Maria'), findsOneWidget);
    expect(find.text('+63 917 555 0101'), findsOneWidget);
    expect(find.text('4.8 rating'), findsOneWidget);
    expect(
      find.text('Friendly passenger and ready at pickup.'),
      findsOneWidget,
    );
    expect(find.text('Ride type'), findsOneWidget);
    expect(find.text('Solo'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Ride type')).textAlign,
      TextAlign.center,
    );
    expect(tester.widget<Text>(find.text('Solo')).textAlign, TextAlign.center);
    expect(find.text('RIDE TYPE'), findsNothing);
    expect(find.text('TOTAL FARE'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
