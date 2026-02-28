/// نموذج بيانات المستخدم العام — يطابق UserPublicSerializer
///
/// يُستخدم في:
/// - قائمة "متابعيني" (التفاعلي - مزود الخدمة)
/// - أي قائمة عامة للمستخدمين
class UserPublicModel {
  final int id;
  final String username;
  final String displayName;

  UserPublicModel({
    required this.id,
    required this.username,
    required this.displayName,
  });

  factory UserPublicModel.fromJson(Map<String, dynamic> json) {
    return UserPublicModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'مستخدم',
    );
  }

  /// اسم المستخدم بصيغة @username
  String get usernameDisplay => '@$username';
}
