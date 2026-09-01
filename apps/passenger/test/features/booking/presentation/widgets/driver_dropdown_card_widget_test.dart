import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:passenger/src/features/booking/booking.dart';
import 'package:passenger/src/features/booking/presentation/widgets/driver_dropdown_card_widget.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_profile_stats.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';

const driver = DriverModel(
  id: 'driver-1',
  name: 'Demo Driver',
  vehicleType: 'Sedan',
  plateNumber: 'ABC-123',
  rating: 4.8,
  lat: 7.83,
  lng: 123.44,
  distanceKm: 0.4,
  etaMinutes: 3,
  score: 0.9,
);

class _DriverProfileRepositoryStub implements DriverProfileRepository {
  @override
  Future<Either<Failure, DriverProfileStats>> fetchStats(
    String driverId,
  ) async => const Right(DriverProfileStats(completedTrips: 12));

  @override
  Future<Either<Failure, List<DriverReview>>> fetchReviews(
    String driverId, {
    int page = 1,
    int limit = 20,
  }) async => const Right([]);

  @override
  Future<Either<Failure, void>> submitReview({
    required String driverId,
    required String rideId,
    required double rating,
    required String comment,
  }) async => const Right(null);
}

void main() {
  testWidgets('opens the driver profile inside the selected card', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _DriverCardHarness()));

    expect(find.text('View Full Profile'), findsOneWidget);

    await tester.tap(find.text('View Full Profile'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Driver profile'), findsOneWidget);
    expect(find.byKey(const ValueKey('driver-profile-back')), findsOneWidget);
    expect(find.text('View Full Profile'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('driver-profile-back')));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('View Full Profile'), findsOneWidget);
  });
}

class const _DriverCardHarness() extends StatefulWidget {
  @override
  State<_DriverCardHarness> createState() => _DriverCardHarnessState();
}

class _DriverCardHarnessState extends State<_DriverCardHarness> {
  bool _isProfileVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DriverDropdownCardWidget(
        driver: driver,
        isNearestDriver: true,
        isProfileVisible: _isProfileVisible,
        onViewFullProfilePressed: () {
          setState(() => _isProfileVisible = true);
        },
        onProfileBackPressed: () {
          setState(() => _isProfileVisible = false);
        },
        onSelectDriverPressed: () {},
        onCloseDropdownPressed: () {},
        profileRepository: _DriverProfileRepositoryStub(),
      ),
    );
  }
}
