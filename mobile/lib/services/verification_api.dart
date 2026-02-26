import 'package:dio/dio.dart';

import '../core/network/api_dio.dart';
import 'api_config.dart';
import 'dio_proxy.dart';

class VerificationApi {
  final Dio _dio;

  VerificationApi({Dio? dio}) : _dio = dio ?? ApiDio.dio {
    configureDioForLocalhost(_dio, ApiConfig.baseUrl);
  }

  Future<Map<String, dynamic>> createRequest({required String badgeType}) async {
    final res = await _dio.post(
      '${ApiConfig.apiPrefix}/verification/requests/create/',
      data: {'badge_type': badgeType},
    );
    return _asMap(res.data);
  }

  Future<List<Map<String, dynamic>>> getMyRequests() async {
    final res = await _dio.get('${ApiConfig.apiPrefix}/verification/requests/my/');
    return _extractList(res.data).map((e) => _asMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getBackofficeRequests({
    String? status,
    String? q,
  }) async {
    final res = await _dio.get(
      '${ApiConfig.apiPrefix}/verification/backoffice/requests/',
      queryParameters: {
        if ((status ?? '').trim().isNotEmpty) 'status': status,
        if ((q ?? '').trim().isNotEmpty) 'q': q,
      },
    );
    return _extractList(res.data).map((e) => _asMap(e)).toList();
  }

  Future<Map<String, dynamic>> getRequestDetail(int requestId) async {
    final res = await _dio.get('${ApiConfig.apiPrefix}/verification/requests/$requestId/');
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> backofficeAssign({
    required int requestId,
    int? assignedToUserId,
  }) async {
    final res = await _dio.patch(
      '${ApiConfig.apiPrefix}/verification/backoffice/requests/$requestId/assign/',
      data: {
        'assigned_to': assignedToUserId,
      },
    );
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> backofficeFinalize({
    required int requestId,
  }) async {
    final res = await _dio.post(
      '${ApiConfig.apiPrefix}/verification/backoffice/requests/$requestId/finalize/',
    );
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> addDocument({
    required int requestId,
    required String filePath,
    required String docType,
    String? title,
  }) async {
    final formData = FormData.fromMap({
      'doc_type': docType,
      if ((title ?? '').trim().isNotEmpty) 'title': title,
      'file': await MultipartFile.fromFile(filePath),
    });

    final res = await _dio.post(
      '${ApiConfig.apiPrefix}/verification/requests/$requestId/documents/',
      data: formData,
    );
    return _asMap(res.data);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final map = _asMap(data);
      final results = map['results'];
      if (results is List) return results;
      final items = map['items'];
      if (items is List) return items;
      final payload = map['data'];
      if (payload is List) return payload;
    }
    return const [];
  }
}
