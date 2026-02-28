/// نموذج بيانات ملف المزود (من /api/providers/me/profile/)
class ProviderProfileModel {
  final int id;
  final String providerType;
  final String displayName;
  final String? profileImage;
  final String? coverImage;
  final String bio;
  final String? aboutDetails;
  final int yearsExperience;
  final String? whatsapp;
  final String? website;
  final List<dynamic> socialLinks;
  final List<dynamic> languages;
  final String city;
  final double? lat;
  final double? lng;
  final int coverageRadiusKm;
  final List<dynamic> qualifications;
  final List<dynamic> experiences;
  final List<dynamic> contentSections;
  final String seoKeywords;
  final String? seoMetaDescription;
  final String? seoSlug;
  final bool acceptsUrgent;
  final bool isVerifiedBlue;
  final bool isVerifiedGreen;
  final double ratingAvg;
  final int ratingCount;
  final String? createdAt;

  ProviderProfileModel({
    required this.id,
    required this.providerType,
    required this.displayName,
    this.profileImage,
    this.coverImage,
    required this.bio,
    this.aboutDetails,
    required this.yearsExperience,
    this.whatsapp,
    this.website,
    required this.socialLinks,
    required this.languages,
    required this.city,
    this.lat,
    this.lng,
    required this.coverageRadiusKm,
    required this.qualifications,
    required this.experiences,
    required this.contentSections,
    required this.seoKeywords,
    this.seoMetaDescription,
    this.seoSlug,
    required this.acceptsUrgent,
    required this.isVerifiedBlue,
    required this.isVerifiedGreen,
    required this.ratingAvg,
    required this.ratingCount,
    this.createdAt,
  });

  /// تحويل من JSON
  factory ProviderProfileModel.fromJson(Map<String, dynamic> json) {
    return ProviderProfileModel(
      id: json['id'] as int,
      providerType: json['provider_type'] as String? ?? 'individual',
      displayName: json['display_name'] as String? ?? '',
      profileImage: json['profile_image'] as String?,
      coverImage: json['cover_image'] as String?,
      bio: json['bio'] as String? ?? '',
      aboutDetails: json['about_details'] as String?,
      yearsExperience: json['years_experience'] as int? ?? 0,
      whatsapp: json['whatsapp'] as String?,
      website: json['website'] as String?,
      socialLinks: json['social_links'] as List<dynamic>? ?? [],
      languages: json['languages'] as List<dynamic>? ?? [],
      city: json['city'] as String? ?? '',
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['lng']),
      coverageRadiusKm: json['coverage_radius_km'] as int? ?? 10,
      qualifications: json['qualifications'] as List<dynamic>? ?? [],
      experiences: json['experiences'] as List<dynamic>? ?? [],
      contentSections: json['content_sections'] as List<dynamic>? ?? [],
      seoKeywords: json['seo_keywords'] as String? ?? '',
      seoMetaDescription: json['seo_meta_description'] as String?,
      seoSlug: json['seo_slug'] as String?,
      acceptsUrgent: json['accepts_urgent'] as bool? ?? false,
      isVerifiedBlue: json['is_verified_blue'] as bool? ?? false,
      isVerifiedGreen: json['is_verified_green'] as bool? ?? false,
      ratingAvg: _parseDouble(json['rating_avg']) ?? 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
    );
  }

  /// ─── حساب نسبة إكمال الملف التعريفي ───
  ///
  /// المعايير:
  /// 1. بيانات التسجيل الأساسية (30%) — متوفرة دائماً
  /// 2. تفاصيل الخدمة (10%) — display_name + bio
  /// 3. معلومات إضافية (10%) — about_details
  /// 4. معلومات التواصل الكاملة (10%) — whatsapp + website
  /// 5. اللغة ونطاق الخدمة (10%) — languages + coverage_radius_km
  /// 6. محتوى أعمالك (15%) — profile_image + cover_image + content_sections
  /// 7. SEO والكلمات المفتاحية (15%) — seo_keywords
  double get profileCompletion {
    double completion = 0.0;

    // 1️⃣ بيانات التسجيل الأساسية (30%)
    completion += 0.30;

    // 2️⃣ تفاصيل الخدمة (10%)
    if (displayName.isNotEmpty && bio.isNotEmpty) {
      completion += 0.10;
    }

    // 3️⃣ معلومات إضافية (10%)
    if (aboutDetails != null && aboutDetails!.isNotEmpty) {
      completion += 0.10;
    }

    // 4️⃣ معلومات التواصل الكاملة (10%)
    if ((whatsapp != null && whatsapp!.isNotEmpty) ||
        (website != null && website!.isNotEmpty)) {
      completion += 0.10;
    }

    // 5️⃣ اللغة ونطاق الخدمة (10%)
    if (languages.isNotEmpty) {
      completion += 0.10;
    }

    // 6️⃣ محتوى أعمالك (15%)
    double contentScore = 0.0;
    if (profileImage != null && profileImage!.isNotEmpty) contentScore += 0.05;
    if (coverImage != null && coverImage!.isNotEmpty) contentScore += 0.05;
    if (contentSections.isNotEmpty) contentScore += 0.05;
    completion += contentScore;

    // 7️⃣ SEO والكلمات المفتاحية (15%)
    if (seoKeywords.isNotEmpty) {
      completion += 0.15;
    }

    return completion.clamp(0.0, 1.0);
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
