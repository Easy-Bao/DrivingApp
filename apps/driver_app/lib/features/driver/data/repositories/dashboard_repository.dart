import 'package:core_models/core_models.dart';
import 'package:fixtures/fixtures.dart';

//TODO: Replace with real API implementation once backend endpoints are ready and integrated.

class MockDashboardRepository implements DashboardRepository {
  @override
  Future<double> getTodayEarnings() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return MockData.todayEarnings;
  }

  @override
  Future<int> getTodayTrips() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockData.todayTrips;
  }

  @override
  Future<double> getHoursOnline() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockData.hoursOnline;
  }

  @override
  Future<List<HeatmapCell>> getSurgeHeatmap({
    required double lat,
    required double lng,
    required int gridSize,
    required double cellSize,
    required List<double> requestLats,
    required List<double> requestLngs,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MockData.getSurgeHeatmapOffsets()
        .map(
          (o) => HeatmapCell(
            lat: lat + (o['latOffset'] ?? 0.0),
            lng: lng + (o['lngOffset'] ?? 0.0),
            intensity: o['intensity'] ?? 0.0,
          ),
        )
        .toList();
  }
}

//TODO: Implement the real API repository once backend endpoints are ready and integrated.

// ignore: unused_element — will be used when backend is integrated
class _ApiDashboardRepository implements DashboardRepository {
  // final HttpClient _httpClient;
  // ApiDashboardRepository(this._httpClient);

  @override
  Future<double> getTodayEarnings() async {
    // final response = await _httpClient.get('/driver/earnings/today');
    // return (response.data['earnings'] as num).toDouble();
    throw UnimplementedError('Backend not yet integrated');
  }

  @override
  Future<int> getTodayTrips() async {
    // final response = await _httpClient.get('/driver/trips/today');
    // return response.data['count'] as int;
    throw UnimplementedError('Backend not yet integrated');
  }

  @override
  Future<double> getHoursOnline() async {
    // final response = await _httpClient.get('/driver/hours-online/today');
    // return (response.data['hours'] as num).toDouble();
    throw UnimplementedError('Backend not yet integrated');
  }

  @override
  Future<List<HeatmapCell>> getSurgeHeatmap({
    required double lat,
    required double lng,
    required int gridSize,
    required double cellSize,
    required List<double> requestLats,
    required List<double> requestLngs,
  }) async {
    // final response = await _httpClient.post('/map/surge', body: {...});
    // return (response.data['cells'] as List).map(HeatmapCell.fromJson).toList();
    throw UnimplementedError('Backend not yet integrated');
  }
}
