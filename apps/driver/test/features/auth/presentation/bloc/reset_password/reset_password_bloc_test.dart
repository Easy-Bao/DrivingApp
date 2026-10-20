import 'package:driver/src/features/auth/domain/repositories/driver_auth_repository.dart';
import 'package:driver/src/features/auth/presentation/bloc/reset_password/reset_password_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUp(() => repository = _MockAuthRepository());

  Future<List<ResetPasswordState>> run(ResetPasswordSubmitted event) async {
    final bloc = ResetPasswordBloc(repository);
    final states = <ResetPasswordState>[];
    final subscription = bloc.stream.listen(states.add);
    bloc.add(event);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();
    await bloc.close();
    return states;
  }

  test('submits the emailed code and new password', () async {
    when(
      () => repository.confirmPasswordReset(
        email: 'driver@example.com',
        code: '123456',
        newPassword: 'new-password',
      ),
    ).thenAnswer((_) async => const Ok(null));

    final states = await run(
      const ResetPasswordSubmitted(
        email: ' Driver@Example.com ',
        code: ' 123456 ',
        newPassword: 'new-password',
      ),
    );

    expect(states, const [ResetPasswordLoading(), ResetPasswordSuccess()]);
  });

  test('rejects a short password without calling the server', () async {
    final states = await run(
      const ResetPasswordSubmitted(
        email: 'driver@example.com',
        code: '123456',
        newPassword: 'short',
      ),
    );

    expect(states.single, isA<ResetPasswordFailure>());
    verifyNever(
      () => repository.confirmPasswordReset(
        email: any(named: 'email'),
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    );
  });

  test('reports a rejected code', () async {
    when(
      () => repository.confirmPasswordReset(
        email: any(named: 'email'),
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async => const Err(ServerFailure('Invalid code')));

    final states = await run(
      const ResetPasswordSubmitted(
        email: 'driver@example.com',
        code: '000000',
        newPassword: 'new-password',
      ),
    );

    expect(states.first, const ResetPasswordLoading());
    expect(states.last, isA<ResetPasswordFailure>());
  });
}
