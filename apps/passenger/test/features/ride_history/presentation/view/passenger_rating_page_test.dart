import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_profile_stats.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/ride_history/presentation/view/passenger_rating_page.dart';

class _DriverProfileRepositoryStub implements DriverProfileRepository {
  @override
  Future<Result<DriverProfileStats, Failure>> fetchStats(
    String driverId,
  ) async => const Ok(DriverProfileStats(completedTrips: 0));

  @override
  Future<Result<List<DriverReview>, Failure>> fetchReviews(
    String driverId, {
    int page = 1,
    int limit = 20,
  }) async => const Ok([]);

  @override
  Future<Result<void, Failure>> submitReview({
    required String driverId,
    required String rideId,
    required double rating,
    required String comment,
  }) async => const Ok(null);
}

void main() {
  testWidgets('rating page remains usable and identifies the driver', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PassengerRatingPage(
          driverId: 'driver-1',
          driverName: 'Demo Driver',
          rideId: 'ride-1',
          profileRepository: _DriverProfileRepositoryStub(),
        ),
      ),
    );

    expect(find.text('Demo Driver'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('passenger-rating-scroll-view')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.star_border), findsNWidgets(5));

    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pump();

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNWidgets(4));
  });
}
