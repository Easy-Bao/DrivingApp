import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/settings/domain/entities/user_settings.dart';
import 'package:shared_core/shared_core.dart';

abstract class ISettingsRepository {
  Future<Either<Failure, UserSettings>> fetchUserSettings();
  Future<Either<Failure, void>> updateUserSettings(UserSettings settings);
}
