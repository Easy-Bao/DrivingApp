import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';

void main() {
  test('root redirect only handles the exact app root', () {
    expect(AuthRoutes.rootRedirect(Uri.parse('/')), '/passenger/location-gate');
    expect(AuthRoutes.rootRedirect(Uri.parse('/auth/signin')), isNull);
    expect(AuthRoutes.rootRedirect(Uri.parse('/auth/signup')), isNull);
  });
}
