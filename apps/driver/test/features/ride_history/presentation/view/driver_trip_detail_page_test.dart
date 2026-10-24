import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:design_system/design_system.dart';
import 'package:driver/src/features/ride_history/presentation/view/driver_trip_detail_page.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RideRepository extends Mock implements RideRepository {}

void main() {
  testWidgets('shows driver reporting only for a completed trip', (
    tester,
  ) async {
    final repository = _RideRepository();
    for (final status in [
      'accepted',
      'arrived',
      'in_transit',
      'cancelled',
      '',
      'completed',
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: TripDetailPage(
            key: ValueKey(status),
            sessionService: SessionStore(),
            rideRepository: repository,
            trip: {'id': 42, 'status': status},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byTooltip('Report a safety issue'),
        status == 'completed' ? findsOneWidget : findsNothing,
      );
    }
  });

  testWidgets('renders the hydrated passenger trip detail card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: TripDetailPage(
          sessionService: SessionStore(),
          trip: {
            'id': 42,
            'passenger_id': 7,
            'status': 'completed',
            'created_at': '2026-08-19T10:00:00Z',
            'completed_at': DateTime.now()
                .toUtc()
                .subtract(const Duration(hours: 1))
                .toIso8601String(),
            'pickup_name': 'Mountain View',
            'dropoff_name': 'Aikido of Mountain View',

            'fare_amount': 2973,
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

    expect(find.text('Mountain View'), findsOneWidget);
    expect(find.text('Aikido of Mountain View'), findsOneWidget);
    expect(find.byTooltip('Message passenger'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('driver-trip-contact-passenger')),
          )
          .onPressed,
      isNotNull,
    );
    expect(find.text('Ana Maria'), findsOneWidget);
    expect(find.text('+63 917 555 0101'), findsNothing);
    expect(find.text('4.8'), findsOneWidget);
    expect(
      find.text('Friendly passenger and ready at pickup.'),
      findsOneWidget,
    );
    expect(find.text('Ride type'), findsNothing);
    expect(find.text('Solo'), findsNothing);
    expect(find.text('RIDE TYPE'), findsNothing);
    expect(find.text('TOTAL FARE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closes passenger contact for cancelled or expired trips', (
    tester,
  ) async {
    final closedTrips = [
      <String, dynamic>{'status': 'cancelled'},
      <String, dynamic>{
        'status': 'completed',
        'completed_at': DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 25))
            .toIso8601String(),
      },
    ];

    for (final trip in closedTrips) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: TripDetailPage(
            sessionService: SessionStore(),
            trip: {
              'id': 42,
              'passenger_id': 7,
              'created_at': '2026-08-19T10:00:00Z',
              ...trip,
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Message passenger'), findsNothing);
      expect(
        find.byKey(const ValueKey('driver-trip-contact-passenger')),
        findsNothing,
      );
    }

    expect(tester.takeException(), isNull);
  });
}
