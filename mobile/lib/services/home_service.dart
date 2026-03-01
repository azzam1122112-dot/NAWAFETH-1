import 'api_client.dart';
import '../models/category_model.dart';
import '../models/banner_model.dart';
import '../models/provider_public_model.dart';

/// خدمة الصفحة الرئيسية — تجلب البيانات من الـ API
class HomeService {
  static const Duration _cacheTtl = Duration(minutes: 2);

  static _CacheEntry<List<CategoryModel>>? _categoriesCache;
  static final Map<int, _CacheEntry<List<ProviderPublicModel>>> _featuredProvidersCache = {};
  static final Map<int, _CacheEntry<List<BannerModel>>> _homeBannersCache = {};

  static HomeCachedData getCachedHomeData({int providersLimit = 10, int bannersLimit = 6}) {
    final categories = _categoriesCache?.data ?? const <CategoryModel>[];
    final providers = _featuredProvidersCache[providersLimit]?.data ?? const <ProviderPublicModel>[];
    final banners = _homeBannersCache[bannersLimit]?.data ?? const <BannerModel>[];
    return HomeCachedData(
      categories: List<CategoryModel>.from(categories),
      providers: List<ProviderPublicModel>.from(providers),
      banners: List<BannerModel>.from(banners),
    );
  }

  // ── التصنيفات ──
  static Future<List<CategoryModel>> fetchCategories({bool forceRefresh = false}) async {
    final cached = _categoriesCache;
    if (!forceRefresh && cached != null && cached.isFresh(_cacheTtl)) {
      return List<CategoryModel>.from(cached.data);
    }

    final res = await ApiClient.get('/api/providers/categories/');
    if (res.isSuccess && res.data != null) {
      final list = res.data is List ? res.data as List : (res.data['results'] as List?) ?? [];
      final parsed = list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
      _categoriesCache = _CacheEntry<List<CategoryModel>>(
        List<CategoryModel>.unmodifiable(parsed),
        DateTime.now(),
      );
      return parsed;
    }
    if (cached != null) {
      return List<CategoryModel>.from(cached.data);
    }
    return [];
  }

  // ── مزودو الخدمة (مميزون / أحدث) ──
  static Future<List<ProviderPublicModel>> fetchFeaturedProviders({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cached = _featuredProvidersCache[limit];
    if (!forceRefresh && cached != null && cached.isFresh(_cacheTtl)) {
      return List<ProviderPublicModel>.from(cached.data);
    }

    final res = await ApiClient.get('/api/providers/list/?page_size=$limit');
    if (res.isSuccess && res.data != null) {
      final list = res.data is List ? res.data as List : (res.data['results'] as List?) ?? [];
      final parsed = list.map((e) => ProviderPublicModel.fromJson(e as Map<String, dynamic>)).toList();
      _featuredProvidersCache[limit] = _CacheEntry<List<ProviderPublicModel>>(
        List<ProviderPublicModel>.unmodifiable(parsed),
        DateTime.now(),
      );
      return parsed;
    }
    if (cached != null) {
      return List<ProviderPublicModel>.from(cached.data);
    }
    return [];
  }

  // ── البانرات الإعلانية ──
  static Future<List<BannerModel>> fetchHomeBanners({
    int limit = 6,
    bool forceRefresh = false,
  }) async {
    final cached = _homeBannersCache[limit];
    if (!forceRefresh && cached != null && cached.isFresh(_cacheTtl)) {
      return List<BannerModel>.from(cached.data);
    }

    final res = await ApiClient.get('/api/promo/banners/home/?limit=$limit');
    if (res.isSuccess && res.data != null) {
      final list = res.data is List ? res.data as List : [];
      final parsed = list.map((e) => BannerModel.fromJson(e as Map<String, dynamic>)).toList();
      _homeBannersCache[limit] = _CacheEntry<List<BannerModel>>(
        List<BannerModel>.unmodifiable(parsed),
        DateTime.now(),
      );
      return parsed;
    }
    if (cached != null) {
      return List<BannerModel>.from(cached.data);
    }
    return [];
  }
}

class HomeCachedData {
  final List<CategoryModel> categories;
  final List<ProviderPublicModel> providers;
  final List<BannerModel> banners;

  const HomeCachedData({
    required this.categories,
    required this.providers,
    required this.banners,
  });

  bool get hasAnyData =>
      categories.isNotEmpty || providers.isNotEmpty || banners.isNotEmpty;
}

class _CacheEntry<T> {
  final T data;
  final DateTime fetchedAt;

  const _CacheEntry(this.data, this.fetchedAt);

  bool isFresh(Duration ttl) {
    return DateTime.now().difference(fetchedAt) <= ttl;
  }
}
