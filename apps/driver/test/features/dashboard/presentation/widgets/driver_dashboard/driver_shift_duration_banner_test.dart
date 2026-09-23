import 'package:driver/src/features/dashboard/presentation/widgets/driver_dashboard/driver_shift_duration_banner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats the shift timer as hours and minutes', () {
    expect(
      DriverShiftDurationBanner.formatDuration(
        const Duration(hours: 8, minutes: 3),
      ),
      '08:03',
    );
  });

  test('recommends a break at the eight-hour threshold', () {
    const banner = DriverShiftDurationBanner(duration: Duration(hours: 8));

    expect(banner.breakRecommended, isTrue);
  });
}
