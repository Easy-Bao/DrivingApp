import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/Features/Settings/Domain/Entities/UserSettings.dart';

abstract class SettingsRepository {
  Future<Either<Failure, UserSettings>> fetchUserSettings();
  Future<Either<Failure, void>> updateUserSettings(UserSettings settings);
}
