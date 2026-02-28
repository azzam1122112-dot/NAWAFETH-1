import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import 'signup_screen.dart';

class TwoFAScreen extends StatefulWidget {
  final String phone;
  final Widget? redirectTo;
  /// للتوافق مع الأماكن القديمة التي تستخدم nextPage
  final Widget? nextPage;

  const TwoFAScreen({
    super.key,
    required this.phone,
    this.redirectTo,
    this.nextPage,
  });

  @override
  State<TwoFAScreen> createState() => _TwoFAScreenState();
}

class _TwoFAScreenState extends State<TwoFAScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  /// العد التنازلي لإعادة الإرسال (60 ثانية)
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _canResend = false;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _canResend = true;
        }
      });
      return _resendCountdown > 0;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// ✅ التحقق من الرمز عبر الـ API
  Future<void> _onVerifyOtp() async {
    final code = _codeController.text.trim();
    if (code.length != 4) {
      setState(() => _errorMessage = 'أدخل رمز التحقق المكون من 4 أرقام');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthApiService.verifyOtp(widget.phone, code);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // ✅ هل يحتاج إكمال البيانات؟
      if (result.needsCompletion) {
        // الانتقال لشاشة إكمال البيانات
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SignUpScreen(
              redirectTo: widget.redirectTo ?? widget.nextPage,
            ),
          ),
        );
      } else {
        // تسجيل الدخول ناجح — التوجيه
        _navigateAfterLogin();
      }
    } else {
      setState(() => _errorMessage = result.error ?? 'الرمز غير صحيح');
    }
  }

  /// ✅ إعادة إرسال الرمز
  Future<void> _onResendOtp() async {
    if (!_canResend || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final result = await AuthApiService.sendOtp(widget.phone);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (result.success) {
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.devCode != null
                ? 'تم الإرسال — رمز التطوير: ${result.devCode}'
                : 'تم إرسال رمز جديد',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      setState(() => _errorMessage = result.error ?? 'فشل إعادة الإرسال');
    }
  }

  void _navigateAfterLogin() {
    final target = widget.redirectTo ?? widget.nextPage;
    if (target != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => target),
        (route) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("التحقق من الرمز"),
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
                  // العنوان
                  const Text(
                    "🔐 رمز التحقق",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    "أدخل رمز التحقق المرسل إلى\n${widget.phone}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 20),

                  // إدخال الكود
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() => _errorMessage = null),
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
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
                      errorText: _errorMessage,
                      errorStyle: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // زر التأكيد
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _onVerifyOtp,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
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
                  ),
                  const SizedBox(height: 16),

                  // إعادة الإرسال
                  TextButton(
                    onPressed: _canResend ? _onResendOtp : null,
                    child: _isResending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _canResend
                                ? "إعادة إرسال الرمز"
                                : "إعادة الإرسال بعد $_resendCountdown ثانية",
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              color: _canResend
                                  ? Colors.deepPurple
                                  : Colors.grey,
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
