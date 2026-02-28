import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_bar.dart';
import '../widgets/bottom_nav.dart';
import 'registration/register_service_provider.dart';
import 'provider_dashboard/provider_home_screen.dart';
import 'provider_dashboard/provider_orders_screen.dart';
import 'client_orders_screen.dart';
import '../widgets/custom_drawer.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  final Color mainColor = Colors.deepPurple;
  File? _profileImage;
  File? _coverImage;
  late AnimationController _controller;

  // ────── حالات التحميل ──────
  bool _isLoading = true;
  String? _errorMessage;

  // ────── بيانات من الـ API ──────
  UserProfile? _userProfile;
  bool get isProvider => _userProfile?.isProvider ?? false;
  bool get isProviderRegistered => _userProfile?.hasProviderProfile ?? false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _loadProfile();
  }

  /// ✅ تحميل بيانات المستخدم من الـ API
  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // التحقق من تسجيل الدخول
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'يجب تسجيل الدخول أولاً';
        });
      }
      return;
    }

    // جلب بيانات المستخدم
    final result = await ProfileService.fetchMyProfile();

    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      final profile = result.data!;

      // تحديث SharedPreferences للتوافق مع باقي التطبيق
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isProvider', profile.isProvider);
      await prefs.setBool('isProviderRegistered', profile.hasProviderProfile);

      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.error;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isCover}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        isCover
            ? _coverImage = File(picked.path)
            : _profileImage = File(picked.path);
      });
    }
  }

  Widget _iconButtonCircle(IconData icon, String label, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.grey[850] : Colors.white,
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black45 : Colors.black12,
                blurRadius: 4,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  /// ✅ شاشة خطأ مع زر إعادة المحاولة
  Widget _buildErrorState(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const CustomDrawer(),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(showSearchField: false, title: 'نافذتي'),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'حدث خطأ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (_errorMessage == 'يجب تسجيل الدخول أولاً') ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      color: mainColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ إذا كان مقدم خدمة، عرض لوحة المزود
    if (!_isLoading && _errorMessage == null && isProvider) {
      return const ProviderHomeScreen();
    }
    
    // ✅ إذا كان قيد التحميل، عرض شاشة تحميل
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: CustomAppBar(showSearchField: false),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.deepPurple,
          ),
        ),
        bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
      );
    }

    // ✅ إذا كان هناك خطأ
    if (_errorMessage != null) {
      return _buildErrorState(theme);
    }
    
    // ✅ عرض بروفايل العميل العادي
    final isDark = theme.brightness == Brightness.dark;
    final profile = _userProfile!;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ✅ أضف هذا السطر لفتح القائمة من اليسار
      drawer: const CustomDrawer(),

      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(showSearchField: false, title: 'نافذتي'),
      ),

      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: mainColor,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 190,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient:
                            _coverImage == null
                                ? LinearGradient(
                                  colors: [
                                    isDark ? Colors.deepPurple.shade800 : mainColor,
                                    isDark ? Colors.deepPurple.shade900.withOpacity(0.6) : mainColor.withOpacity(0.6),
                                  ],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                )
                                : null,
                        image:
                            _coverImage != null
                                ? DecorationImage(
                                  image: FileImage(_coverImage!),
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                      child: Stack(
                        children: [
                          // ✅ زر تعديل الغلاف
                          Positioned(
                            top: 8,
                            left: 16,
                            child: SafeArea(
                              bottom: false,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.photo_camera_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () => _pickImage(isCover: true),
                                ),
                              ),
                            ),
                          ),
                          // ✅ زر التبديل إلى وضع مقدم الخدمة (يظهر فقط إذا كان مسجلاً)
                          if (isProviderRegistered)
                            Positioned(
                              top: 8,
                              right: 16,
                              child: SafeArea(
                                bottom: false,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        final prefs = await SharedPreferences.getInstance();
                                        await prefs.setBool('isProvider', true);
                                      
                                        if (mounted) {
                                          // إظهار إشعار التبديل
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Row(
                                                children: [
                                                  Icon(Icons.check_circle, color: Colors.white),
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      'تم التبديل إلى حساب مقدم الخدمة بنجاح',
                                                      style: TextStyle(
                                                        fontFamily: 'Cairo',
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors.green,
                                              duration: const Duration(seconds: 5),
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                          
                                          setState(() {
                                            _isLoading = true;
                                          });
                                          await _loadProfile();
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(25),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(
                                              Icons.business_center,
                                              size: 18,
                                              color: Colors.deepPurple,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'مقدم خدمة',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepPurple,
                                                fontFamily: 'Cairo',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      top: 130,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? Colors.grey[800] : Colors.white,
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                                backgroundImage:
                                    _profileImage != null
                                        ? FileImage(_profileImage!)
                                        : null,
                                child:
                                    _profileImage == null
                                        ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 40,
                                        )
                                        : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _pickImage(isCover: false),
                                child: CircleAvatar(
                                  radius: 13,
                                  backgroundColor: mainColor,
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // ✅ اسم المستخدم — من الـ API
                Text(
                  profile.usernameDisplay,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                // ✅ الاسم الكامل إذا متوفر
                if (profile.firstName != null || profile.lastName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    profile.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // ✅ إحصائيات المتابعين والمتابعون
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('قائمة المتابعين'),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Text(
                            '${profile.followingCount}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'متابع',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('قائمة المتابَعون'),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Text(
                            '${profile.likesCount}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'يتابع',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.list_alt, color: Colors.white),
                    label: const Text(
                      "إدارة الطلبات",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      if (isProvider) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProviderOrdersScreen(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ClientOrdersScreen(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: isDark ? Colors.deepPurple.shade700 : mainColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.deepPurple.shade300 : mainColor,
                                width: 2,
                              ),
                              color: isDark ? Colors.grey[850] : Colors.white,
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: isDark ? Colors.grey[850] : Colors.white,
                              child: Icon(
                                Icons.add,
                                color: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
                                size: 28,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return RotationTransition(
                          turns: _controller,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [Colors.deepPurple.shade700, Colors.orange.shade700]
                                    : [const Color(0xFFE1BEE7), const Color(0xFFFFB74D)],
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: isDark ? Colors.grey[850] : Colors.white,
                              child: Icon(
                                Icons.play_arrow,
                                color: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
                                size: 26,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 30),
                // ✅ يظهر زر التسجيل كمقدم خدمة فقط إذا لم يكن مسجلاً بعد
                if (!isProviderRegistered)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.deepPurple.shade900.withOpacity(0.3)
                            : mainColor.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'انضم الآن وشارك مهاراتك مع الباحثين عنها بسهولة!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => const RegisterServiceProviderPage(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.person_add_alt_1,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'سجل كمقدم خدمة',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.deepPurple.shade700
                                  : mainColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          Positioned(
            top: 190,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Row(
                  children: [
                    _iconButtonCircle(Icons.qr_code, "QR", isDark),
                    const SizedBox(width: 16),
                    _iconButtonCircle(Icons.bookmark_border, '${profile.favoritesMediaCount}', isDark),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    _iconButtonCircle(Icons.person_outline, '${profile.followingCount}', isDark),
                    const SizedBox(width: 16),
                    _iconButtonCircle(Icons.thumb_up_alt_outlined, '${profile.likesCount}', isDark),
                  ],
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
