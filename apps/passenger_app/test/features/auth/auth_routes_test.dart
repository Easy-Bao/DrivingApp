import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/location/location_routes.dart';

void main() {
  test('root redirect only handles the exact app root', () {
    expect(
      AuthRoutes.rootRedirect(Uri.parse(AuthRoutes.rootPath)),
      LocationRoutes.fullGatePath,
    );
    expect(AuthRoutes.rootRedirect(Uri.parse(AuthRoutes.signinPath)), isNull);
    expect(AuthRoutes.rootRedirect(Uri.parse(AuthRoutes.signupPath)), isNull);
  });
}
