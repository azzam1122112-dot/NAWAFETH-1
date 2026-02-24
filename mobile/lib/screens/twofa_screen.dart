import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/auth_api.dart';
import '../services/account_api.dart';
import '../services/session_storage.dart';
import '../services/app_snackbar.dart';
import '../services/role_sync.dart';
import '../services/role_controller.dart';
import '../utils/local_user_state.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class TwoFAScreen extends StatefulWidget {
  final String phone;
  final Widget? redirectTo;
  final String? initialDevCode;

  const TwoFAScreen({
    super.key,
    required this.phone,
    this.redirectTo,
    this.initialDevCode,
  });

  @override
  State<TwoFAScreen> createState() => _TwoFAScreenState();
}

class _TwoFAScreenState extends State<TwoFAScreen> {
  // Development shortcut disabled by default; enable explicitly by build flag.
  static const bool _devAllowAny4DigitsOtp = bool.fromEnvironment(
    'DEV_ALLOW_ANY_OTP',
    defaultValue: false,
  );

  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;

  String? _extractBackendErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString().trim();
      }
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          final msg = first?.toString().trim() ?? '';
          if (msg.isNotEmpty) return msg;
        }
        final msg = value?.toString().trim() ?? '';
        if (msg.isNotEmpty && entry.key.toString() != 'ok') {
          return msg;
        }
      }
    } else if (data is List && data.isNotEmpty) {
      final msg = data.first?.toString().trim() ?? '';
      if (msg.isNotEmpty) return msg;
    } else if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return null;
  }

  String _formatError(Object e) {
    if (e is DioException) {
      final backendMsg = _extractBackendErrorMessage(e);
      if (backendMsg != null && backendMsg.isNotEmpty) {
        return backendMsg;
      }
      final msg = (e.message ?? '').trim();
      final short = msg.isEmpty ? 'تعذر الاتصال بالخادم' : msg;
      return 'حدث خطأ في الاتصال بالشبكة: $short';
    }
    return e.toString();
  }

  String _normalizeOtp(String input) {
    final trimmed = input.trim();
    final buffer = StringBuffer();
    for (final rune in trimmed.runes) {
      final ch = String.fromCharCode(rune);

      // Arabic-Indic digits: ٠١٢٣٤٥٦٧٨٩
      const arabicIndic = {
        '٠': '0',
        '١': '1',
        '٢': '2',
        '٣': '3',
        '٤': '4',
        '٥': '5',
        '٦': '6',
        '٧': '7',
        '٨': '8',
        '٩': '9',
      };

      // Eastern Arabic / Persian digits: ۰۱۲۳۴۵۶۷۸۹
      const easternArabic = {
        '۰': '0',
        '۱': '1',
        '۲': '2',
        '۳': '3',
        '۴': '4',
        '۵': '5',
        '۶': '6',
        '۷': '7',
        '۸': '8',
        '۹': '9',
      };

      if (arabicIndic.containsKey(ch)) {
        buffer.write(arabicIndic[ch]);
        continue;
      }
      if (easternArabic.containsKey(ch)) {
        buffer.write(easternArabic[ch]);
        continue;
      }
      if (RegExp(r'\d').hasMatch(ch)) {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    try {
      await AuthApi().sendOtp(phone: widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إعادة إرسال الرمز')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إعادة الإرسال: ${_formatError(e)}')),
      );
    }
  }

  Future<void> _verify() async {
    final code = _normalizeOtp(_codeController.text);
    if (code.length != 4 || int.tryParse(code) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل رمز مكون من 4 أرقام')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final codeToVerify = (_devAllowAny4DigitsOtp &&
              (widget.initialDevCode ?? '').trim().isNotEmpty)
          ? widget.initialDevCode!.trim()
          : code;

      final result = await AuthApi().otpVerify(
        phone: widget.phone,
        code: codeToVerify,
      );

      await const SessionStorage().saveTokens(access: result.access, refresh: result.refresh);

      // Best-effort: refresh user identity for UI.
      try {
        final me = await AccountApi().me();

        String? nonEmpty(dynamic v) {
          final s = (v ?? '').toString().trim();
          return s.isEmpty ? null : s;
        }

        final userId = me['id'] is int ? me['id'] as int : int.tryParse((me['id'] ?? '').toString());
        if (userId != null) {
          await LocalUserState.setActiveUserId(userId);
        }

        await const SessionStorage().saveProfile(
          userId: userId,
          username: nonEmpty(me['username']),
          email: nonEmpty(me['email']),
          firstName: nonEmpty(me['first_name']),
          lastName: nonEmpty(me['last_name']),
          phone: nonEmpty(me['phone']),
        );
      } catch (_) {
        // ignore
      }

      // Best-effort: sync provider/client role flags for UI.
      try {
        await RoleSync.sync(accessToken: result.access);
        await RoleController.instance.refreshFromPrefs();
      } catch (_) {
        // ignore
      }

      if (!mounted) return;

      if (result.isNewUser || result.needsCompletion) {
        AppSnackBar.success('أهلاً بك! يرجى استكمال تسجيل بياناتك.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignUpScreen()),
        );
        return;
      }

      AppSnackBar.success('تم تسجيل الدخول بنجاح.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => widget.redirectTo ?? const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_formatError(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("التحقق الثنائي (2FA)"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ العنوان
                  const Text(
                    "🔐 مصادقة ثنائية مطلوبة",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    "من فضلك أدخل رمز التحقق المكوّن من 4 أرقام.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 20),

                  // ✅ إدخال الكود
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      letterSpacing: 4,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: "••••",
                      counterText: "",
                      filled: true,
                      fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.deepPurple,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: _loading ? null : _resend,
                    child: const Text(
                      'إعادة إرسال الرمز',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ✅ زر التأكيد
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 40,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _loading ? null : _verify,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "تأكيد",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
