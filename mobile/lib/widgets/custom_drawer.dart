import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/colors.dart';
import '../constants/app_texts.dart';
import '../screens/provider_dashboard/provider_home_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_settings_screen.dart';
import '../screens/terms_screen.dart';
import '../screens/about_screen.dart';
import '../screens/contact_screen.dart';
import '../main.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String selectedLanguage = "ar";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final themeController = MyThemeController.of(context);
    final isDarkMode = themeController?.themeMode == ThemeMode.dark;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // ✅ رأس القائمة
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              right: 20,
              left: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.deepPurple.withOpacity(0.15)
                      : Colors.deepPurple.withOpacity(0.05),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 👤 معلومات
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "أهلاً عبدالسلام",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: isDark ? Colors.white : AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "0505111111",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Cairo',
                        color: isDark ? Colors.grey[300] : Colors.black54,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Switch(
                      value: isDarkMode,
                      activeColor: AppColors.primaryDark,
                      onChanged: (val) {
                        final mode = val ? ThemeMode.dark : ThemeMode.light;
                        themeController?.changeTheme(mode);
                      },
                    ),
                    Text(
                      isDarkMode ? "النمط الليلي" : "النمط النهاري",
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Cairo',
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? Colors.grey[700] : const Color(0xFFE0E0E0),
          ),

          // ✅ عناصر القائمة
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              children: [
                _buildDrawerItem(
                  icon: Icons.home_outlined,
                  label: AppTexts.getText(context, "home"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  isDark: isDark,
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  label: AppTexts.getText(context, "settings"),
                  onTap: () {
                    Navigator.pop(context); // إغلاق الـ Drawer
                    Future.delayed(const Duration(milliseconds: 100), () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LoginSettingsScreen(),
                        ),
                      );
                    });
                  },
                  isDark: isDark,
                ),
                _buildDrawerItem(
                  icon: Icons.language,
                  label: AppTexts.getText(context, "language"),
                  onTap: () => _showLanguageDialog(),
                  isDark: isDark,
                ),
                _buildDrawerItem(
                  icon: FontAwesomeIcons.qrcode,
                  label: AppTexts.getText(context, "qr"),
                  onTap: () {
                    Navigator.pop(context); // إغلاق الـ Drawer
                    Future.delayed(const Duration(milliseconds: 100), () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProviderHomeScreen(),
                        ),
                      );
                    });
                  },
                  isDark: isDark,
                ),
                _buildDrawerItem(
                  icon: Icons.article_outlined,
                  label: AppTexts.getText(context, "terms"),
                  onTap: () {
                    Navigator.pop(context); // إغلاق الـ Drawer
                    Future.delayed(const Duration(milliseconds: 100), () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TermsScreen()),
                      );
                    });
                  },
                  isDark: isDark,
                ),
                _buildDrawerItem(
                  icon: Icons.support_agent,
                  label: AppTexts.getText(context, "support"),
                  onTap: () {
                    Navigator.pop(context); // إغلاق الـ Drawer
                    Future.delayed(const Duration(milliseconds: 100), () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ContactScreen()),
                      );
                    });
                  },
                  isDark: isDark,
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  label: AppTexts.getText(context, "about"),
                  onTap: () {
                    Navigator.pop(context); // إغلاق الـ Drawer
                    Future.delayed(const Duration(milliseconds: 100), () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    });
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? Colors.grey[700] : const Color(0xFFE0E0E0),
          ),

          // ✅ أزرار أسفل
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _buildActionBtn(
                  text: AppTexts.getText(context, "logout"),
                  color: AppColors.primaryDark,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 10),
                _buildActionBtn(
                  text: AppTexts.getText(context, "delete"),
                  color: Colors.red.shade600,
                  onPressed: () => _showDeleteConfirmDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ نافذة اختيار اللغة
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final themeController = MyThemeController.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "🌐 اختر اللغة",
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _languageOption("ar", "🇸🇦", "العربية", themeController),
              const SizedBox(height: 10),
              _languageOption("en", "🇺🇸", "English", themeController),
            ],
          ),
        );
      },
    );
  }

  /// ✅ نافذة تأكيد الحذف
  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "⚠️ تأكيد حذف الحساب",
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: const Text(
            "ستقوم بحذف حسابك نهائياً، ولن نتمكن من استعادة بياناتك أو طلباتك السابقة.\n\n"
            "هل أنت متأكد أنك تريد المتابعة؟",
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
          ),
          actions: [
            TextButton(
              child: const Text("إلغاء", style: TextStyle(fontFamily: 'Cairo')),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                "تأكيد الحذف",
                style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
              ),
              onPressed: () {
                Navigator.pop(context);
                _showVerifyCodeDialog(context);
              },
            ),
          ],
        );
      },
    );
  }

  /// ✅ نافذة إدخال رمز تحقق
  void _showVerifyCodeDialog(BuildContext context) {
    TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "🔑 رمز التحقق",
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "أدخل رمز التحقق المرسل إلى جوالك لمتابعة الحذف.",
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: "رمز التحقق",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("إلغاء", style: TextStyle(fontFamily: 'Cairo')),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                "تأكيد",
                style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ تم حذف الحساب (وهمياً)")),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _languageOption(
    String code,
    String flag,
    String title,
    MyThemeController? controller,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Text(flag, style: const TextStyle(fontSize: 24)),
        title: Text(title, style: const TextStyle(fontFamily: 'Cairo')),
        trailing:
            selectedLanguage == code
                ? const Icon(Icons.check_circle, color: Colors.deepPurple)
                : null,
        onTap: () {
          setState(() => selectedLanguage = code);
          Navigator.pop(context);
          if (code == "ar") {
            controller?.changeLanguage(const Locale('ar', 'SA'));
          } else {
            controller?.changeLanguage(const Locale('en', 'US'));
          }
        },
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Icon(
        icon,
        color: isDark ? Colors.white70 : AppColors.primaryDark,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: AppColors.primaryDark.withOpacity(0.08),
    );
  }

  Widget _buildActionBtn({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
