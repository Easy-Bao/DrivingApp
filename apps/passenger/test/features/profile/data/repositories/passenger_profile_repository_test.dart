import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/domain/failures/auth_failures.dart';
import 'package:passenger/src/features/profile/data/data_sources/passenger_profile_remote_data_source.dart';
import 'package:passenger/src/features/profile/data/repositories/passenger_profile_repository_impl.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPassengerProfileRemoteDataSource extends Mock
    implements PassengerProfileRemoteDataSource {}

class MockSecureSessionService extends Mock implements PassengerSessionStore {}

void main() {
  test('uploads a newly selected avatar as part of profile save', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final remoteDataSource = MockPassengerProfileRemoteDataSource();
    final sessionService = MockSecureSessionService();
    final avatarFile = File(
      '${Directory.systemTemp.path}/passenger-profile-test.png',
    );
    const avatarBytes = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    await avatarFile.writeAsBytes(avatarBytes);
    addTearDown(() async {
      if (await avatarFile.exists()) await avatarFile.delete();
    });

    when(() => sessionService.readPassengerId()).thenAnswer((_) async => '42');
    when(
      () => remoteDataSource.uploadProfileAvatar(
        passengerId: any(named: 'passengerId'),
        bytes: any<List<int>>(named: 'bytes'),
        fileName: any(named: 'fileName'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => remoteDataSource.updateProfile(
        passengerId: any(named: 'passengerId'),
        data: any<Map<String, dynamic>>(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => const {
        'id': 7,
        'user_id': 42,
        'name': 'Updated Passenger',
        'phone': '+639170000001',
        'email': 'passenger@example.com',
        'gender': 'Female',
        'avatar_url': '/api/v1/passengers/42/avatar',
      },
    );

    final repository = PassengerProfileRepositoryImpl(
      remoteDataSource: remoteDataSource,
      sessionService: sessionService,
      preferences: preferences,
    );
    final result = await repository.updateProfile(
      name: 'Updated Passenger',
      phone: '+639170000001',
      email: 'passenger@example.com',
      address: '',
      gender: 'Female',
      avatarPath: avatarFile.path,
    );

    result.fold((failure) => fail('profile save failed: ${failure.message}'), (
      profile,
    ) {
      expect(profile.avatarPath, avatarFile.path);
      expect(profile.avatarData, isNotEmpty);
      expect(profile.avatarUrl, '/api/v1/passengers/42/avatar');
    });
    verify(
      () => remoteDataSource.uploadProfileAvatar(
        passengerId: '42',
        bytes: avatarBytes,
        fileName: 'passenger-profile-test.png',
      ),
    ).called(1);
  });

  test(
    'keeps forbidden profile responses separate from session expiry',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final remoteDataSource = MockPassengerProfileRemoteDataSource();
      final sessionService = MockSecureSessionService();
      final request = RequestOptions(path: '/api/v1/passengers/42');

      when(() => sessionService.readPassengerId())
          .thenAnswer((_) async => '42');
      when(
        () => remoteDataSource.updateProfile(
          passengerId: '42',
          data: any<Map<String, dynamic>>(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: request,
          response: Response<Object?>(requestOptions: request, statusCode: 403),
          type: DioExceptionType.badResponse,
        ),
      );

      final repository = PassengerProfileRepositoryImpl(
        remoteDataSource: remoteDataSource,
        sessionService: sessionService,
        preferences: preferences,
      );
      final result = await repository.updateProfile(
        name: 'Passenger',
        phone: '+639170000001',
        email: 'passenger@example.com',
        address: '',
        gender: 'Female',
        avatarPath: '',
      );

      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure, isNot(isA<AuthFailure>()));
        expect(
          failure.message,
          'You do not have permission to view or update your profile.',
        );
        expect((failure as ServerFailure).statusCode, 403);
      }, (_) => fail('Expected a permission failure.'));
    },
  );
}
