import 'package:bloc_test/bloc_test.dart';
import 'package:driver_app/src/features/auth/bloc/sign_in/sign_in_bloc.dart';
import 'package:driver_app/src/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_core/shared_core.dart';

class _MockSignInUseCase extends Mock implements SignInUseCase {}

void main() {
  late _MockSignInUseCase signInUseCase;

  setUp(() {
    signInUseCase = _MockSignInUseCase();
  });

  blocTest<SignInBloc, SignInState>(
    'shows a credential error instead of a session-expired message',
    setUp: () {
      when(
        () => signInUseCase.execute(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Left(AuthFailure('Invalid email or password.')),
      );
    },
    build: () => SignInBloc(signInUseCase),
    act: (bloc) => bloc.add(
      const SignInSubmitted(
        email: ' Passenger@Example.com ',
        password: ' password-with-spaces ',
      ),
    ),
    expect: () => const <SignInState>[
      SignInLoading(),
      SignInFailure('The email or password is incorrect.'),
    ],
    verify: (_) {
      verify(
        () => signInUseCase.execute(
          email: 'passenger@example.com',
          password: ' password-with-spaces ',
        ),
      ).called(1);
    },
  );
}
