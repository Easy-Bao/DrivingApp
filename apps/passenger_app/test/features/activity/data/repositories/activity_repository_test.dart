import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/activity/data/repositories/activity_repository.dart';
import 'package:passenger_app/src/features/trip/data/datasources/passenger_remote_data_source.dart';
import 'package:shared_core/shared_core.dart';

class MockPassengerRemoteDataSource extends Mock
    implements PassengerRemoteDataSource {}

void main() {
  late MockPassengerRemoteDataSource remoteDataSource;
  late ActivityRepository repository;

  setUp(() {
    remoteDataSource = MockPassengerRemoteDataSource();
    repository = ActivityRepository(
      passengerRemoteDataSource: remoteDataSource,
    );
  });

  test(
    'maps unauthorized responses to a safe authentication failure',
    () async {
      final request = RequestOptions(
        path: '/api/v1/passengers/private-id/rides',
      );
      when(() => remoteDataSource.fetchRideHistory('private-id')).thenThrow(
        DioException(
          requestOptions: request,
          response: Response<Object?>(requestOptions: request, statusCode: 401),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.fetchRideHistory('private-id');

      result.fold((failure) {
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('Sign in again'));
        expect(failure.message, isNot(contains('DioException')));
        expect(failure.message, isNot(contains('401')));
        expect(failure.message, isNot(contains('private-id')));
      }, (_) => fail('Expected an authentication failure.'));
    },
  );

  test('does not expose unexpected exception diagnostics', () async {
    when(
      () => remoteDataSource.fetchRideHistory('passenger-1'),
    ).thenThrow(StateError('database-password-leak'));

    final result = await repository.fetchRideHistory('passenger-1');

    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(
        failure.message,
        'Activity is temporarily unavailable. Please try again.',
      );
      expect(failure.message, isNot(contains('database-password-leak')));
    }, (_) => fail('Expected a server failure.'));
  });
}
