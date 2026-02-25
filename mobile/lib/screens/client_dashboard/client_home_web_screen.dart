import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../services/account_api.dart';
import '../../services/marketplace_api.dart';
import '../../services/web_inline_banner.dart';
import '../../services/web_loading_overlay.dart';

class ClientHomeWebScreen extends StatefulWidget {
  const ClientHomeWebScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ClientHomeWebScreen> createState() => _ClientHomeWebScreenState();
}

class _ClientHomeWebScreenState extends State<ClientHomeWebScreen> {
  late Future<_ClientHomeVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ClientHomeVm> _load() async {
    final me = await AccountApi().me(forceRefresh: true);
    final orders = await MarketplaceApi().getMyRequests();

    int newCount = 0;
    int progressCount = 0;
    int completedCount = 0;
    int cancelledCount = 0;
    final recent = <Map<String, dynamic>>[];

    for (final row in orders) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      recent.add(map);
      final status = (map['status_group'] ?? map['status'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (status.contains('complete')) {
        completedCount++;
      } else if (status.contains('cancel')) {
        cancelledCount++;
      } else if (status.contains('progress') || status.contains('accepted')) {
        progressCount++;
      } else {
        newCount++;
      }
    }

    recent.sort((a, b) => (b['id'] ?? 0).toString().compareTo((a['id'] ?? 0).toString()));

    final fullName = [
      (me['first_name'] ?? '').toString().trim(),
      (me['last_name'] ?? '').toString().trim(),
    ].where((e) => e.isNotEmpty).join(' ');

    return _ClientHomeVm(
      displayName: fullName.isEmpty ? ((me['username'] ?? '').toString().trim().isEmpty ? 'عميل' : (me['username'] ?? '').toString().trim()) : fullName,
      username: (me['username'] ?? '').toString().trim(),
      phone: (me['phone'] ?? '').toString().trim(),
      totalOrders: recent.length,
      newOrders: newCount,
      inProgressOrders: progressCount,
      completedOrders: completedCount,
      cancelledOrders: cancelledCount,
      recentOrders: recent.take(6).toList(),
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _refreshWithOverlay() {
    return WebLoadingOverlayController.instance.run(
      () async {
        try {
          await _refresh();
          WebInlineBannerController.instance.success('تم تحديث لوحة العميل.');
        } catch (_) {
          WebInlineBannerController.instance.error('تعذر تحديث لوحة العميل.');
          rethrow;
        }
      },
      message: 'جاري تحديث لوحة العميل...',
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<_ClientHomeVm>(
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
                const SizedBox(height: 8),
                const Text(
                  'تعذر تحميل لوحة العميل',
                  style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _refreshWithOverlay,
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
              final desktop = c.maxWidth >= 1000;
              final tablet = c.maxWidth >= 700;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ClientHeaderCard(vm: vm),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: desktop ? 4 : (tablet ? 2 : 1),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: desktop ? 2.1 : 2.6,
                    children: [
                      _StatTile('إجمالي الطلبات', vm.totalOrders.toString(), Icons.list_alt_rounded, Colors.blue),
                      _StatTile('طلبات جديدة', vm.newOrders.toString(), Icons.fiber_new_rounded, Colors.orange),
                      _StatTile('قيد التنفيذ', vm.inProgressOrders.toString(), Icons.pending_actions_rounded, Colors.teal),
                      _StatTile('مكتملة', vm.completedOrders.toString(), Icons.check_circle_rounded, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _RecentOrdersPanel(orders: vm.recentOrders)),
                        const SizedBox(width: 14),
                        const Expanded(flex: 2, child: _QuickActionsPanel()),
                      ],
                    )
                  else ...[
                    const _QuickActionsPanel(),
                    const SizedBox(height: 14),
                    _RecentOrdersPanel(orders: vm.recentOrders),
                  ],
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
        appBar: AppBar(
          title: const Text('لوحة العميل (Web)'),
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
}

class _ClientHomeVm {
  const _ClientHomeVm({
    required this.displayName,
    required this.username,
    required this.phone,
    required this.totalOrders,
    required this.newOrders,
    required this.inProgressOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.recentOrders,
  });

  final String displayName;
  final String username;
  final String phone;
  final int totalOrders;
  final int newOrders;
  final int inProgressOrders;
  final int completedOrders;
  final int cancelledOrders;
  final List<Map<String, dynamic>> recentOrders;
}

class _ClientHeaderCard extends StatelessWidget {
  const _ClientHeaderCard({required this.vm});
  final _ClientHomeVm vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0B2C5F), AppColors.deepPurple, Color(0xFF7B67C7)],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withAlpha(40),
            child: const Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحبًا ${vm.displayName}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (vm.username.isNotEmpty) '@${vm.username}',
                    if (vm.phone.isNotEmpty) vm.phone,
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
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/client_dashboard/orders'),
            icon: const Icon(Icons.assignment_outlined, color: Colors.white),
            label: const Text('طلباتي', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.title, this.value, this.icon, this.color);
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

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel();

  @override
  Widget build(BuildContext context) {
    Widget action(String label, IconData icon, String route) {
      return OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontFamily: 'Cairo')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          action('طلباتي', Icons.assignment_outlined, '/client_dashboard/orders'),
          action('الرئيسية', Icons.home_outlined, '/home'),
          action('الإشعارات', Icons.notifications_outlined, '/client_dashboard/notifications'),
          action('الملف الشخصي', Icons.person_outline_rounded, '/client_dashboard/profile'),
          action('المدخل', Icons.door_front_door_outlined, '/entry'),
        ],
      ),
    );
  }
}

class _RecentOrdersPanel extends StatelessWidget {
  const _RecentOrdersPanel({required this.orders});
  final List<Map<String, dynamic>> orders;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'آخر الطلبات',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),
          if (orders.isEmpty)
            const Text(
              'لا توجد طلبات حالياً.',
              style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF64748B)),
            )
          else
            ...orders.map((o) {
              final title = (o['title'] ?? 'طلب خدمة').toString();
              final status = (o['status_label'] ?? o['status_group'] ?? o['status'] ?? '').toString();
              final city = (o['city'] ?? '').toString();
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
                    const Icon(Icons.assignment_rounded, color: AppColors.deepPurple, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      [if (city.isNotEmpty) city, if (status.isNotEmpty) status].join(' • '),
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
