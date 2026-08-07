import 'package:passenger_app/src/core/routing/app_routes.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_state.dart';
import 'package:passenger_app/src/features/location/location_routes.dart';

String? locationAccessDestinationName({
  required String currentPath,
  required LocationAccessViewState accessState,
}) {
  return switch (accessState) {
    LocationAccessReady() when currentPath == LocationRoutes.fullGatePath =>
      HomeRoutes.home,
    LocationAccessUnavailable(isPromptSuppressed: false)
        when currentPath.startsWith(AppRoutes.passengerModulePath) &&
            currentPath != LocationRoutes.fullGatePath =>
      LocationRoutes.gate,
    _ => null,
  };
}
