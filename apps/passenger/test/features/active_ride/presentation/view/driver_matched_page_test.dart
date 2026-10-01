import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/active_ride/presentation/view/driver_matched_page.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_profile_stats.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';

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
  testWidgets('keeps the match screen usable on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: DriverMatchedPage(
          rideType: 'Bicycle',
          fare: 26,
          destination: const Place(
            id: 'destination-1',
            name: 'Pasadena Inn',
            fullAddress: 'Pasadena Inn',
            latitude: 7.83,
            longitude: 123.44,
          ),
          distance: '1.2 km',
          duration: '5 min',
          driverName: 'Xyrel D. Tenefrancia',
          driverRating: '4.9',
          vehicleType: 'Tricycle',
          plateNumber: 'ABC 2034',
          profileRepository: _DriverProfileRepositoryStub(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Track Your Driver'), findsOneWidget);
  });
}
