/// خدمة المحتوى العام — /api/content/*
library;

import 'api_client.dart';

class ContentService {
  // ─── In-memory cache (TTL = 5 دقائق) ───
  static ApiResponse? _cachedResponse;
  static DateTime? _cachedAt;
  static const _cacheTtl = Duration(minutes: 5);

  /// جلب المحتوى العام (blocks, documents, links) — بدون مصادقة
  /// يستخدم cache في الذاكرة لمنع تكرار الطلبات خلال 5 دقائق
  static Future<ApiResponse> fetchPublicContent({bool forceRefresh = false}) async {
    // إرجاع النسخة المخزنة إذا لا تزال صالحة
    if (!forceRefresh &&
        _cachedResponse != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return _cachedResponse!;
    }

    final response = await ApiClient.get('/api/content/public/');

    // تخزين النتيجة الناجحة فقط
    if (response.isSuccess) {
      _cachedResponse = response;
      _cachedAt = DateTime.now();
    }

    return response;
  }

  /// مسح الـ cache يدوياً (مثلاً بعد تحديث المحتوى)
  static void clearCache() {
    _cachedResponse = null;
    _cachedAt = null;
  }
}
