import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../services/account_api.dart';
import '../../services/api_config.dart';
import '../../services/marketplace_api.dart';
import '../../services/providers_api.dart';
import '../../services/reviews_api.dart';
import '../../services/web_inline_banner.dart';
import '../../services/web_loading_overlay.dart';

class ProviderHomeWebScreen extends StatefulWidget {
  const ProviderHomeWebScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProviderHomeWebScreen> createState() => _ProviderHomeWebScreenState();
}

class _ProviderHomeWebScreenState extends State<ProviderHomeWebScreen> {
  late Future<_ProviderDashboardVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProviderDashboardVm> _load() async {
    final me = await AccountApi().me(forceRefresh: true);
    final myProfile = await ProvidersApi().getMyProviderProfile(forceRefresh: true);
    final subcats = await ProvidersApi().getMyProviderSubcategories(forceRefresh: true);

    final providerId = _asInt(me['provider_profile_id']);
    final followers = _asInt(me['provider_followers_count']) ?? 0;
    final likes = _asInt(me['provider_likes_received_count']) ?? 0;

    double ratingAvg = 0;
    int ratingCount = 0;
    if (providerId != null) {
      try {
        final rating = await ReviewsApi().getProviderRatingSummary(providerId);
        ratingAvg = _asDouble(rating['rating_avg']) ?? 0;
        ratingCount = _asInt(rating['rating_count']) ?? 0;
      } catch (_) {}
    }

    List<dynamic> orders = const [];
    try {
      orders = await MarketplaceApi().getMyProviderRequests();
    } catch (_) {}

    int completed = 0;
    int active = 0;
    int pending = 0;
    final normalizedOrders = <Map<String, dynamic>>[];
    for (final row in orders) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      normalizedOrders.add(map);
      final status = (map['status'] ?? map['status_group'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (status.contains('complete')) {
        completed++;
      } else if (status.contains('progress') ||
          status.contains('active') ||
          status.contains('started') ||
          status.contains('accepted')) {
        active++;
      } else {
        pending++;
      }
    }

    final displayName = (myProfile?['display_name'] ?? '').toString().trim();
    final username = (me['username'] ?? '').toString().trim();
    final bio = (myProfile?['bio'] ?? '').toString().trim();
    final city = (myProfile?['city'] ?? '').toString().trim();
    final profileImage = _normalizeMediaUrl(myProfile?['profile_image']);
    final coverImage = _normalizeMediaUrl(myProfile?['cover_image']);

    return _ProviderDashboardVm(
      providerId: providerId,
      displayName: displayName.isEmpty ? null : displayName,
      username: username.isEmpty ? null : username,
      bio: bio,
      city: city,
      profileImageUrl: profileImage,
      coverImageUrl: coverImage,
      followersCount: followers,
      likesCount: likes,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
      subcategoriesCount: subcats.length,
      totalOrders: normalizedOrders.length,
      activeOrders: active,
      pendingOrders: pending,
      completedOrders: completed,
      recentOrders: normalizedOrders.take(8).toList(),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _refreshWithOverlay() {
    return WebLoadingOverlayController.instance.run(
      () async {
        try {
          await _refresh();
          WebInlineBannerController.instance.success('تم تحديث لوحة مقدم الخدمة.');
        } catch (_) {
          WebInlineBannerController.instance.error('تعذر تحديث لوحة مقدم الخدمة.');
          rethrow;
        }
      },
      message: 'جاري تحديث لوحة مقدم الخدمة...',
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<_ProviderDashboardVm>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return _ErrorView(onRetry: _refreshWithOverlay);
        }

        final vm = snap.data;
        if (vm == null) {
          return _ErrorView(onRetry: _refreshWithOverlay);
        }

        return LayoutBuilder(
          builder: (context, c) {
            final desktop = c.maxWidth >= 1000;
            final tablet = c.maxWidth >= 700;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HeaderCard(vm: vm, desktop: desktop),
                  const SizedBox(height: 14),
                  _StatsGrid(vm: vm, desktop: desktop, tablet: tablet),
                  const SizedBox(height: 14),
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _OrdersPanel(orders: vm.recentOrders)),
                        const SizedBox(width: 14),
                        Expanded(flex: 2, child: _ActionsPanel(vm: vm)),
                      ],
                    )
                  else ...[
                    _ActionsPanel(vm: vm),
                    const SizedBox(height: 14),
                    _OrdersPanel(orders: vm.recentOrders),
                  ],
                ],
              ),
            );
          },
        );
      },
    );

    if (widget.embedded) {
      return Directionality(textDirection: TextDirection.rtl, child: body);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة مقدم الخدمة (Web)'),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _refreshWithOverlay,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: body,
      ),
    );
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse((v ?? '').toString());
  }

  static double? _asDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse((v ?? '').toString());
  }

  static String? _normalizeMediaUrl(dynamic raw) {
    final value = (raw ?? '').toString().trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    if (value.startsWith('/')) return '${ApiConfig.baseUrl}$value';
    return value;
  }
}

class _ProviderDashboardVm {
  const _ProviderDashboardVm({
    required this.providerId,
    required this.displayName,
    required this.username,
    required this.bio,
    required this.city,
    required this.profileImageUrl,
    required this.coverImageUrl,
    required this.followersCount,
    required this.likesCount,
    required this.ratingAvg,
    required this.ratingCount,
    required this.subcategoriesCount,
    required this.totalOrders,
    required this.activeOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.recentOrders,
  });

  final int? providerId;
  final String? displayName;
  final String? username;
  final String bio;
  final String city;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final int followersCount;
  final int likesCount;
  final double ratingAvg;
  final int ratingCount;
  final int subcategoriesCount;
  final int totalOrders;
  final int activeOrders;
  final int pendingOrders;
  final int completedOrders;
  final List<Map<String, dynamic>> recentOrders;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.vm, required this.desktop});

  final _ProviderDashboardVm vm;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final title = vm.displayName ?? 'مقدم خدمة';
    final subtitle = [
      if ((vm.username ?? '').isNotEmpty) '@${vm.username}',
      if (vm.city.isNotEmpty) vm.city,
    ].join(' • ');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF1A153D), AppColors.deepPurple, Color(0xFF9B7ED8)],
        ),
      ),
      child: Column(
        children: [
          if ((vm.coverImageUrl ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: desktop ? 170 : 120,
                width: double.infinity,
                child: Image.network(
                  vm.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: desktop ? 34 : 28,
                  backgroundColor: Colors.white.withAlpha(60),
                  backgroundImage: (vm.profileImageUrl ?? '').isNotEmpty
                      ? NetworkImage(vm.profileImageUrl!)
                      : null,
                  child: (vm.profileImageUrl ?? '').isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 28)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withAlpha(230),
                            fontFamily: 'Cairo',
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (vm.bio.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          vm.bio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withAlpha(220),
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _pill(Icons.star_rounded, '${vm.ratingAvg.toStringAsFixed(1)} (${vm.ratingCount})'),
                    const SizedBox(height: 6),
                    _pill(Icons.category_outlined, 'التخصصات: ${vm.subcategoriesCount}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.vm,
    required this.desktop,
    required this.tablet,
  });

  final _ProviderDashboardVm vm;
  final bool desktop;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _Stat('إجمالي الطلبات', vm.totalOrders.toString(), Icons.assignment_rounded, const Color(0xFF2563EB)),
      _Stat('طلبات نشطة', vm.activeOrders.toString(), Icons.bolt_rounded, const Color(0xFF0EA5A4)),
      _Stat('بانتظار الإجراء', vm.pendingOrders.toString(), Icons.hourglass_top_rounded, const Color(0xFFF59E0B)),
      _Stat('طلبات مكتملة', vm.completedOrders.toString(), Icons.check_circle_rounded, const Color(0xFF22C55E)),
      _Stat('المتابعون', vm.followersCount.toString(), Icons.groups_rounded, const Color(0xFF8B5CF6)),
      _Stat('الإعجابات', vm.likesCount.toString(), Icons.thumb_up_alt_rounded, const Color(0xFFEC4899)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: desktop ? 3 : (tablet ? 2 : 1),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: desktop ? 2.45 : 2.7,
      ),
      itemBuilder: (context, i) => _StatCard(stat: stats[i]),
    );
  }
}

class _Stat {
  const _Stat(this.title, this.value, this.icon, this.color);
  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: stat.color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(stat.icon, color: stat.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.value,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsPanel extends StatelessWidget {
  const _ActionsPanel({required this.vm});

  final _ProviderDashboardVm vm;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'إجراءات سريعة (Web)',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _action(context, 'لوحتي', Icons.person_outline_rounded, '/provider_dashboard'),
          _action(context, 'طلباتي', Icons.assignment_outlined, '/provider_dashboard/orders'),
          _action(context, 'خدماتي', Icons.design_services_outlined, '/provider_dashboard/services'),
          _action(context, 'مراجعاتي', Icons.reviews_outlined, '/provider_dashboard/reviews'),
          _action(context, 'الرئيسية', Icons.home_outlined, '/home'),
          _action(context, 'المدخل', Icons.door_front_door_outlined, '/entry'),
        ],
      ),
    );
  }

  Widget _action(BuildContext context, String label, IconData icon, String route) {
    return OutlinedButton.icon(
      onPressed: () {
        if (ModalRoute.of(context)?.settings.name == route) return;
        Navigator.pushNamed(context, route);
      },
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontFamily: 'Cairo')),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.deepPurple,
        side: BorderSide(color: AppColors.deepPurple.withAlpha(90)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _OrdersPanel extends StatelessWidget {
  const _OrdersPanel({required this.orders});

  final List<Map<String, dynamic>> orders;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'آخر طلبات مقدم الخدمة',
      child: orders.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'لا توجد طلبات حالياً أو تعذر تحميل البيانات.',
                style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF64748B)),
              ),
            )
          : Column(
              children: orders.map((o) => _OrderRow(order: o)).toList(),
            ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final title = (order['title'] ?? order['request_title'] ?? 'طلب خدمة')
        .toString()
        .trim();
    final code = (order['code'] ?? order['request_code'] ?? '').toString().trim();
    final status = (order['status_display'] ?? order['status_group'] ?? order['status'] ?? '')
        .toString()
        .trim();
    final city = (order['city'] ?? '').toString().trim();
    final created = (order['created_at'] ?? order['created'] ?? '').toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.deepPurple.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_rounded, color: AppColors.deepPurple, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'طلب خدمة' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (code.isNotEmpty) '#$code',
                    if (city.isNotEmpty) city,
                    if (status.isNotEmpty) status,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (created.isNotEmpty)
            Text(
              created.length > 16 ? created.substring(0, 16) : created,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: Color(0xFF94A3B8),
              ),
            ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            const Text(
              'تعذر تحميل لوحة مقدم الخدمة',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'تحقق من تسجيل الدخول أو اتصال الشبكة ثم أعد المحاولة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }
}
