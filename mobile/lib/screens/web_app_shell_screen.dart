import 'package:flutter/material.dart';

import '../services/api_config.dart';

class WebAppShellScreen extends StatefulWidget {
  const WebAppShellScreen({super.key});

  @override
  State<WebAppShellScreen> createState() => _WebAppShellScreenState();
}

enum _Section {
  public('الواجهة العامة', Icons.public_rounded),
  client('لوحة العميل', Icons.person_rounded),
  provider('لوحة مقدم الخدمة', Icons.handyman_rounded);

  const _Section(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _WebAppShellScreenState extends State<WebAppShellScreen> {
  _Section _section = _Section.public;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, c) {
          final desktop = c.maxWidth >= 980;
          return Scaffold(
            drawer: desktop ? null : Drawer(child: _nav(isDrawer: true)),
            body: Row(
              children: [
                if (desktop)
                  SizedBox(
                    width: 260,
                    child: ColoredBox(color: const Color(0xFF0F172A), child: _nav(isDrawer: false)),
                  ),
                Expanded(child: _body(desktop)),
              ],
            ),
            bottomNavigationBar: desktop
                ? null
                : NavigationBar(
                    selectedIndex: _Section.values.indexOf(_section),
                    onDestinationSelected: (i) => setState(() => _section = _Section.values[i]),
                    destinations: _Section.values
                        .map((s) => NavigationDestination(icon: Icon(s.icon), label: s.label))
                        .toList(),
                  ),
          );
        },
      ),
    );
  }

  Widget _nav({required bool isDrawer}) {
    final dark = !isDrawer;
    final bg = dark ? const Color(0xFF0F172A) : Colors.white;
    final fg = dark ? Colors.white : const Color(0xFF111827);
    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('نوافذ Web Templates', style: TextStyle(color: fg, fontWeight: FontWeight.w800)),
              ),
            ),
            ..._Section.values.map((s) {
              final selected = s == _section;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: ListTile(
                  selected: selected,
                  selectedTileColor: dark ? const Color(0xFF1E293B) : const Color(0xFFEAF7F4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Icon(s.icon, color: selected ? const Color(0xFF0B8D7A) : (dark ? Colors.white70 : null)),
                  title: Text(
                    s.label,
                    style: TextStyle(color: selected ? (dark ? Colors.white : const Color(0xFF0B8D7A)) : fg),
                  ),
                  onTap: () {
                    Navigator.of(context).maybePop();
                    setState(() => _section = s);
                  },
                ),
              );
            }),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'النسخة منفصلة وآمنة لتجهيز واجهات الويب بدون كسر الجوال.',
                style: TextStyle(color: dark ? Colors.white70 : const Color(0xFF64748B), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(bool desktop) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          leading: desktop
              ? null
              : Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
          title: Text(_section.label, style: const TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('تسجيل الدخول'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0B8D7A), foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _hero(),
              const SizedBox(height: 12),
              _panel(
                title: 'حالة الربط',
                child: Text(
                  'API Base URL: ${ApiConfig.baseUrl}',
                  style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF334155)),
                ),
              ),
              const SizedBox(height: 12),
              _content(desktop),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _hero() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF0B8D7A)]),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('قوالب ويب لنفس تطبيق نوافذ', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            SizedBox(height: 6),
            Text(
              'واجهة أولية Responsive يمكن تطويرها تدريجيًا وربطها بالـ API الحالي (Django/DRF).',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
          ],
        ),
      );

  Widget _content(bool desktop) {
    final cols = desktop ? 2 : 1;
    final cards = switch (_section) {
      _Section.public => const [
          ('Landing Hero', 'تعريف المنصة + دعوات تسجيل/طلب خدمة'),
          ('Services Grid', 'عرض الأقسام والخدمات بشكل واضح'),
          ('Featured Providers', 'مقدمو خدمات مميزون + تقييمات'),
          ('FAQ / Contact', 'الأسئلة الشائعة وروابط التواصل'),
        ],
      _Section.client => const [
          ('طلباتي', 'حالات الطلبات: جديد / قيد التنفيذ / مكتمل'),
          ('المحادثات', 'قائمة المحادثات وربطها بكل طلب'),
          ('إجراءات سريعة', 'طلب جديد / تتبع / دعم'),
          ('الإشعارات', 'تنبيهات الطلبات والعروض'),
        ],
      _Section.provider => const [
          ('لوحة الأداء', 'الطلبات الجديدة، نسب القبول، الإيراد'),
          ('العروض', 'إرسال ومتابعة العروض بسرعة'),
          ('إدارة الخدمات', 'تحديث الخدمات والأسعار والتغطية'),
          ('التقييمات', 'عرض المراجعات والرد عليها'),
        ],
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: desktop ? 2.2 : 2.8,
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) => _templateCard(cards[i].$1, cards[i].$2),
    );
  }

  Widget _panel({required String title, required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ]),
      );

  Widget _templateCard(String title, String subtitle) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.web_rounded, color: Color(0xFF0B8D7A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF111827))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      );
}
