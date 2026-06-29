/**
 * Centralized mock data registry for the DrivingApp workspace.
 *
 * This utility class houses structured geographical, category, and personnel
 * data models represented as simple, JSON-compatible Dart maps and lists. 
 * Isolating these mock definitions within `fixtures` makes them reusable across
 * both driver and passenger applications, establishing a unified interface that
 * can be swapped directly for live HTTP/WebSocket backend endpoints at a later stage.
 *
 * **Data Shape & Schemas:**
 * The values returned by the methods in this class follow standard schema formats:
 * * Recent locations are maps containing `title`, `subtitle`, `lat`, and `lng`.
 * * Shortcuts are maps containing `label` and `iconName` (a string mapping to UI icons).
 * * Quick actions are maps containing `title`, `subtitle`, and `iconName`.
 * * Nearby drivers include properties like `id`, `name`, `vehicleType`, `plateNumber`,
 *   `rating`, `lat`, `lng`, `distanceKm`, `etaMinutes`, and `score`.
 */
class MockData {
  MockData._();

  /**
   * Default fallback latitude centering on Pagadian City.
   */
  static const double defaultLat = 7.8286;

  /**
   * Default fallback longitude centering on Pagadian City.
   */
  static const double defaultLng = 123.4361;

  /**
   * Default address descriptor matched with the default coordinate set.
   */
  static const String defaultAddress = 'Pagadian City, Zamboanga del Sur';

  /**
   * Returns a collection of pre-defined recent locations visited by the passenger.
   */
  static List<Map<String, dynamic>> getRecentLocations() {
    return [
      {
        'title': 'Plaza Luz',
        'subtitle': 'San Francisco',
        'lat': 7.8275,
        'lng': 123.4365,
      },
      {
        'title': 'Robinson Supermarket',
        'subtitle': 'San Francisco',
        'lat': 7.8250,
        'lng': 123.4380,
      },
      {
        'title': "Bo's Coffee",
        'subtitle': 'San Francisco',
        'lat': 7.8295,
        'lng': 123.4358,
      },
      {
        'title': 'Gaisano Capital',
        'subtitle': 'San Francisco',
        'lat': 7.8260,
        'lng': 123.4355,
      },
    ];
  }

  /**
   * Returns the default shortcut category destinations for the quick actions bar.
   */
  static List<Map<String, String>> getDefaultShortcuts() {
    return [
      {
        'label': 'Home',
        'iconName': 'house',
      },
      {
        'label': 'Campus',
        'iconName': 'graduation_cap',
      },
      {
        'label': 'Work',
        'iconName': 'briefcase',
      },
    ];
  }

  /**
   * Returns active quick action product types shown on the home page dashboard.
   */
  static List<Map<String, String>> getQuickActions() {
    return [
      {
        'title': 'Solo Ride',
        'subtitle': 'Direct booking',
        'iconName': 'bike',
      },
      {
        'title': 'Share-Bao',
        'subtitle': 'Pasabay',
        'iconName': 'users',
      },
    ];
  }

  /**
   * Generates a dynamic set of nearby driver positions relative to the passenger's current coordinates.
   */
  static List<Map<String, dynamic>> getNearbyDrivers({
    required double lat,
    required double lng,
  }) {
    return [
      {
        'id': 'drv_001',
        'name': 'Xyrel T.',
        'vehicleType': 'Motorcycle',
        'plateNumber': 'ZDN-1234',
        'rating': 4.9,
        'lat': lat + 0.003,
        'lng': lng - 0.002,
        'distanceKm': 0.42,
        'etaMinutes': 2,
        'score': 0.95,
      },
      {
        'id': 'drv_002',
        'name': 'Marco D.',
        'vehicleType': 'Motorcycle',
        'plateNumber': 'ZDN-5678',
        'rating': 4.7,
        'lat': lat - 0.004,
        'lng': lng + 0.003,
        'distanceKm': 0.88,
        'etaMinutes': 4,
        'score': 0.82,
      },
    ];
  }

  /**
   * Generates a straight-line interpolation of coordinates between two positions.
   */
  static List<List<double>> interpolateRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return List.generate(5, (i) {
      final t = i / 4;
      return [
        startLng + (endLng - startLng) * t,
        startLat + (endLat - startLat) * t,
      ];
    });
  }

  /**
   * Mock data for driver dashboard earnings.
   */
  static const double todayEarnings = 385.50;

  /**
   * Mock data for driver dashboard trip count.
   */
  static const int todayTrips = 7;

  /**
   * Mock data for driver dashboard online hours.
   */
  static const double hoursOnline = 4.5;

  /**
   * Returns mock surge heatmap cells offsets and intensities.
   */
  static List<Map<String, double>> getSurgeHeatmapOffsets() {
    return [
      {'latOffset': 0.002, 'lngOffset': -0.002, 'intensity': 2.5},
      {'latOffset': -0.001, 'lngOffset': 0.003, 'intensity': 1.8},
      {'latOffset': 0.005, 'lngOffset': 0.001, 'intensity': 3.1},
    ];
  }

  /**
   * Mock fare calculation constants.
   */
  static const double fareBase = 40.0;
  static const double fareDistanceRate = 8.0;
  static const double fareTimeRate = 1.0;
  static const double fareSurge = 0.0;
  static const double optimizedDistanceKm = 5.2;

  /**
   * Returns a static pool of driver profiles used for matching simulation.
   */
  static List<Map<String, dynamic>> getDriverPool() {
    return [
      {
        'id': 'drv_01',
        'name': 'Melvin Perez',
        'vehicleType': 'Habal-Habal Motorcycle',
        'plateNumber': '987-PHP',
        'rating': 4.9,
      },
      {
        'id': 'drv_02',
        'name': 'Jerry Maglasang',
        'vehicleType': 'Premium BaoBao Trike',
        'plateNumber': '321-XYZ',
        'rating': 4.7,
      },
      {
        'id': 'drv_03',
        'name': 'Ramil Sombilon',
        'vehicleType': 'Standard Trike',
        'plateNumber': '555-ABC',
        'rating': 4.5,
      },
      {
        'id': 'drv_04',
        'name': 'Crisanto Caboverde',
        'vehicleType': 'Habal-Habal Motorcycle',
        'plateNumber': '888-BAO',
        'rating': 4.8,
      },
      {
        'id': 'drv_05',
        'name': 'Junrey Tugahan',
        'vehicleType': 'Premium BaoBao Trike',
        'plateNumber': '777-RIDE',
        'rating': 4.6,
      },
    ];
  }
}

