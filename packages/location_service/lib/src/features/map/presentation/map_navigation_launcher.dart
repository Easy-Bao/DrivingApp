import 'package:map_launcher/map_launcher.dart';

class MapNavigationLauncher {
  MapNavigationLauncher._();

  static Future<List<AvailableMap>> getInstalledMaps() async {
    try {
      return await MapLauncher.installedMaps;
    } catch (_) {
      return [];
    }
  }

  static Future<bool> launchNavigation({
    required double latitude,
    required double longitude,
    required String title,
    MapType? mapType,
  }) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;
      if (availableMaps.isEmpty) return false;

      final targetMap = mapType != null
          ? availableMaps.firstWhere(
              (m) => m.mapType == mapType,
              orElse: () => availableMaps.first,
            )
          : availableMaps.first;

      await targetMap.showDirections(
        destination: Coords(latitude, longitude),
        destinationTitle: title,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
