import 'package:core_models/core_models.dart';
import 'package:dio/dio.dart';

abstract class BiddingRemoteDataSource {
  Future<Map<String, dynamic>> requestRide(Map<String, dynamic> body);
  Future<Map<String, dynamic>> getSession(String sessionId);
  Future<List<dynamic>> fetchOffers(String sessionId);
  Future<Map<String, dynamic>> acceptOffer({
    required String sessionId,
    required String offerId,
  });
  Future<bool> cancelSession(String sessionId);
  Future<Map<String, dynamic>> fetchDriverStats(String driverId);
  Future<List<dynamic>> fetchDriverReviews(
    String driverId, {
    int? page,
    int? limit,
  });
  Future<List<dynamic>> fetchOnlineDrivers();
  Future<Map<String, dynamic>> fetchDriverLocation(String driverId);
  Future<Map<String, dynamic>> getDriverProfile(String driverId);
  Future<Map<String, dynamic>> getRideStatus(String rideId);
  Future<Map<String, dynamic>> submitDriverReview({
    required String driverId,
    required String passengerName,
    required double rating,
    required String comment,
  });
  Future<bool> updateRideStatus(String rideId, String status);
  String? takeLastPublicError();
}

class BiddingRemoteDataSourceImpl implements BiddingRemoteDataSource {
  BiddingRemoteDataSourceImpl(this._dio);

  final Dio _dio;
  String? _lastPublicError;

  @override
  String? takeLastPublicError() {
    final error = _lastPublicError;
    _lastPublicError = null;
    return error;
  }

  @override
  Future<Map<String, dynamic>> requestRide(Map<String, dynamic> body) =>
      _mapRequest(() => _dio.post<Map<String, dynamic>>('/bids', data: body));

  @override
  Future<Map<String, dynamic>> getSession(String sessionId) =>
      _mapRequest(() => _dio.get<Map<String, dynamic>>('/bids/$sessionId'));

  @override
  Future<List<dynamic>> fetchOffers(String sessionId) =>
      _listRequest(() => _dio.get<List<dynamic>>('/bids/$sessionId/offers'));

  @override
  Future<Map<String, dynamic>> acceptOffer({
    required String sessionId,
    required String offerId,
  }) => _mapRequest(
    () => _dio.post<Map<String, dynamic>>(
      '/bids/$sessionId/accept',
      data: {'offer_id': offerId},
    ),
  );

  @override
  Future<bool> cancelSession(String sessionId) =>
      _boolRequest(() => _dio.delete<Map<String, dynamic>>('/bids/$sessionId'));

  @override
  Future<Map<String, dynamic>> fetchDriverStats(String driverId) => _mapRequest(
    () => _dio.get<Map<String, dynamic>>('/drivers/$driverId/stats'),
  );

  @override
  Future<List<dynamic>> fetchDriverReviews(
    String driverId, {
    int? page,
    int? limit,
  }) => _listRequest(
    () => _dio.get<List<dynamic>>(
      '/drivers/$driverId/reviews',
      queryParameters: {
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    ),
  );

  @override
  Future<List<dynamic>> fetchOnlineDrivers() =>
      _listRequest(() => _dio.get<List<dynamic>>('/drivers/online'));

  @override
  Future<Map<String, dynamic>> fetchDriverLocation(String driverId) =>
      _mapRequest(
        () => _dio.get<Map<String, dynamic>>('/telemetry/location/$driverId'),
      );

  @override
  Future<Map<String, dynamic>> getDriverProfile(String driverId) =>
      _mapRequest(() => _dio.get<Map<String, dynamic>>('/drivers/$driverId'));

  @override
  Future<Map<String, dynamic>> getRideStatus(String rideId) =>
      _mapRequest(() => _dio.get<Map<String, dynamic>>('/rides/$rideId'));

  @override
  Future<Map<String, dynamic>> submitDriverReview({
    required String driverId,
    required String passengerName,
    required double rating,
    required String comment,
  }) => _mapRequest(
    () => _dio.post<Map<String, dynamic>>(
      '/drivers/$driverId/reviews',
      data: {
        'passengerName': passengerName,
        'rating': rating,
        'comment': comment,
      },
    ),
  );

  @override
  Future<bool> updateRideStatus(String rideId, String status) => _boolRequest(
    () => _dio.post<Map<String, dynamic>>(
      '/rides/$rideId/status',
      data: {'status': status},
    ),
  );

  Future<Map<String, dynamic>> _mapRequest(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    final response = await _request(request);
    return response.data ?? <String, dynamic>{};
  }

  Future<List<dynamic>> _listRequest(
    Future<Response<List<dynamic>>> Function() request,
  ) async {
    final response = await _request(request);
    return response.data ?? <dynamic>[];
  }

  Future<bool> _boolRequest(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    await _request(request);
    return true;
  }

  Future<Response<T>> _request<T>(
    Future<Response<T>> Function() request,
  ) async {
    _lastPublicError = null;
    try {
      return await request();
    } on DioException catch (error) {
      final message = _errorMessage(error.response?.data);
      _lastPublicError = message;
      throw ServerException(
        statusCode: error.response?.statusCode ?? 500,
        message: message,
      );
    }
  }
}

String? acceptedRideId(Map<String, dynamic>? response) {
  if (response == null) return null;
  final value =
      response['rideId'] ??
      response['accepted_trip_id'] ??
      response['ride_id'] ??
      (response['session'] is Map
          ? (response['session'] as Map)['accepted_trip_id']
          : null);
  return value is String && value.isNotEmpty ? value : null;
}

String passengerRideErrorMessage(String? codeOrMessage) {
  final code = (codeOrMessage ?? '').toUpperCase();
  if (code.contains('ACCOUNT_RESTRICTED')) {
    return 'Your account is restricted. You can still view your ride history, but you cannot request a ride. Contact support for help.';
  }
  if (code.contains('OUTSIDE_SERVICE_ZONE')) {
    return 'Choose a pickup and destination inside an active EasyRide service barangay in Pagadian City.';
  }
  if (code.contains('SERVICE_ZONE_NOT_CONFIGURED')) {
    return 'Ride booking is not open yet because the pilot service area has not been activated. Please try again later.';
  }
  if (code.contains('DRIVER_NOT_APPROVED')) {
    return 'The selected driver is not approved to take rides. Choose another driver.';
  }
  if (code.contains('DRIVER_DOCUMENTS_INCOMPLETE')) {
    return 'The selected driver is unavailable because required documents are incomplete, rejected, or expired. Choose another driver.';
  }
  if (code.contains('INSUFFICIENT_CREDIT')) {
    return 'The selected driver does not have enough service credit for this ride. Choose another driver.';
  }
  return codeOrMessage?.isNotEmpty == true
      ? codeOrMessage!
      : 'Unable to request a ride. Please try again.';
}

String _errorMessage(dynamic data) {
  if (data is Map) {
    final error = data['error'];
    if (error is Map) {
      return error['code']?.toString() ??
          error['message']?.toString() ??
          'Server error';
    }
    return data['code']?.toString() ??
        data['message']?.toString() ??
        error?.toString() ??
        'Server error';
  }
  return data?.toString() ?? 'Server error';
}
