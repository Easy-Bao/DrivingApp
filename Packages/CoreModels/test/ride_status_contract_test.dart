import 'package:core_models/core_models.dart';
import 'package:test/test.dart';

void main() {
  RideUpdate update(RideStatus status) => RideUpdate(
    status: status,
    driverName: 'Driver',
    vehiclePlate: 'ABC 1234',
    vehicleType: 'Bao Bao',
  );

  test('uses canonical backend ride statuses', () {
    expect(RideStatus.inTransit.value, 'in_transit');
    expect(RideStatus.cancelled.value, 'canceled');
    expect(RideStatus.fromString('canceled'), RideStatus.cancelled);
    expect(RideStatus.fromString('cancelled'), RideStatus.cancelled);
    expect(update(RideStatus.inTransit).toJson()['status'], 'in_transit');
    expect(update(RideStatus.cancelled).toJson()['status'], 'canceled');
  });
}
