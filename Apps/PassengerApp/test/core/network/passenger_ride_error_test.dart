import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/Features/Booking/Data/DataSources/BiddingRemoteDataSource.dart';

void main() {
  test('maps passenger ride blockers to clear next steps', () {
    expect(
      passengerRideErrorMessage('ACCOUNT_RESTRICTED'),
      contains('cannot request a ride'),
    );
    expect(
      passengerRideErrorMessage('OUTSIDE_SERVICE_ZONE'),
      contains('pickup and destination inside'),
    );
    expect(
      passengerRideErrorMessage('SERVICE_ZONE_NOT_CONFIGURED'),
      contains('pilot service area has not been activated'),
    );
  });

  test('reads accepted ride identifiers from current server responses', () {
    expect(acceptedRideId({'rideId': 'ride-1'}), 'ride-1');
    expect(acceptedRideId({'accepted_trip_id': 'ride-2'}), 'ride-2');
    expect(
      acceptedRideId({
        'session': {'accepted_trip_id': 'ride-3'},
      }),
      'ride-3',
    );
  });
}
