import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/domain/failures/auth_failures.dart';
import 'package:passenger/src/features/driver_profile/data/data_sources/driver_profile_remote_data_source.dart';
import 'package:passenger/src/features/driver_profile/data/repositories/driver_profile_repository_impl.dart';

class MockDriverProfileRemoteDataSource extends Mock
    implements DriverProfileRemoteDataSource {}

void main() {
  test(
    'keeps forbidden driver profile responses separate from session expiry',
    () async {
      final dataSource = MockDriverProfileRemoteDataSource();
      final request = RequestOptions(path: '/api/v1/drivers/driver-1/stats');
      when(() => dataSource.fetchStats('driver-1')).thenThrow(
        DioException(
          requestOptions: request,
          response: Response<Object?>(requestOptions: request, statusCode: 403),
          type: DioExceptionType.badResponse,
        ),
      );

      final repository = DriverProfileRepositoryImpl(dataSource: dataSource);
      final result = await repository.fetchStats('driver-1');

      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure, isNot(isA<AuthFailure>()));
        expect(
          failure.message,
          'You do not have permission to access driver profiles.',
        );
        expect((failure as ServerFailure).statusCode, 403);
      }, (_) => fail('Expected a permission failure.'));
    },
  );
}
