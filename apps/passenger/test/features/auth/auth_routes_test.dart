import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/auth/auth_routes.dart';
import 'package:passenger/src/features/home/home_routes.dart';

void main() {
  test('root redirect only handles the exact app root', () {
    expect(
      authRootRedirect(Uri.parse(AuthRoutes.rootPath)),
      HomeRoutes.fullHomePath,
    );
    expect(authRootRedirect(Uri.parse(AuthRoutes.signinPath)), isNull);
    expect(authRootRedirect(Uri.parse(AuthRoutes.signupPath)), isNull);
  });
}
