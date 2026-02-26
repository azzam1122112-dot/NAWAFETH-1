import 'package:dio/dio.dart';

import '../core/network/api_dio.dart';
import 'api_config.dart';
import 'dio_proxy.dart';

class SiteContentBlockData {
  final String key;
  final String titleAr;
  final String bodyAr;
  final DateTime? updatedAt;

  const SiteContentBlockData({
    required this.key,
    required this.titleAr,
    required this.bodyAr,
    this.updatedAt,
  });
}

class SiteLegalDocumentData {
  final String docType;
  final String version;
  final DateTime? publishedAt;
  final String fileUrl;

  const SiteLegalDocumentData({
    required this.docType,
    required this.version,
    this.publishedAt,
    required this.fileUrl,
  });
}

class SiteLinksData {
  final String xUrl;
  final String whatsappUrl;
  final String email;
  final String androidStore;
  final String iosStore;
  final String websiteUrl;

  const SiteLinksData({
    this.xUrl = '',
    this.whatsappUrl = '',
    this.email = '',
    this.androidStore = '',
    this.iosStore = '',
    this.websiteUrl = '',
  });

  bool get hasAny =>
      xUrl.isNotEmpty ||
      whatsappUrl.isNotEmpty ||
      email.isNotEmpty ||
      androidStore.isNotEmpty ||
      iosStore.isNotEmpty ||
      websiteUrl.isNotEmpty;
}

class PublicContentPayload {
  final Map<String, SiteContentBlockData> blocks;
  final Map<String, SiteLegalDocumentData> documents;
  final SiteLinksData links;

  const PublicContentPayload({
    this.blocks = const {},
    this.documents = const {},
    this.links = const SiteLinksData(),
  });
}

class ContentApi {
  ContentApi({Dio? dio}) : _dio = dio ?? ApiDio.dio {
    configureDioForLocalhost(_dio, ApiConfig.baseUrl);
  }

  final Dio _dio;

  static PublicContentPayload? _cache;
  static DateTime? _cacheAt;
  static Future<PublicContentPayload>? _inFlight;
  static const Duration _ttl = Duration(minutes: 5);

  Future<PublicContentPayload> getPublicContent({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cache != null &&
        _cacheAt != null &&
        now.difference(_cacheAt!) < _ttl) {
      return _cache!;
    }
    if (!forceRefresh && _inFlight != null) {
      return _inFlight!;
    }

    final future = _fetchPublicContent();
    _inFlight = future;
    try {
      final data = await future;
      _cache = data;
      _cacheAt = DateTime.now();
      return data;
    } finally {
      _inFlight = null;
    }
  }

  static void clearCache() {
    _cache = null;
    _cacheAt = null;
    _inFlight = null;
  }

  Future<PublicContentPayload> _fetchPublicContent() async {
    try {
      final res = await _dio.get('${ApiConfig.apiPrefix}/content/public/');
      final root = _asMap(res.data);

      final blocks = <String, SiteContentBlockData>{};
      final rawBlocks = _asMap(root['blocks']);
      for (final entry in rawBlocks.entries) {
        final blockMap = _asMap(entry.value);
        final key = entry.key.trim();
        if (key.isEmpty) continue;
        blocks[key] = SiteContentBlockData(
          key: key,
          titleAr: _asString(blockMap['title_ar']),
          bodyAr: _asString(blockMap['body_ar']),
          updatedAt: DateTime.tryParse(_asString(blockMap['updated_at'])),
        );
      }

      final docs = <String, SiteLegalDocumentData>{};
      final rawDocs = _asMap(root['documents']);
      for (final entry in rawDocs.entries) {
        final docMap = _asMap(entry.value);
        final docType = _asString(docMap['doc_type']).isNotEmpty
            ? _asString(docMap['doc_type'])
            : entry.key.toString();
        docs[docType] = SiteLegalDocumentData(
          docType: docType,
          version: _asString(docMap['version']),
          publishedAt: DateTime.tryParse(_asString(docMap['published_at'])),
          fileUrl: _resolveUrl(_asString(docMap['file_url'])),
        );
      }

      final rawLinks = _asMap(root['links']);
      final links = SiteLinksData(
        xUrl: _resolveUrl(_asString(rawLinks['x_url'])),
        whatsappUrl: _resolveUrl(_asString(rawLinks['whatsapp_url'])),
        email: _asString(rawLinks['email']),
        androidStore: _resolveUrl(_asString(rawLinks['android_store'])),
        iosStore: _resolveUrl(_asString(rawLinks['ios_store'])),
        websiteUrl: _resolveUrl(_asString(rawLinks['website_url'])),
      );

      return PublicContentPayload(
        blocks: blocks,
        documents: docs,
        links: links,
      );
    } catch (_) {
      return const PublicContentPayload();
    }
  }

  String _resolveUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;
    try {
      return Uri.parse(ApiConfig.baseUrl).resolve(value).toString();
    } catch (_) {
      return value;
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return const <String, dynamic>{};
  }

  String _asString(dynamic value) => (value ?? '').toString().trim();
}
