import 'package:dio/dio.dart';

abstract class BiddingRemoteDataSource {
  Future<Map<String, dynamic>> requestRide(Map<String, dynamic> body);
  Future<List<dynamic>> fetchOffers(String sessionId);
  Future<bool> acceptOffer({required String sessionId, required String offerId});
  Future<bool> cancelSession(String sessionId);
  Future<Map<String, dynamic>> fetchDriverStats(String driverId);
  Future<List<dynamic>> fetchDriverReviews(String driverId, {int? page, int? limit});
}

class BiddingRemoteDataSourceImpl implements BiddingRemoteDataSource {
  final Dio _dio;

  BiddingRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> requestRide(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>('/bids/session', data: body);
    return response.data ?? {};
  }

  @override
  Future<List<dynamic>> fetchOffers(String sessionId) async {
    final response = await _dio.get<List<dynamic>>('/bids/session/$sessionId/offers');
    return response.data ?? [];
  }

  @override
  Future<bool> acceptOffer({required String sessionId, required String offerId}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/bids/session/$sessionId/accept',
      data: {'offer_id': offerId},
    );
    return response.statusCode == 200;
  }

  @override
  Future<bool> cancelSession(String sessionId) async {
    final response = await _dio.post<Map<String, dynamic>>('/bids/session/$sessionId/cancel');
    return response.statusCode == 200;
  }

  @override
  Future<Map<String, dynamic>> fetchDriverStats(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>('/drivers/$driverId/stats');
    return response.data ?? {};
  }

  @override
  Future<List<dynamic>> fetchDriverReviews(String driverId, {int? page, int? limit}) async {
    final response = await _dio.get<List<dynamic>>(
      '/drivers/$driverId/reviews',
      queryParameters: {
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    );
    return response.data ?? [];
  }
}

