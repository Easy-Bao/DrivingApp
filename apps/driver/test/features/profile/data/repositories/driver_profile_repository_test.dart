import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:driver/src/features/profile/data/data_sources/driver_profile_remote_data_source.dart';
import 'package:driver/src/features/profile/data/repositories/driver_profile_repository_impl.dart';
import 'package:driver/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockProfileDataSource extends Mock
    implements DriverProfileRemoteDataSource {}

class _MockSessionService extends Mock implements DriverSessionStore {}

void main() {
  test(
    'loads profile data without coupling account refresh to statistics',
    () async {
      SharedPreferences.setMockInitialValues({
        'driver_name': 'Cached Driver',
        'driver_phone': '+639170000001',
        'driver_email': 'cached@example.com',
      });
      final preferences = await SharedPreferences.getInstance();
      final profileDataSource = _MockProfileDataSource();
      final sessionService = _MockSessionService();
      when(() => sessionService.readDriverId())
          .thenAnswer((_) async => 'driver-42');
      when(() => profileDataSource.fetchProfile('driver-42')).thenAnswer(
        (_) async => const {
          'name': 'Remote Driver',
          'phone': '+639170000002',
          'email': 'remote@example.com',
          'vehicle_type': 'Motorcycle',
          'plate_number': 'XYZ-123',
        },
      );

      final repository = DriverProfileRepositoryImpl(
        profileDataSource: profileDataSource,
        sessionService: sessionService,
        preferences: preferences,
      );

      final result = await repository.refreshAccount();

      result.fold((failure) => fail('Expected profile data, got $failure.'), (
        account,
      ) {
        expect(account.name, 'Remote Driver');
        expect(account.phone, '+639170000002');
        expect(account.vehicleType, 'Motorcycle');
        expect(account.totalTrips, 0);
        expect(account.lifetimeEarnings, 0);
      });
    },
  );

  test('updates profile fields without posting contact identifiers', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final profileDataSource = _MockProfileDataSource();
    when(
      () => profileDataSource.updateProfile(
        data: any<Map<String, dynamic>>(named: 'data'),
      ),
    ).thenAnswer((_) async => const {'name': 'Updated Driver'});

    final repository = DriverProfileRepositoryImpl(
      profileDataSource: profileDataSource,
      sessionService: _MockSessionService(),
      preferences: preferences,
    );
    final currentAccount = const DriverAccountSnapshot(
      name: 'Driver',
      phone: '+639170000001',
      email: 'driver@example.com',
      vehicleType: 'Motorcycle',
      plateNumber: 'ABC-123',
    );

    final result = await repository.updateAccount(
      currentAccount: currentAccount,
      name: 'Updated Driver',
      vehicleType: 'Motorcycle',
      plateNumber: 'ABC-123',
    );

    result.fold((failure) => fail('profile update failed: $failure'), (
      account,
    ) {
      expect(account.phone, currentAccount.phone);
      expect(account.email, currentAccount.email);
    });
    final updatePayload =
        verify(
              () => profileDataSource.updateProfile(
                data: captureAny<Map<String, dynamic>>(named: 'data'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(updatePayload, {
      'name': 'Updated Driver',
      'vehicle_type': 'Motorcycle',
      'plate_number': 'ABC-123',
    });
  });
}
