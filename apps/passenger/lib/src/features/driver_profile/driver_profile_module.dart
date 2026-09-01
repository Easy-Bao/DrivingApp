import 'package:dio/dio.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/features/driver_profile/data/data_sources/driver_profile_remote_data_source.dart';
import 'package:passenger/src/features/driver_profile/data/repositories/driver_profile_repository_impl.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';

class DriverProfileModule {
  DriverProfileModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<DriverProfileRemoteDataSource>(
        (i) => DriverProfileRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<DriverProfileRepository>(
        (i) => DriverProfileRepositoryImpl(
          dataSource: i.get<DriverProfileRemoteDataSource>(),
        ),
      );
  }
}
