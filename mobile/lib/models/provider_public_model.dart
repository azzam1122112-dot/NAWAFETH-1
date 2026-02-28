/// نموذج بيانات مزود الخدمة العام — يطابق ProviderPublicSerializer
///
/// يُستخدم في:
/// - قائمة "من أتابع" (التفاعلي)
/// - نتائج البحث عن مزودي الخدمة
/// - أي قائمة عامة لمزودي الخدمة
class ProviderPublicModel {
  final int id;
  final String displayName;
  final String? profileImage;
  final String? coverImage;
  final String? bio;
  final int? yearsExperience;
  final String? phone;
  final String? whatsapp;
  final String? city;
  final double? lat;
  final double? lng;
  final bool acceptsUrgent;
  final bool isVerifiedBlue;
  final bool isVerifiedGreen;
  final double ratingAvg;
  final int ratingCount;
  final String? createdAt;

  // ── إحصائيات اجتماعية ──
  final int followersCount;
  final int likesCount;
  final int followingCount;
  final int completedRequests;

  ProviderPublicModel({
    required this.id,
    required this.displayName,
    this.profileImage,
    this.coverImage,
    this.bio,
    this.yearsExperience,
    this.phone,
    this.whatsapp,
    this.city,
    this.lat,
    this.lng,
    this.acceptsUrgent = false,
    this.isVerifiedBlue = false,
    this.isVerifiedGreen = false,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.createdAt,
    this.followersCount = 0,
    this.likesCount = 0,
    this.followingCount = 0,
    this.completedRequests = 0,
  });

  factory ProviderPublicModel.fromJson(Map<String, dynamic> json) {
    return ProviderPublicModel(
      id: json['id'] as int? ?? 0,
      displayName: json['display_name'] as String? ?? '',
      profileImage: json['profile_image'] as String?,
      coverImage: json['cover_image'] as String?,
      bio: json['bio'] as String?,
      yearsExperience: json['years_experience'] as int?,
      phone: json['phone'] as String?,
      whatsapp: json['whatsapp'] as String?,
      city: json['city'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      acceptsUrgent: json['accepts_urgent'] as bool? ?? false,
      isVerifiedBlue: json['is_verified_blue'] as bool? ?? false,
      isVerifiedGreen: json['is_verified_green'] as bool? ?? false,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
      followersCount: json['followers_count'] as int? ?? 0,
      likesCount: json['likes_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      completedRequests: json['completed_requests'] as int? ?? 0,
    );
  }

  /// هل المزود مُوثق (أزرق أو أخضر)
  bool get isVerified => isVerifiedBlue || isVerifiedGreen;
}
