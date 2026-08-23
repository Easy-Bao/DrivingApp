import 'package:dio/dio.dart';

abstract class BookingRemoteDataSource {
  Future<Map<String, dynamic>> createSession(Map<String, dynamic> body);

  Future<List<dynamic>> fetchOffers(String sessionId);

  Future<Map<String, dynamic>> acceptOffer({
    required String sessionId,
    required String offerId,
  });

  Future<bool> cancelSession(String sessionId);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final Dio _dio;

  BookingRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> createSession(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bids',
      data: body,
    );
    return response.data ?? const <String, dynamic>{};
  }

  @override
  Future<List<dynamic>> fetchOffers(String sessionId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/bids/${Uri.encodeComponent(sessionId)}/offers',
    );
    return response.data ?? const <dynamic>[];
  }

  @override
  Future<Map<String, dynamic>> acceptOffer({
    required String sessionId,
    required String offerId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bids/${Uri.encodeComponent(sessionId)}/offers/'
      '${Uri.encodeComponent(offerId)}/accept',
      data: {'offer_id': offerId},
    );
    return response.data ?? const <String, dynamic>{};
  }

  @override
  Future<bool> cancelSession(String sessionId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bids/${Uri.encodeComponent(sessionId)}/cancel',
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
