import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/place.dart';
import 'api_config.dart';

class TourApiException implements Exception {
  const TourApiException(this.message, {this.code});

  final String message;
  final String? code;
}

class TourApiService {
  TourApiService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8);

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String> query = const {},
  ]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    try {
      final request = await _client
          .getUrl(uri)
          .timeout(const Duration(seconds: 8));
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final content = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 12));
      final data = jsonDecode(content) as Map<String, dynamic>;
      if (response.statusCode != HttpStatus.ok) {
        final detail = data['detail'];
        if (detail is Map<String, dynamic>) {
          throw TourApiException(
            detail['message'] as String? ?? '관광정보를 가져오지 못했어요.',
            code: detail['code'] as String?,
          );
        }
        throw const TourApiException('관광정보를 가져오지 못했어요.');
      }
      return data;
    } on TourApiException {
      rethrow;
    } on SocketException {
      throw const TourApiException('서버에 연결할 수 없어요. 서버 실행 상태를 확인해 주세요.');
    } on TimeoutException {
      throw const TourApiException('응답이 지연되고 있어요. 잠시 뒤 다시 시도해 주세요.');
    } on FormatException {
      throw const TourApiException('서버 응답을 읽을 수 없어요.');
    } on HttpException {
      throw const TourApiException('서버 통신에 실패했어요.');
    }
  }

  Future<PlacePage> getPlaces({int page = 1}) async {
    final data = await _get('/api/places', {'page': '$page', 'limit': '20'});
    return PlacePage.fromJson(data);
  }

  Future<PlaceDetail> getPlace(String id) async {
    final data = await _get('/api/places/${Uri.encodeComponent(id)}');
    return PlaceDetail.fromJson(data);
  }
}
