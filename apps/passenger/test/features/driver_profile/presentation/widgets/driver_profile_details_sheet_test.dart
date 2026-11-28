import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_profile_stats.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/driver_profile/presentation/widgets/driver_profile_details_sheet.dart';

class _MockDriverProfileRepository extends Mock
    implements DriverProfileRepository {}

void main() {
  testWidgets(
    'paginates reviews cleanly when repository returns unmodifiable lists',
    (tester) async {
      final repository = _MockDriverProfileRepository();
      when(() => repository.fetchStats('driver-1')).thenAnswer(
        (_) async => const Ok(DriverProfileStats(completedTrips: 42)),
      );
      when(
        () =>
            repository.fetchReviews('driver-1', page: 1, limit: 3, cursor: ''),
      ).thenAnswer(
        (_) async => Ok(
          OffsetPage<DriverReview>(
            items: List<DriverReview>.unmodifiable(const [
              DriverReview(
                passengerName: 'Alex',
                comment: 'Smooth ride through downtown.',
                rating: 5,
              ),
              DriverReview(
                passengerName: 'Bea',
                comment: 'Arrived right on time.',
                rating: 4.5,
              ),
              DriverReview(
                passengerName: 'Carl',
                comment: 'Polite driver and clean cabin.',
                rating: 5,
              ),
            ]),
            nextOffset: 3,
            hasMore: true,
            nextCursor: 'cursor-page-2',
          ),
        ),
      );
      when(
        () => repository.fetchReviews(
          'driver-1',
          page: 2,
          limit: 3,
          cursor: 'cursor-page-2',
        ),
      ).thenAnswer(
        (_) async => Ok(
          OffsetPage<DriverReview>(
            items: List<DriverReview>.unmodifiable(const [
              DriverReview(
                passengerName: 'Dana',
                comment: 'Second page review loaded cleanly.',
                rating: 5,
              ),
            ]),
            nextOffset: 4,
            hasMore: false,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: Scaffold(
            body: DriverProfileDetailsSheet(
              driverId: 'driver-1',
              driverName: 'Jordan Reyes',
              vehicleType: 'Tricycle',
              plateNumber: 'ABC-123',
              rating: '4.9',
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('42'), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Dana'), findsOneWidget);
      expect(find.text('Second page review loaded cleanly.'), findsOneWidget);
    },
  );

  testWidgets(
    'shows error state and retries instead of pretending there are no reviews',
    (tester) async {
      final repository = _MockDriverProfileRepository();
      var attempts = 0;
      when(() => repository.fetchStats('driver-2')).thenAnswer(
        (_) async => const Ok(DriverProfileStats(completedTrips: 12)),
      );
      when(
        () =>
            repository.fetchReviews('driver-2', page: 1, limit: 3, cursor: ''),
      ).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) {
          return const Err(ServerFailure('Unable to load reviews.'));
        }
        return const Ok(
          OffsetPage<DriverReview>(
            items: [
              DriverReview(
                passengerName: 'Elena',
                comment: 'Great trip after retry.',
                rating: 5,
              ),
            ],
            nextOffset: 1,
            hasMore: false,
          ),
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: Scaffold(
            body: DriverProfileDetailsSheet(
              driverId: 'driver-2',
              driverName: 'Sam Cruz',
              vehicleType: 'Sedan',
              plateNumber: 'XYZ-789',
              rating: '4.8',
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No passenger reviews yet.'), findsNothing);
      expect(find.text('Unable to load reviews.'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Elena'), findsOneWidget);
      expect(attempts, 2);
    },
  );

  testWidgets(
    'shows inline retry error when loading the next page of reviews fails',
    (tester) async {
      final repository = _MockDriverProfileRepository();
      var pageTwoAttempts = 0;
      when(() => repository.fetchStats('driver-3')).thenAnswer(
        (_) async => const Ok(DriverProfileStats(completedTrips: 20)),
      );
      when(
        () =>
            repository.fetchReviews('driver-3', page: 1, limit: 3, cursor: ''),
      ).thenAnswer(
        (_) async => const Ok(
          OffsetPage<DriverReview>(
            items: [
              DriverReview(
                passengerName: 'Alex',
                comment: 'Smooth first review.',
                rating: 5,
              ),
              DriverReview(
                passengerName: 'Bea',
                comment: 'Second review.',
                rating: 4.5,
              ),
              DriverReview(
                passengerName: 'Carl',
                comment: 'Third review.',
                rating: 5,
              ),
            ],
            nextOffset: 3,
            hasMore: true,
            nextCursor: 'cursor-page-2',
          ),
        ),
      );
      when(
        () => repository.fetchReviews(
          'driver-3',
          page: 2,
          limit: 3,
          cursor: 'cursor-page-2',
        ),
      ).thenAnswer((_) async {
        pageTwoAttempts++;
        if (pageTwoAttempts == 1) {
          return const Err(NetworkFailure('Unable to load more reviews.'));
        }
        return const Ok(
          OffsetPage<DriverReview>(
            items: [
              DriverReview(
                passengerName: 'Dana',
                comment: 'Loaded after pagination retry.',
                rating: 5,
              ),
            ],
            nextOffset: 4,
            hasMore: false,
          ),
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: Scaffold(
            body: DriverProfileDetailsSheet(
              driverId: 'driver-3',
              driverName: 'Jordan Reyes',
              vehicleType: 'Tricycle',
              plateNumber: 'ABC-123',
              rating: '4.9',
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load more reviews.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(pageTwoAttempts, 1);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Dana'), findsOneWidget);
      expect(find.text('Loaded after pagination retry.'), findsOneWidget);
      expect(pageTwoAttempts, 2);
    },
  );
}
