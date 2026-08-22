import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/core/location/services/map_annotation_service.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';

void main() {
  test('trip markers keep one screen-space size and role colors', () {
    expect(TripMapMarkerStyle.pinIconSize, greaterThan(1.0));
    expect(
      TripMapMarkerStyle.colorFor(isOrigin: true),
      AppTheme.primaryColor,
    );
    expect(TripMapMarkerStyle.colorFor(isOrigin: false), AppTheme.complete);
  });
}
