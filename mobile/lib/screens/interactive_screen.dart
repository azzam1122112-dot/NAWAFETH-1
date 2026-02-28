import 'package:flutter/material.dart';
import '../widgets/app_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/custom_drawer.dart';
import 'chat_detail_screen.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/interactive_service.dart';
import '../models/provider_public_model.dart';
import '../models/user_public_model.dart';
import '../models/media_item_model.dart';

class InteractiveScreen extends StatefulWidget {
  const InteractiveScreen({super.key});

  @override
  State<InteractiveScreen> createState() => _InteractiveScreenState();
}

class _InteractiveScreenState extends State<InteractiveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ────── حالة الدور ──────
  bool _isProvider = false;

  // ────── بيانات من الـ API ──────
  List<ProviderPublicModel> _following = [];
  List<UserPublicModel> _followers = [];
  List<MediaItemModel> _favorites = [];

  // ────── حالات التحميل لكل تبويب ──────
  bool _followingLoading = true;
  bool _followersLoading = true;
  bool _favoritesLoading = true;

  String? _followingError;
  String? _followersError;
  String? _favoritesError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  /// ✅ تحميل جميع البيانات من الـ API
  Future<void> _loadAllData() async {
    // تحديد الدور
    final role = await AuthService.getRoleState();
    if (mounted) {
      setState(() {
        _isProvider = role == 'provider';
      });
    }

    // جلب البيانات بالتوازي
    await Future.wait([
      _loadFollowing(),
      _loadFollowers(),
      _loadFavorites(),
    ]);
  }

  Future<void> _loadFollowing() async {
    if (!mounted) return;
    setState(() {
      _followingLoading = true;
      _followingError = null;
    });

    final result = await InteractiveService.fetchFollowing();
    if (!mounted) return;

    setState(() {
      _followingLoading = false;
      if (result.isSuccess) {
        _following = result.items;
      } else {
        _followingError = result.error;
      }
    });
  }

  Future<void> _loadFollowers() async {
    if (!mounted) return;
    setState(() {
      _followersLoading = true;
      _followersError = null;
    });

    // فقط المزودين يمكنهم جلب قائمة المتابعين
    if (!_isProvider) {
      setState(() {
        _followersLoading = false;
        _followers = [];
      });
      return;
    }

    final result = await InteractiveService.fetchFollowers();
    if (!mounted) return;

    setState(() {
      _followersLoading = false;
      if (result.isSuccess) {
        _followers = result.items;
      } else {
        _followersError = result.error;
      }
    });
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    setState(() {
      _favoritesLoading = true;
      _favoritesError = null;
    });

    final result = await InteractiveService.fetchFavorites();
    if (!mounted) return;

    setState(() {
      _favoritesLoading = false;
      if (result.isSuccess) {
        _favorites = result.items;
      } else {
        _favoritesError = result.error;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const CustomAppBar(title: "تفاعلي"),
        automaticallyImplyLeading: false,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontFamily: "Cairo",
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: "من أتابع", icon: Icon(Icons.group)),
            Tab(text: "متابعيني", icon: Icon(Icons.person)),
            Tab(text: "مفضلتي", icon: Icon(Icons.bookmark)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFollowingTab(),
          _buildFollowersTab(),
          _buildFavoritesTab(),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }

  // ══════════════════════════════════════════
  //  🔁 ويدجتات مشتركة
  // ══════════════════════════════════════════

  /// حالة التحميل
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// حالة الخطأ مع زر إعادة المحاولة
  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: "Cairo",
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("إعادة المحاولة",
                  style: TextStyle(fontFamily: "Cairo")),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// حالة فارغة
  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Cairo",
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// هيدر مزود الخدمة (صورة + اسم + زر اختياري)
  Widget _buildProviderHeader(
    ProviderPublicModel provider, {
    Widget? action,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final imageUrl = ApiClient.buildMediaUrl(provider.profileImage);

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          child: imageUrl == null
              ? Text(
                  provider.displayName.isNotEmpty
                      ? provider.displayName[0]
                      : '؟',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.displayName,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: "Cairo",
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (provider.city != null && provider.city!.isNotEmpty)
                Text(
                  provider.city!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontFamily: "Cairo",
                  ),
                ),
            ],
          ),
        ),
        if (provider.isVerified)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.verified,
              size: 16,
              color: provider.isVerifiedBlue ? Colors.blue : Colors.green,
            ),
          ),
        if (action != null) action,
      ],
    );
  }

  // ══════════════════════════════════════════
  //  📋 تبويب "من أتابع"
  // ══════════════════════════════════════════

  Widget _buildFollowingTab() {
    if (_followingLoading) return _buildLoadingState();
    if (_followingError != null) {
      return _buildErrorState(_followingError!, _loadFollowing);
    }
    if (_following.isEmpty) {
      return _buildEmptyState(Icons.group_off, "لا تتابع أي مزود خدمة حتى الآن");
    }

    final primaryColor = Theme.of(context).colorScheme.primary;

    return RefreshIndicator(
      onRefresh: _loadFollowing,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        itemCount: _following.length,
        itemBuilder: (context, index) {
          final provider = _following[index];
          final coverUrl = ApiClient.buildMediaUrl(provider.coverImage);

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // هيدر المزود
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildProviderHeader(
                    provider,
                    action: IconButton(
                      icon: Icon(Icons.chat, color: primaryColor, size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              name: provider.displayName,
                              isOnline: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // صورة الغلاف
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: coverUrl != null
                        ? Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                ),

                // إحصائيات سريعة
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniStat(Icons.people, '${provider.followersCount}'),
                      _miniStat(Icons.favorite, '${provider.likesCount}'),
                      if (provider.ratingAvg > 0)
                        _miniStat(Icons.star, provider.ratingAvg.toStringAsFixed(1)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
    );
  }

  Widget _miniStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(fontSize: 11, color: Colors.grey[700], fontFamily: "Cairo"),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  //  👥 تبويب "متابعيني"
  // ══════════════════════════════════════════

  Widget _buildFollowersTab() {
    // العميل لا يملك متابعين — فقط المزود
    if (!_isProvider) {
      return _buildEmptyState(
        Icons.person_off,
        "تبويب المتابعين متاح لمزودي الخدمة فقط.\nسجّل كمزود خدمة لعرض متابعينك.",
      );
    }

    if (_followersLoading) return _buildLoadingState();
    if (_followersError != null) {
      return _buildErrorState(_followersError!, _loadFollowers);
    }
    if (_followers.isEmpty) {
      return _buildEmptyState(Icons.person_off, "لا يوجد متابعون بعد");
    }

    final primaryColor = Theme.of(context).colorScheme.primary;

    return RefreshIndicator(
      onRefresh: _loadFollowers,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        itemCount: _followers.length,
        itemBuilder: (context, index) {
          final user = _followers[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0] : '؟',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              title: Text(
                user.displayName,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: "Cairo",
                ),
              ),
              subtitle: Text(
                user.usernameDisplay,
                style: const TextStyle(fontFamily: "Cairo", fontSize: 12),
              ),
              trailing: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                label: const Text(
                  "مراسلة",
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        name: user.displayName,
                        isOnline: false,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  //  ⭐ تبويب "مفضلتي"
  // ══════════════════════════════════════════

  Widget _buildFavoritesTab() {
    if (_favoritesLoading) return _buildLoadingState();
    if (_favoritesError != null) {
      return _buildErrorState(_favoritesError!, _loadFavorites);
    }
    if (_favorites.isEmpty) {
      return _buildEmptyState(Icons.bookmark_border, "لا توجد عناصر محفوظة في المفضلة");
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.85,
        ),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final item = _favorites[index];
          final imageUrl = ApiClient.buildMediaUrl(
            item.thumbnailUrl ?? item.fileUrl,
          );

          return Stack(
            children: [
              // الصورة
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => _buildBrokenImagePlaceholder(),
                      )
                    : _buildBrokenImagePlaceholder(),
              ),

              // أيقونة فيديو
              if (item.isVideo)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                  ),
                ),

              // نوع المحتوى (portfolio / spotlight)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.source == MediaItemSource.spotlight
                        ? Colors.amber.shade700
                        : Colors.deepPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.source == MediaItemSource.spotlight ? "أضواء" : "معرض",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: "Cairo",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // شريط أسفل
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.providerDisplayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            fontFamily: "Cairo",
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showRemoveConfirmDialog(index),
                        child: const Icon(
                          Icons.bookmark,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrokenImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }

  // ══════════════════════════════════════════
  //  🗑️ حوار تأكيد إزالة من المفضلة
  // ══════════════════════════════════════════

  void _showRemoveConfirmDialog(int index) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final item = _favorites[index];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "تأكيد الإزالة",
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: "Cairo"),
          ),
          content: const Text(
            "هل تريد إزالة المحتوى من المفضلة؟",
            style: TextStyle(fontFamily: "Cairo"),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              child: const Text(
                "إلغاء",
                style: TextStyle(color: Colors.grey, fontFamily: "Cairo"),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "تأكيد",
                style: TextStyle(color: Colors.white, fontFamily: "Cairo"),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                // ✅ إلغاء الحفظ عبر الـ API
                final success = await InteractiveService.unsaveItem(item);
                if (mounted) {
                  if (success) {
                    setState(() {
                      _favorites.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("تم إزالة العنصر من المفضلة",
                            style: TextStyle(fontFamily: "Cairo")),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("فشل إزالة العنصر — حاول مرة أخرى",
                            style: TextStyle(fontFamily: "Cairo")),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
