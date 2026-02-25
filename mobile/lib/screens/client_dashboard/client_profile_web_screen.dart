import 'package:flutter/material.dart';

import '../../services/account_api.dart';
import '../../services/session_storage.dart';
import '../../utils/auth_guard.dart';

class ClientProfileWebScreen extends StatefulWidget {
  const ClientProfileWebScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ClientProfileWebScreen> createState() => _ClientProfileWebScreenState();
}

class _ClientProfileWebScreenState extends State<ClientProfileWebScreen> {
  final _session = const SessionStorage();
  late Future<_ClientProfileVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ClientProfileVm> _load() async {
    final loggedIn = await _session.isLoggedIn();
    if (!loggedIn) {
      throw const _LoginRequiredException();
    }

    final me = await AccountApi().me(forceRefresh: true);
    String text(dynamic v) => (v ?? '').toString().trim();
    int? asInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse(text(v)));

    final first = text(me['first_name']);
    final last = text(me['last_name']);
    final username = text(me['username']);
    final fullName = [if (first.isNotEmpty) first, if (last.isNotEmpty) last].join(' ');
    final roleState = text(me['role_state']).toLowerCase();

    return _ClientProfileVm(
      displayName: fullName.isEmpty ? (username.isEmpty ? 'مستخدم' : username) : fullName,
      username: username,
      email: text(me['email']),
      phone: text(me['phone']),
      roleLabel: me['is_provider'] == true || roleState == 'provider' ? 'مقدم خدمة' : 'عميل',
      followingCount: asInt(me['following_count']) ?? 0,
      likesCount: asInt(me['favorites_media_count']) ?? 0,
      hasProviderProfile: me['has_provider_profile'] == true,
      providerProfileId: asInt(me['provider_profile_id']),
      raw: me,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<_ClientProfileVm>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          final loginRequired = snap.error is _LoginRequiredException;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    loginRequired ? Icons.lock_outline_rounded : Icons.error_outline_rounded,
                    size: 42,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    loginRequired ? 'تسجيل الدخول مطلوب' : 'تعذر تحميل الملف الشخصي',
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: loginRequired ? () => checkAuth(context) : _refresh,
                    icon: Icon(loginRequired ? Icons.login_rounded : Icons.refresh_rounded),
                    label: Text(
                      loginRequired ? 'تسجيل الدخول' : 'إعادة المحاولة',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final vm = snap.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, c) {
              final desktop = c.maxWidth >= 980;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProfileHero(vm: vm),
                  const SizedBox(height: 14),
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _IdentityCard(vm: vm)),
                        const SizedBox(width: 14),
                        Expanded(flex: 2, child: _ProfileActionsCard(vm: vm)),
                      ],
                    )
                  else ...[
                    _IdentityCard(vm: vm),
                    const SizedBox(height: 14),
                    _ProfileActionsCard(vm: vm),
                  ],
                  const SizedBox(height: 14),
                  _RawMetaCard(vm: vm),
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
        appBar: AppBar(title: const Text('الملف الشخصي')),
        body: body,
      ),
    );
  }
}

class _ClientProfileVm {
  const _ClientProfileVm({
    required this.displayName,
    required this.username,
    required this.email,
    required this.phone,
    required this.roleLabel,
    required this.followingCount,
    required this.likesCount,
    required this.hasProviderProfile,
    required this.providerProfileId,
    required this.raw,
  });

  final String displayName;
  final String username;
  final String email;
  final String phone;
  final String roleLabel;
  final int followingCount;
  final int likesCount;
  final bool hasProviderProfile;
  final int? providerProfileId;
  final Map<String, dynamic> raw;
}

class _LoginRequiredException implements Exception {
  const _LoginRequiredException();
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.vm});
  final _ClientProfileVm vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8), Color(0xFF22C55E)],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withAlpha(40),
            child: const Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.displayName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (vm.username.isNotEmpty) '@${vm.username}',
                    vm.roleLabel,
                  ].join(' • '),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white.withAlpha(230),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroBadge(label: 'متابعة', value: vm.followingCount.toString()),
              _HeroBadge(label: 'إعجابات', value: vm.likesCount.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(fontFamily: 'Cairo', color: Colors.white.withAlpha(220), fontSize: 11)),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.vm});
  final _ClientProfileVm vm;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, String value, IconData icon) {
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
              width: 110,
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

    return _card(
      title: 'بيانات الحساب',
      child: Column(
        children: [
          item('الاسم', vm.displayName, Icons.badge_outlined),
          item('اسم المستخدم', vm.username.isEmpty ? '-' : '@${vm.username}', Icons.alternate_email_rounded),
          item('الهاتف', vm.phone, Icons.phone_outlined),
          item('البريد', vm.email, Icons.mail_outline_rounded),
          item('نوع الحساب', vm.roleLabel, Icons.verified_user_outlined),
        ],
      ),
    );
  }
}

class _ProfileActionsCard extends StatelessWidget {
  const _ProfileActionsCard({required this.vm});
  final _ClientProfileVm vm;

  @override
  Widget build(BuildContext context) {
    Widget action(String label, IconData icon, String route) {
      return OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontFamily: 'Cairo')),
      );
    }

    return _card(
      title: 'إجراءات سريعة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              action('طلباتي', Icons.assignment_outlined, '/client_dashboard/orders'),
              action('إشعاراتي', Icons.notifications_outlined, '/client_dashboard/notifications'),
              action('الرئيسية', Icons.home_outlined, '/home'),
              if (vm.hasProviderProfile || vm.providerProfileId != null)
                action('لوحة المزود', Icons.handyman_outlined, '/provider_dashboard'),
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
                const Text(
                  'حالة الملف',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  vm.hasProviderProfile
                      ? 'لديك ملف مزود خدمة مرتبط ويمكنك الانتقال للوحة المزود.'
                      : 'حسابك يعمل كعميل حاليًا. يمكن إضافة دعم تعديل الملف لاحقًا في نسخة الويب.',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RawMetaCard extends StatelessWidget {
  const _RawMetaCard({required this.vm});
  final _ClientProfileVm vm;

  @override
  Widget build(BuildContext context) {
    final keys = [
      'id',
      'role_state',
      'is_provider',
      'has_provider_profile',
      'provider_profile_id',
      'following_count',
      'favorites_media_count',
    ];
    return _card(
      title: 'مؤشرات الحساب',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: keys.map((k) {
          final v = (vm.raw[k] ?? '-').toString();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              '$k: $v',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700),
            ),
          );
        }).toList(),
      ),
    );
  }
}

Widget _card({required String title, required Widget child}) {
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

