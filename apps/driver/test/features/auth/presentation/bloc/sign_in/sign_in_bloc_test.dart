import 'package:bloc_test/bloc_test.dart';
import 'package:driver/src/features/auth/domain/failures/auth_failures.dart';
import 'package:driver/src/features/auth/domain/repositories/driver_auth_repository.dart';
import 'package:driver/src/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDriverAuthRepository extends Mock implements DriverAuthRepository {}

void main() {
  late _MockDriverAuthRepository authRepository;

  setUp(() {
    authRepository = _MockDriverAuthRepository();
  });

  blocTest<SignInBloc, SignInState>(
    'shows a credential error instead of a session-expired message',
    setUp: () {
      when(
        () => authRepository.authenticate(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(InvalidCredentialsFailure()));
    },
    build: () => SignInBloc(authRepository),
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
        () => authRepository.authenticate(
          email: 'passenger@example.com',
          password: ' password-with-spaces ',
        ),
      ).called(1);
    },
  );
}
