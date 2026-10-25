import 'package:bloc_test/bloc_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/reset_password_confirm/reset_password_confirm_bloc.dart';

class _AuthRepository extends Mock implements AuthRepository {}

void main() {
  final repository = _AuthRepository();
  blocTest<ResetPasswordConfirmBloc, ResetPasswordConfirmState>(
    'resends the password reset code through the repository',
    build: () {
      when(() => repository.resetPassword(email: 'person@example.com'))
          .thenAnswer((_) async => const Ok(null));
      return ResetPasswordConfirmBloc(repository);
    },
    act: (bloc) =>
        bloc.add(const ResetPasswordCodeRequested(' Person@Example.com ')),
    expect: () => const [ResetPasswordCodeResending(), ResetPasswordCodeSent()],
  );
}
