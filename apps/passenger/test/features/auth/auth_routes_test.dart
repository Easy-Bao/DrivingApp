import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/features/auth/auth_module.dart';
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

  test('auth form routes enter from opposite sides for the bottom links', () {
    final routes = AuthModule().routes.whereType<ChildRoute>();
    final signInRoute = routes.singleWhere(
      (route) => route.name == AuthRoutes.signin,
    );
    final signUpRoute = routes.singleWhere(
      (route) => route.name == AuthRoutes.signup,
    );

    final signInTransition = signInRoute.transition! as CustomPageTransition;
    final signUpTransition = signUpRoute.transition! as CustomPageTransition;

    expect(signInTransition.fromRight, isFalse);
    expect(signUpTransition.fromRight, isTrue);
  });
}
