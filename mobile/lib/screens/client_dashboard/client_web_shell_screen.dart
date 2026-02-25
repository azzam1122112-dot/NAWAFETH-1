import 'package:flutter/material.dart';

import '../client_orders_screen.dart';
import '../../services/app_snackbar.dart';
import '../../services/role_controller.dart';
import '../../utils/auth_guard.dart';
import '../../widgets/web_shell_account_actions.dart';
import '../../widgets/web_shell_page_header.dart';
import 'client_notifications_web_screen.dart';
import 'client_profile_web_screen.dart';
import 'client_home_web_screen.dart';

enum ClientWebSection {
  summary('الملخص', Icons.dashboard_outlined),
  orders('طلباتي', Icons.assignment_outlined),
  notifications('الإشعارات', Icons.notifications_outlined),
  profile('الملف الشخصي', Icons.person_outline_rounded);

  const ClientWebSection(this.label, this.icon);
  final String label;
  final IconData icon;
}

class ClientOrdersRouteState {
  const ClientOrdersRouteState({
    this.searchQuery,
    this.statusFilter,
    this.typeFilter,
  });

  final String? searchQuery;
  final String? statusFilter;
  final String? typeFilter;
}

String _providerRouteForClientSection(ClientWebSection section) {
  return switch (section) {
    ClientWebSection.summary => '/provider_dashboard',
    ClientWebSection.orders => '/provider_dashboard/orders',
    ClientWebSection.notifications => '/provider_dashboard/notifications',
    ClientWebSection.profile => '/provider_dashboard/profile',
  };
}

Future<void> _switchClientWebToProvider(
  BuildContext context, {
  required ClientWebSection currentSection,
}) async {
  if (!await checkFullClient(context)) return;
  if (!context.mounted) return;

  try {
    await RoleController.instance.syncFromBackend();
    await RoleController.instance.refreshFromPrefs();
  } catch (_) {
    // best-effort
  }

  if (!context.mounted) return;
  final role = RoleController.instance.notifier.value;
  if (!role.isProviderRegistered) {
    AppSnackBar.error('حسابك عميل فقط حالياً. سجّل كمقدم خدمة أولاً.');
    return;
  }

  await RoleController.instance.setProviderMode(true);
  if (!context.mounted) return;
  Navigator.pushNamedAndRemoveUntil(
    context,
    _providerRouteForClientSection(currentSection),
    (r) => false,
  );
}

class ClientWebShellScreen extends StatelessWidget {
  const ClientWebShellScreen({
    super.key,
    required this.section,
    this.ordersRouteState,
  });

  final ClientWebSection section;
  final ClientOrdersRouteState? ordersRouteState;

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'نوافذ | لوحة العميل | ${section.label}',
      color: const Color(0xFF5E35B1),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, c) {
            final desktop = c.maxWidth >= 1024;
            return Scaffold(
            drawer: desktop ? null : Drawer(child: _ClientSideNav(section: section)),
            backgroundColor: const Color(0xFFF6F7FB),
            body: Row(
              children: [
                if (desktop)
                  SizedBox(
                    width: 260,
                    child: ColoredBox(
                      color: const Color(0xFF0F172A),
                      child: _ClientSideNav(section: section),
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _ClientTopBar(section: section, showMenu: !desktop),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                WebShellPageHeader(
                                  panelLabel: 'لوحة العميل',
                                  sectionLabel: section.label,
                                  accentColor: const Color(0xFF5E35B1),
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  child: _ClientSectionBody(
                                    section: section,
                                    ordersRouteState: ordersRouteState,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            );
          },
        ),
      ),
    );
  }
}

class _ClientTopBar extends StatelessWidget {
  const _ClientTopBar({required this.section, required this.showMenu});
  final ClientWebSection section;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (showMenu)
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
              if (showMenu) const SizedBox(width: 6),
              Icon(section.icon, color: const Color(0xFF5E35B1)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'لوحة العميل - ${section.label}',
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/home'),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('الرئيسية', style: TextStyle(fontFamily: 'Cairo')),
              ),
              const SizedBox(width: 4),
              ValueListenableBuilder<RoleState>(
                valueListenable: RoleController.instance.notifier,
                builder: (context, role, _) {
                  if (!role.isProviderRegistered) return const SizedBox.shrink();
                  return OutlinedButton.icon(
                    onPressed: () => _switchClientWebToProvider(
                      context,
                      currentSection: section,
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text(
                      'وضع المزود',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              const WebShellAccountActions(
                roleLabel: 'عميل',
                accentColor: Color(0xFF5E35B1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientSideNav extends StatelessWidget {
  const _ClientSideNav({required this.section});
  final ClientWebSection section;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'لوحة العميل (Web)',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _tile(context, 'الملخص', Icons.dashboard_outlined, '/client_dashboard', section == ClientWebSection.summary),
          _tile(context, 'طلباتي', Icons.assignment_outlined, '/client_dashboard/orders', section == ClientWebSection.orders),
          _tile(context, 'الإشعارات', Icons.notifications_outlined, '/client_dashboard/notifications', section == ClientWebSection.notifications),
          _tile(context, 'الملف الشخصي', Icons.person_outline_rounded, '/client_dashboard/profile', section == ClientWebSection.profile),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: ValueListenableBuilder<RoleState>(
              valueListenable: RoleController.instance.notifier,
              builder: (context, role, _) {
                if (!role.isProviderRegistered) return const SizedBox.shrink();
                return OutlinedButton.icon(
                  onPressed: () => _switchClientWebToProvider(
                    context,
                    currentSection: section,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF475569)),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text(
                    'التبديل لوضع المزود',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String label, IconData icon, String route, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListTile(
        selected: selected,
        selectedTileColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: selected ? Colors.white : const Color(0xFFCBD5E1)),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            color: selected ? Colors.white : const Color(0xFFE2E8F0),
            fontWeight: FontWeight.w700,
          ),
        ),
        onTap: () {
          Navigator.of(context).maybePop();
          if (ModalRoute.of(context)?.settings.name == route) return;
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}

class _ClientSectionBody extends StatelessWidget {
  const _ClientSectionBody({
    required this.section,
    this.ordersRouteState,
  });
  final ClientWebSection section;
  final ClientOrdersRouteState? ordersRouteState;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case ClientWebSection.summary:
        return const ClientHomeWebScreen(embedded: true);
      case ClientWebSection.orders:
        return ClientOrdersScreen(
          embedded: true,
          initialSearchQuery: ordersRouteState?.searchQuery,
          initialStatusFilter: ordersRouteState?.statusFilter,
          initialTypeFilter: ordersRouteState?.typeFilter,
        );
      case ClientWebSection.notifications:
        return const ClientNotificationsWebScreen(embedded: true);
      case ClientWebSection.profile:
        return const ClientProfileWebScreen(embedded: true);
    }
  }
}
