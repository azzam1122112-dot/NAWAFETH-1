import 'package:flutter/material.dart';

/// أيقونة Face ID: أيقونة شخص داخل مربع
class FaceIDIcon extends StatelessWidget {
  final double size;
  final Color color;
  const FaceIDIcon({super.key, this.size = 26, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.person_outline, color: color, size: size * 0.7),
    );
  }
}

class LoginSettingsScreen extends StatefulWidget {
  const LoginSettingsScreen({super.key});

  @override
  State<LoginSettingsScreen> createState() => _LoginSettingsScreenState();
}

class _LoginSettingsScreenState extends State<LoginSettingsScreen> {
  // بيانات وهمية
  String username = "عبدالسلام";
  String email = "user@email.com";
  String phone = "0505111111";
  String password = "********";

  // متحكمات
  final TextEditingController securityCodeCtrl = TextEditingController();
  final TextEditingController confirmSecurityCodeCtrl = TextEditingController();
  final TextEditingController faceIdCodeCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("إعدادات الدخول"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ✅ الهيدر
          Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.deepPurple,
                child: const Icon(Icons.person, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 12),
              Text(
                username,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: "Cairo",
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                email,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: "Cairo",
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),

          // 🟣 معلومات الحساب
          _buildSection("معلومات الحساب", [
            _buildEditableField(
              icon: Icons.person_outline,
              label: "اسم العضوية",
              value: username,
              onChanged: (val) => setState(() => username = val),
            ),
            _buildEditableField(
              icon: Icons.phone_android,
              label: "رقم الجوال",
              value: phone,
              onChanged: (val) => setState(() => phone = val),
            ),
          ]),

          const SizedBox(height: 20),

          // 🔵 الأمان
          _buildSection("الأمان", [
            _buildEditableField(
              icon: Icons.email_outlined,
              label: "البريد الإلكتروني",
              value: email,
              onChanged: (val) => setState(() => email = val),
            ),
            _buildEditableField(
              icon: Icons.lock_outline,
              label: "كلمة المرور",
              value: password,
              isPassword: true,
              onChanged: (val) => setState(() => password = val),
            ),
            const SizedBox(height: 12),
            _buildPurpleButton(
              icon: Icons.key,
              label: "إضافة رمز دخول آمان",
              onPressed: () {
                _showSecurityDialog();
              },
            ),
          ]),

          const SizedBox(height: 20),

          // 🟢 طرق الدخول الإضافية
          _buildSection("طرق الدخول الإضافية", [
            _buildPurpleButton(
              iconWidget: const FaceIDIcon(size: 22, color: Colors.white),
              label: "الدخول بمعرف الوجه",
              onPressed: () {
                _showFaceIdDialog();
              },
            ),
          ]),

          const SizedBox(height: 30),

          // ✅ زر الحفظ
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ تم حفظ التغييرات (وهمياً)"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "حفظ التغييرات",
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Cairo",
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ نافذة كرت رمز آمان
  void _showSecurityDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Center(
            child: Card(
              color: Colors.white,
              elevation: 12,
              shadowColor: Colors.black45,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر إغلاق
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.deepPurple,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Text(
                        "إضافة رمز دخول آمان",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "⚠️ احتفظ بالرمز في مكان آمن ولا تشاركه مع أحد.",
                        style: TextStyle(fontFamily: 'Cairo'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: securityCodeCtrl,
                        decoration: const InputDecoration(
                          labelText: "رمز الآمان",
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: confirmSecurityCodeCtrl,
                        decoration: const InputDecoration(
                          labelText: "تأكيد رمز الآمان",
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✅ تم حفظ رمز الآمان (وهمياً)"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("حفظ"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  /// ✅ نافذة كرت Face ID
  void _showFaceIdDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Center(
            child: Card(
              color: Colors.white,
              elevation: 12,
              shadowColor: Colors.black45,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر إغلاق
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.deepPurple,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Text(
                        "إعداد الدخول بمعرف الوجه",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "قم بتأكيد هويتك عبر إدخال رمز تحقق لتفعيل الدخول بمعرف الوجه.",
                        style: TextStyle(fontFamily: 'Cairo'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: faceIdCodeCtrl,
                        decoration: const InputDecoration(
                          labelText: "أدخل رمز التحقق",
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✅ تم تفعيل معرف الوجه (وهمياً)"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("تأكيد"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  // 🟣 بناء قسم
  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      color: Colors.deepPurple.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: "Cairo",
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  // 🟣 حقل إدخال
  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    bool isPassword = false,
  }) {
    final controller = TextEditingController(text: value);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.deepPurple),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
        ),
      ),
    );
  }

  // 🟣 زر بنفسجي
  Widget _buildPurpleButton({
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: iconWidget ?? Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
