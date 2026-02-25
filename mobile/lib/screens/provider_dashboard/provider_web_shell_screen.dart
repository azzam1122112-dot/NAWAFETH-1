import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../services/role_controller.dart';
import '../../widgets/web_shell_account_actions.dart';
import '../../widgets/web_shell_page_header.dart';
import '../client_dashboard/client_notifications_web_screen.dart';
import 'provider_home_web_screen.dart';
import 'provider_orders_screen.dart';
import 'provider_profile_web_screen.dart';
import 'reviews_tab.dart';
import 'services_tab.dart';

enum ProviderWebSection {
  summary('الملخص', Icons.dashboard_outlined),
  orders('الطلبات', Icons.assignment_outlined),
  services('الخدمات', Icons.design_services_outlined),
  reviews('المراجعات', Icons.reviews_outlined),
  notifications('الإشعارات', Icons.notifications_outlined),
  profile('الملف الشخصي', Icons.person_outline_rounded);

  const ProviderWebSection(this.label, this.icon);
  final String label;
  final IconData icon;
}

class ProviderOrdersRouteState {
  const ProviderOrdersRouteState({
    this.tabIndex = 0,
    this.searchQuery,
    this.assignedStatus,
    this.urgentStatus,
  });

  final int tabIndex;
  final String? searchQuery;
  final String? assignedStatus;
  final String? urgentStatus;
}

class ProviderServicesRouteState {
  const ProviderServicesRouteState({
    this.searchQuery,
    this.statusFilter,
  });

  final String? searchQuery;
  final String? statusFilter;
}

class ProviderReviewsRouteState {
  const ProviderReviewsRouteState({
    this.searchQuery,
    this.replyFilter,
    this.minRating,
  });

  final String? searchQuery;
  final String? replyFilter;
  final int? minRating;
}

String _clientRouteForProviderSection(ProviderWebSection section) {
  return switch (section) {
    ProviderWebSection.summary => '/client_dashboard',
    ProviderWebSection.orders => '/client_dashboard/orders',
    ProviderWebSection.services => '/client_dashboard',
    ProviderWebSection.reviews => '/client_dashboard',
    ProviderWebSection.notifications => '/client_dashboard/notifications',
    ProviderWebSection.profile => '/client_dashboard/profile',
  };
}

Future<void> _switchProviderWebToClient(
  BuildContext context, {
  required ProviderWebSection currentSection,
}) async {
  await RoleController.instance.setProviderMode(false);
  if (!context.mounted) return;
  Navigator.pushNamedAndRemoveUntil(
    context,
    _clientRouteForProviderSection(currentSection),
    (r) => false,
  );
}

class ProviderWebShellScreen extends StatelessWidget {
  const ProviderWebShellScreen({
    super.key,
    required this.section,
    this.ordersRouteState,
    this.servicesRouteState,
    this.reviewsRouteState,
  });

  final ProviderWebSection section;
  final ProviderOrdersRouteState? ordersRouteState;
  final ProviderServicesRouteState? servicesRouteState;
  final ProviderReviewsRouteState? reviewsRouteState;

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'نوافذ | لوحة مقدم الخدمة | ${section.label}',
      color: AppColors.deepPurple,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, c) {
            final desktop = c.maxWidth >= 1024;
            final tablet = c.maxWidth >= 760;

            return Scaffold(
            drawer: desktop ? null : Drawer(child: _SideNav(section: section)),
            backgroundColor: const Color(0xFFF6F7FB),
            body: Row(
              children: [
                if (desktop)
                  SizedBox(
                    width: 270,
                    child: ColoredBox(
                      color: const Color(0xFF101828),
                      child: _SideNav(section: section),
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(section: section, showMenu: !desktop),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(desktop ? 18 : (tablet ? 14 : 10)),
                          child: _ContentCard(
                            section: section,
                            child: _SectionBody(
                              section: section,
                              ordersRouteState: ordersRouteState,
                              servicesRouteState: servicesRouteState,
                              reviewsRouteState: reviewsRouteState,
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.section, required this.showMenu});

  final ProviderWebSection section;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
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
              Icon(section.icon, color: AppColors.deepPurple),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.label,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'إدارة مقدم الخدمة - نسخة ويب',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/provider_dashboard'),
                icon: const Icon(Icons.dashboard_outlined, size: 18),
                label: const Text('لوحتي', style: TextStyle(fontFamily: 'Cairo')),
              ),
              const SizedBox(width: 4),
              OutlinedButton.icon(
                onPressed: () => _switchProviderWebToClient(
                  context,
                  currentSection: section,
                ),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('وضع العميل', style: TextStyle(fontFamily: 'Cairo')),
              ),
              const SizedBox(width: 6),
              const WebShellAccountActions(
                roleLabel: 'مزود',
                accentColor: Color(0xFF7C3AED),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({required this.section});

  final ProviderWebSection section;

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
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نوافذ',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'لوحة مقدم الخدمة (Web)',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Color(0xFFCBD5E1),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _navTile(
            context,
            label: 'لوحة الملخص',
            icon: Icons.dashboard_outlined,
            route: '/provider_dashboard',
            selected: section == ProviderWebSection.summary,
          ),
          const SizedBox(height: 6),
          ...ProviderWebSection.values.map((s) {
            final route = switch (s) {
              ProviderWebSection.summary => '/provider_dashboard',
              ProviderWebSection.orders => '/provider_dashboard/orders',
              ProviderWebSection.services => '/provider_dashboard/services',
              ProviderWebSection.reviews => '/provider_dashboard/reviews',
              ProviderWebSection.notifications => '/provider_dashboard/notifications',
              ProviderWebSection.profile => '/provider_dashboard/profile',
            };
            return _navTile(
              context,
              label: s.label,
              icon: s.icon,
              route: route,
              selected: s == section,
            );
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _switchProviderWebToClient(
                    context,
                    currentSection: section,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF475569)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('التبديل لوضع العميل', style: TextStyle(fontFamily: 'Cairo')),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF475569)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('العودة للرئيسية', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String route,
    required bool selected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: ListTile(
        selected: selected,
        selectedTileColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: selected ? Colors.white : const Color(0xFFCBD5E1),
        ),
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

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.section, required this.child});

  final ProviderWebSection section;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          WebShellPageHeader(
            panelLabel: 'لوحة مقدم الخدمة',
            sectionLabel: section.label,
            accentColor: AppColors.deepPurple,
          ),
          const Divider(height: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({
    required this.section,
    this.ordersRouteState,
    this.servicesRouteState,
    this.reviewsRouteState,
  });

  final ProviderWebSection section;
  final ProviderOrdersRouteState? ordersRouteState;
  final ProviderServicesRouteState? servicesRouteState;
  final ProviderReviewsRouteState? reviewsRouteState;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case ProviderWebSection.summary:
        return const ProviderHomeWebScreen(embedded: true);
      case ProviderWebSection.orders:
        final state = ordersRouteState;
        return ProviderOrdersScreen(
          embedded: true,
          initialTabIndex: state?.tabIndex ?? 0,
          initialSearchQuery: state?.searchQuery,
          initialAssignedStatus: state?.assignedStatus,
          initialUrgentStatus: state?.urgentStatus,
        );
      case ProviderWebSection.services:
        return ServicesTab(
          embedded: true,
          initialSearchQuery: servicesRouteState?.searchQuery,
          initialStatusFilter: servicesRouteState?.statusFilter,
        );
      case ProviderWebSection.reviews:
        return ReviewsTab(
          embedded: true,
          allowProviderReply: true,
          initialSearchQuery: reviewsRouteState?.searchQuery,
          initialReplyFilter: reviewsRouteState?.replyFilter,
          initialMinRating: reviewsRouteState?.minRating,
        );
      case ProviderWebSection.notifications:
        return const ClientNotificationsWebScreen(embedded: true);
      case ProviderWebSection.profile:
        return const ProviderProfileWebScreen(embedded: true);
    }
  }
}
