import 'package:dio/dio.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/driver_profile/data/datasources/driver_profile_remote_data_source.dart';
import 'package:passenger_app/src/features/driver_profile/data/repositories/driver_profile_repository.dart';
import 'package:passenger_app/src/features/driver_profile/domain/repositories/i_driver_profile_repository.dart';

class DriverProfileModule {
  DriverProfileModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<DriverProfileRemoteDataSource>(
        (i) => DriverProfileRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<IDriverProfileRepository>(
        (i) => DriverProfileRepository(
          dataSource: i.get<DriverProfileRemoteDataSource>(),
        ),
      );
  }
}
