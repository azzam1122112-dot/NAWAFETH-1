import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/account_api.dart';
import '../services/api_config.dart';
import '../services/role_controller.dart';
import '../services/session_storage.dart';

enum WebDashboardRoleMode {
  client,
  provider,
}

class StaffBlockForFlutterWebScreen extends StatefulWidget {
  const StaffBlockForFlutterWebScreen({
    super.key,
    required this.child,
    this.intendedPath,
  });

  final Widget child;
  final String? intendedPath;

  @override
  State<StaffBlockForFlutterWebScreen> createState() =>
      _StaffBlockForFlutterWebScreenState();
}

class RoleModeAccessGuardScreen extends StatefulWidget {
  const RoleModeAccessGuardScreen({
    super.key,
    required this.mode,
    required this.child,
    this.intendedPath,
  });

  final WebDashboardRoleMode mode;
  final Widget child;
  final String? intendedPath;

  @override
  State<RoleModeAccessGuardScreen> createState() =>
      _RoleModeAccessGuardScreenState();
}

class _RoleModeAccessGuardScreenState extends State<RoleModeAccessGuardScreen> {
  late final Future<_RoleModeBootstrapState> _bootstrapFuture;
  bool _redirectScheduled = false;
  bool _openingBackendDashboard = false;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrapAccessState();
  }

  Future<_RoleModeBootstrapState> _bootstrapAccessState() async {
    final isLoggedIn = await const SessionStorage().isLoggedIn();
    if (!isLoggedIn) {
      return const _RoleModeBootstrapState(
        isLoggedIn: false,
        isStaff: false,
      );
    }

    bool isStaff = false;
    try {
      final me = await AccountApi().me(forceRefresh: true);
      final role = (me['role_state'] ?? '').toString().trim().toLowerCase();
      final isStaffFlag = me['is_staff'] == true || me['is_superuser'] == true;
      isStaff = role == 'staff' || isStaffFlag;
    } catch (_) {
      // best-effort only; role sync below still runs
    }

    try {
      await RoleController.instance.syncFromBackend();
    } catch (_) {
      // Fall back to local persisted role if backend is temporarily unavailable.
      try {
        await RoleController.instance.refreshFromPrefs();
      } catch (_) {
        // ignore
      }
    }
    return _RoleModeBootstrapState(
      isLoggedIn: true,
      isStaff: isStaff,
    );
  }

  Future<void> _openBackendDashboard() async {
    if (_openingBackendDashboard) return;
    setState(() => _openingBackendDashboard = true);
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/dashboard/');
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } finally {
      if (mounted) setState(() => _openingBackendDashboard = false);
    }
  }

  bool _isAllowed(RoleState roleState) {
    switch (widget.mode) {
      case WebDashboardRoleMode.client:
        return !roleState.isProvider;
      case WebDashboardRoleMode.provider:
        return roleState.isProviderRegistered && roleState.isProvider;
    }
  }

  String _forbiddenTitle(RoleState roleState) {
    switch (widget.mode) {
      case WebDashboardRoleMode.client:
        return 'وضع العميل غير مفعّل';
      case WebDashboardRoleMode.provider:
        return roleState.isProviderRegistered
            ? 'وضع مقدم الخدمة غير مفعّل'
            : 'حساب مزود الخدمة غير متاح';
    }
  }

  String _forbiddenMessage(RoleState roleState) {
    switch (widget.mode) {
      case WebDashboardRoleMode.client:
        return 'أنت الآن في وضع مقدم الخدمة. بدّل إلى وضع العميل ثم أعد المحاولة.';
      case WebDashboardRoleMode.provider:
        return roleState.isProviderRegistered
            ? 'أنت الآن في وضع العميل. بدّل إلى وضع مقدم الخدمة للوصول لهذه الصفحات.'
            : 'هذه الصفحة مخصصة لمقدمي الخدمة المسجلين فقط.';
    }
  }

  String _forbiddenPrimaryRoute(RoleState roleState) {
    switch (widget.mode) {
      case WebDashboardRoleMode.client:
        return roleState.isProviderRegistered ? '/provider_dashboard' : '/home';
      case WebDashboardRoleMode.provider:
        return '/client_dashboard';
    }
  }

  String _forbiddenPrimaryLabel(RoleState roleState) {
    switch (widget.mode) {
      case WebDashboardRoleMode.client:
        return roleState.isProviderRegistered ? 'لوحة المزود' : 'الرئيسية';
      case WebDashboardRoleMode.provider:
        return 'لوحة العميل';
    }
  }

  void _scheduleRedirect(String routeName) {
    if (_redirectScheduled) return;
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RoleModeBootstrapState>(
      future: _bootstrapFuture,
      builder: (context, authSnap) {
        if (authSnap.connectionState != ConnectionState.done) {
          return const _RoleGuardStatusView(
            title: 'التحقق من الصلاحيات',
            message: 'جاري التحقق من الجلسة ومزامنة وضع الحساب...',
            loading: true,
          );
        }

        final bootstrap =
            authSnap.data ??
            const _RoleModeBootstrapState(isLoggedIn: false, isStaff: false);
        final isLoggedIn = bootstrap.isLoggedIn;
        if (!isLoggedIn) {
          _scheduleRedirect('/login');
          return _RoleGuardStatusView(
            title: 'تسجيل الدخول مطلوب',
            message: 'يجب تسجيل الدخول للوصول لهذه اللوحة.',
            loading: false,
            intendedPath: widget.intendedPath,
            primaryLabel: 'الانتقال لتسجيل الدخول',
            onPrimaryTap: () => Navigator.of(context).pushReplacementNamed('/login'),
            secondaryLabel: 'المدخل',
            onSecondaryTap: () => Navigator.of(context).pushReplacementNamed('/entry'),
          );
        }

        if (bootstrap.isStaff) {
          return _RoleGuardStatusView(
            title: 'لوحة الإدارة في الباكند',
            message:
                'هذا الحساب إداري (staff). للوصول لإدارة المنصة استخدم لوحة الباكند المخصصة، وليس لوحات العميل/المزود داخل Flutter Web.',
            loading: false,
            intendedPath: widget.intendedPath,
            primaryLabel: _openingBackendDashboard
                ? 'جاري فتح لوحة الباكند...'
                : 'فتح لوحة الباكند',
            onPrimaryTap: _openingBackendDashboard ? null : _openBackendDashboard,
            secondaryLabel: 'الرئيسية',
            onSecondaryTap: () => Navigator.of(context).pushReplacementNamed('/home'),
          );
        }

        return ValueListenableBuilder<RoleState>(
          valueListenable: RoleController.instance.notifier,
          builder: (context, roleState, _) {
            if (_isAllowed(roleState)) return widget.child;

            final primaryRoute = _forbiddenPrimaryRoute(roleState);
            _scheduleRedirect(primaryRoute);
            return _RoleGuardStatusView(
              title: _forbiddenTitle(roleState),
              message: _forbiddenMessage(roleState),
              loading: false,
              intendedPath: widget.intendedPath,
              primaryLabel: _forbiddenPrimaryLabel(roleState),
              onPrimaryTap: () =>
                  Navigator.of(context).pushReplacementNamed(primaryRoute),
              secondaryLabel: 'الرئيسية',
              onSecondaryTap: () => Navigator.of(context).pushReplacementNamed('/home'),
            );
          },
        );
      },
    );
  }
}

class _RoleModeBootstrapState {
  const _RoleModeBootstrapState({
    required this.isLoggedIn,
    required this.isStaff,
  });

  final bool isLoggedIn;
  final bool isStaff;
}

class _StaffBlockForFlutterWebScreenState
    extends State<StaffBlockForFlutterWebScreen> {
  late final Future<_RoleModeBootstrapState> _bootstrapFuture;
  bool _openingBackendDashboard = false;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<_RoleModeBootstrapState> _bootstrap() async {
    final isLoggedIn = await const SessionStorage().isLoggedIn();
    if (!isLoggedIn) {
      return const _RoleModeBootstrapState(isLoggedIn: false, isStaff: false);
    }

    bool isStaff = false;
    try {
      final me = await AccountApi().me(forceRefresh: true);
      final role = (me['role_state'] ?? '').toString().trim().toLowerCase();
      isStaff = role == 'staff' || me['is_staff'] == true || me['is_superuser'] == true;
    } catch (_) {
      isStaff = false;
    }
    return _RoleModeBootstrapState(isLoggedIn: true, isStaff: isStaff);
  }

  Future<void> _openBackendDashboard() async {
    if (_openingBackendDashboard) return;
    setState(() => _openingBackendDashboard = true);
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/dashboard/');
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } finally {
      if (mounted) setState(() => _openingBackendDashboard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RoleModeBootstrapState>(
      future: _bootstrapFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _RoleGuardStatusView(
            title: 'التحقق من الصلاحيات',
            message: 'جاري التحقق من الجلسة...',
            loading: true,
          );
        }

        final state = snap.data ??
            const _RoleModeBootstrapState(isLoggedIn: false, isStaff: false);
        if (!state.isStaff) return widget.child;

        return _RoleGuardStatusView(
          title: 'لوحة الإدارة في الباكند',
          message:
              'هذا الحساب إداري (staff). استخدام الويب هنا مخصص للعملاء ومقدمي الخدمة فقط. استخدم لوحة الباكند لإدارة المنصة.',
          loading: false,
          intendedPath: widget.intendedPath,
          primaryLabel:
              _openingBackendDashboard ? 'جاري فتح لوحة الباكند...' : 'فتح لوحة الباكند',
          onPrimaryTap: _openingBackendDashboard ? null : _openBackendDashboard,
          secondaryLabel: 'إغلاق',
          onSecondaryTap: () => Navigator.of(context).maybePop(),
        );
      },
    );
  }
}

class _RoleGuardStatusView extends StatelessWidget {
  const _RoleGuardStatusView({
    required this.title,
    required this.message,
    required this.loading,
    this.intendedPath,
    this.primaryLabel,
    this.onPrimaryTap,
    this.secondaryLabel,
    this.onSecondaryTap,
  });

  final String title;
  final String message;
  final bool loading;
  final String? intendedPath;
  final String? primaryLabel;
  final VoidCallback? onPrimaryTap;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              margin: const EdgeInsets.all(20),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: loading
                              ? const Color(0xFFE0F2FE)
                              : const Color(0xFFFEF3C7),
                          child: Icon(
                            loading ? Icons.hourglass_top_rounded : Icons.shield_outlined,
                            color: loading
                                ? const Color(0xFF0369A1)
                                : const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (loading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      message,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                    if ((intendedPath ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          'المسار المطلوب: ${intendedPath!.trim()}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                    if (!loading && primaryLabel != null) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton(
                            onPressed: onPrimaryTap,
                            child: Text(
                              primaryLabel!,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: onSecondaryTap,
                            child: Text(
                              secondaryLabel ?? 'رجوع',
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
