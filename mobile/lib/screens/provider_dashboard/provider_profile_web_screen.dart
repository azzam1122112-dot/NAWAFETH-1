import 'package:flutter/material.dart';

import '../../services/account_api.dart';
import '../../services/api_config.dart';
import '../../services/providers_api.dart';
import '../../services/reviews_api.dart';

class ProviderProfileWebScreen extends StatefulWidget {
  const ProviderProfileWebScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProviderProfileWebScreen> createState() => _ProviderProfileWebScreenState();
}

class _ProviderProfileWebScreenState extends State<ProviderProfileWebScreen> {
  late Future<_ProviderProfileVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProviderProfileVm> _load() async {
    final me = await AccountApi().me(forceRefresh: true);
    final providerProfile = await ProvidersApi().getMyProviderProfile(forceRefresh: true);
    final subcats = await ProvidersApi().getMyProviderSubcategories(forceRefresh: true);
    final myServices = await ProvidersApi().getMyServices();

    final providerId = _asInt(me['provider_profile_id']);
    double ratingAvg = 0;
    int ratingCount = 0;
    if (providerId != null) {
      try {
        final summary = await ReviewsApi().getProviderRatingSummary(providerId);
        ratingAvg = _asDouble(summary['rating_avg']) ?? 0;
        ratingCount = _asInt(summary['rating_count']) ?? 0;
      } catch (_) {
        // Best effort
      }
    }

    final displayName = (providerProfile?['display_name'] ?? '').toString().trim();
    final bio = (providerProfile?['bio'] ?? '').toString().trim();
    final city = (providerProfile?['city'] ?? '').toString().trim();
    final username = (me['username'] ?? '').toString().trim();
    final phone = (me['phone'] ?? '').toString().trim();
    final email = (me['email'] ?? '').toString().trim();
    final profileImageUrl = _normalizeMediaUrl(
      providerProfile?['profile_image'] ?? providerProfile?['profile_image_url'],
    );
    final coverImageUrl = _normalizeMediaUrl(
      providerProfile?['cover_image'] ?? providerProfile?['cover_image_url'],
    );

    final activeServices = myServices.where((s) => s.isActive == true).length;

    return _ProviderProfileVm(
      providerId: providerId,
      displayName: displayName.isEmpty ? null : displayName,
      username: username,
      phone: phone,
      email: email,
      city: city,
      bio: bio,
      profileImageUrl: profileImageUrl,
      coverImageUrl: coverImageUrl,
      followersCount: _asInt(me['provider_followers_count']) ?? 0,
      likesCount: _asInt(me['provider_likes_received_count']) ?? 0,
      subcategoriesCount: subcats.length,
      servicesCount: myServices.length,
      activeServicesCount: activeServices,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
      rawAccount: me,
      rawProvider: providerProfile ?? const <String, dynamic>{},
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<_ProviderProfileVm>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || snap.data == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 42),
                const SizedBox(height: 10),
                const Text(
                  'تعذر تحميل ملف مقدم الخدمة',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          );
        }

        final vm = snap.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, c) {
              final desktop = c.maxWidth >= 980;
              final tablet = c.maxWidth >= 700;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProviderProfileHero(vm: vm),
                  const SizedBox(height: 14),
                  _ProviderStatsGrid(vm: vm, desktop: desktop, tablet: tablet),
                  const SizedBox(height: 14),
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _ProviderIdentityCard(vm: vm)),
                        const SizedBox(width: 14),
                        Expanded(flex: 2, child: _ProviderActionsCard(vm: vm)),
                      ],
                    )
                  else ...[
                    _ProviderIdentityCard(vm: vm),
                    const SizedBox(height: 14),
                    _ProviderActionsCard(vm: vm),
                  ],
                  const SizedBox(height: 14),
                  _ProviderMetaCard(vm: vm),
                ],
              );
            },
          ),
        );
      },
    );

    if (widget.embedded) {
      return Directionality(textDirection: TextDirection.rtl, child: body);
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي لمقدم الخدمة')),
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

class _ProviderProfileVm {
  const _ProviderProfileVm({
    required this.providerId,
    required this.displayName,
    required this.username,
    required this.phone,
    required this.email,
    required this.city,
    required this.bio,
    required this.profileImageUrl,
    required this.coverImageUrl,
    required this.followersCount,
    required this.likesCount,
    required this.subcategoriesCount,
    required this.servicesCount,
    required this.activeServicesCount,
    required this.ratingAvg,
    required this.ratingCount,
    required this.rawAccount,
    required this.rawProvider,
  });

  final int? providerId;
  final String? displayName;
  final String username;
  final String phone;
  final String email;
  final String city;
  final String bio;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final int followersCount;
  final int likesCount;
  final int subcategoriesCount;
  final int servicesCount;
  final int activeServicesCount;
  final double ratingAvg;
  final int ratingCount;
  final Map<String, dynamic> rawAccount;
  final Map<String, dynamic> rawProvider;
}

class _ProviderProfileHero extends StatelessWidget {
  const _ProviderProfileHero({required this.vm});
  final _ProviderProfileVm vm;

  @override
  Widget build(BuildContext context) {
    final title = vm.displayName ?? 'مقدم خدمة';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF111827), Color(0xFF1D4ED8), Color(0xFF7C3AED)],
        ),
      ),
      child: Column(
        children: [
          if ((vm.coverImageUrl ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: Image.network(
                  vm.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withAlpha(40),
                  backgroundImage: (vm.profileImageUrl ?? '').isNotEmpty
                      ? NetworkImage(vm.profileImageUrl!)
                      : null,
                  child: (vm.profileImageUrl ?? '').isEmpty
                      ? const Icon(Icons.person_rounded, color: Colors.white)
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
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (vm.username.isNotEmpty) '@${vm.username}',
                          if (vm.city.isNotEmpty) vm.city,
                        ].join(' • '),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white.withAlpha(230),
                          fontSize: 12,
                        ),
                      ),
                      if (vm.bio.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          vm.bio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white.withAlpha(220),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _providerPill(Icons.star_rounded, '${vm.ratingAvg.toStringAsFixed(1)} (${vm.ratingCount})'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderStatsGrid extends StatelessWidget {
  const _ProviderStatsGrid({
    required this.vm,
    required this.desktop,
    required this.tablet,
  });

  final _ProviderProfileVm vm;
  final bool desktop;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: desktop ? 4 : (tablet ? 2 : 1),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: desktop ? 2.2 : 2.7,
      children: [
        _ProviderStatCard('المتابعون', vm.followersCount.toString(), Icons.groups_rounded, const Color(0xFF8B5CF6)),
        _ProviderStatCard('الإعجابات', vm.likesCount.toString(), Icons.thumb_up_alt_rounded, const Color(0xFFEC4899)),
        _ProviderStatCard('الخدمات', vm.servicesCount.toString(), Icons.design_services_rounded, const Color(0xFF0EA5E9)),
        _ProviderStatCard('الخدمات النشطة', vm.activeServicesCount.toString(), Icons.check_circle_rounded, const Color(0xFF10B981)),
      ],
    );
  }
}

class _ProviderStatCard extends StatelessWidget {
  const _ProviderStatCard(this.title, this.value, this.icon, this.color);

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 17)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderIdentityCard extends StatelessWidget {
  const _ProviderIdentityCard({required this.vm});
  final _ProviderProfileVm vm;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, IconData icon) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF334155)),
            const SizedBox(width: 8),
            SizedBox(
              width: 118,
              child: Text(label, style: const TextStyle(fontFamily: 'Cairo', color: Color(0xFF64748B))),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return _providerCard(
      title: 'بيانات مقدم الخدمة',
      child: Column(
        children: [
          row('اسم العرض', vm.displayName ?? '', Icons.badge_outlined),
          row('اسم المستخدم', vm.username.isEmpty ? '' : '@${vm.username}', Icons.alternate_email_rounded),
          row('المدينة', vm.city, Icons.location_on_outlined),
          row('الهاتف', vm.phone, Icons.phone_outlined),
          row('البريد', vm.email, Icons.mail_outline_rounded),
          row('التخصصات', vm.subcategoriesCount.toString(), Icons.category_outlined),
          if (vm.bio.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('النبذة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    vm.bio,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12.5, color: Color(0xFF334155), height: 1.45),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProviderActionsCard extends StatelessWidget {
  const _ProviderActionsCard({required this.vm});
  final _ProviderProfileVm vm;

  @override
  Widget build(BuildContext context) {
    Widget action(String label, IconData icon, String route) {
      return OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontFamily: 'Cairo')),
      );
    }

    return _providerCard(
      title: 'إجراءات سريعة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              action('الطلبات', Icons.assignment_outlined, '/provider_dashboard/orders'),
              action('الخدمات', Icons.design_services_outlined, '/provider_dashboard/services'),
              action('المراجعات', Icons.reviews_outlined, '/provider_dashboard/reviews'),
              action('الإشعارات', Icons.notifications_outlined, '/provider_dashboard/notifications'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('جاهزية الملف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  [
                    'المعرف: ${vm.providerId?.toString() ?? '-'}',
                    'الخدمات: ${vm.servicesCount}',
                    'التخصصات: ${vm.subcategoriesCount}',
                  ].join(' • '),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderMetaCard extends StatelessWidget {
  const _ProviderMetaCard({required this.vm});
  final _ProviderProfileVm vm;

  @override
  Widget build(BuildContext context) {
    final tags = <String, String>{
      'provider_id': '${vm.providerId ?? '-'}',
      'has_profile': '${vm.rawAccount['has_provider_profile'] ?? true}',
      'provider_profile_id': '${vm.rawAccount['provider_profile_id'] ?? '-'}',
      'followers_count': '${vm.rawAccount['provider_followers_count'] ?? vm.followersCount}',
      'likes_received': '${vm.rawAccount['provider_likes_received_count'] ?? vm.likesCount}',
      'accepts_urgent': '${vm.rawProvider['accepts_urgent'] ?? '-'}',
      'city': vm.city.isEmpty ? '-' : vm.city,
    };
    return _providerCard(
      title: 'مؤشرات تقنية',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: tags.entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              '${e.key}: ${e.value}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700),
            ),
          );
        }).toList(),
      ),
    );
  }
}

Widget _providerCard({required String title, required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 14),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

Widget _providerPill(IconData icon, String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(28),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
