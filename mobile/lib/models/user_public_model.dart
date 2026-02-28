/// نموذج بيانات المستخدم العام — يطابق UserPublicSerializer
///
/// يُستخدم في:
/// - قائمة "متابعيني" (التفاعلي - مزود الخدمة)
/// - أي قائمة عامة للمستخدمين
class UserPublicModel {
  final int id;
  final String username;
  final String displayName;
  final int? providerId;

  UserPublicModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.providerId,
  });

  factory UserPublicModel.fromJson(Map<String, dynamic> json) {
    return UserPublicModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'مستخدم',
      providerId: json['provider_id'] as int?,
    );
  }

  /// اسم المستخدم بصيغة @username
  String get usernameDisplay => '@$username';

  /// هل المستخدم لديه ملف مزود خدمة
  bool get hasProviderProfile => providerId != null;
}
