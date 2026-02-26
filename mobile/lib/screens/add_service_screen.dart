import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../utils/auth_guard.dart';
import '../widgets/app_bar.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/custom_drawer.dart';
import 'request_quote_screen.dart';
import 'search_provider_screen.dart';
import 'urgent_request_screen.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _navigate(
    BuildContext context,
    Widget screen, {
    bool requireFullClient = false,
  }) async {
    if (requireFullClient) {
      final ok = await checkFullClient(context);
      if (!ok) return;
    }

    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F2FA),
        drawer: const CustomDrawer(),
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: CustomAppBar(
            title: 'نوع الخدمة',
            showSearchField: false,
            forceDrawerIcon: true,
          ),
        ),
        bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
        body: Stack(
          children: [
            Positioned(
              top: -140,
              right: -100,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryDark.withValues(alpha: 0.18),
                      AppColors.primaryLight.withValues(alpha: 0.03),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 90,
              left: -70,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7B63D2).withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -140,
              left: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentOrange.withValues(alpha: 0.14),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final metrics = _ScreenMetrics.fromWidth(
                    constraints.maxWidth,
                  );
                  final options = <_ServiceOptionData>[
                    _ServiceOptionData(
                      title: 'البحث عن مزود خدمة',
                      subtitle:
                          'استعرض مزودي الخدمة حسب الموقع والتقييم وسابقة الأعمال.',
                      badge: 'الأكثر استخداماً',
                      icon: Icons.travel_explore_rounded,
                      primary: const Color(0xFF5D4AA8),
                      secondary: const Color(0xFF7B63D2),
                      actionLabel: 'استعراض المزودين',
                      detail: 'انطلاقة سريعة',
                      onTap: () =>
                          _navigate(context, const SearchProviderScreen()),
                    ),
                    _ServiceOptionData(
                      title: 'طلب خدمة عاجلة',
                      subtitle:
                          'أرسل طلبًا فوريًا ليصل إلى المزودين القريبين والمتاحين الآن.',
                      badge: 'استجابة فورية',
                      icon: Icons.bolt_rounded,
                      primary: const Color(0xFFF1973D),
                      secondary: const Color(0xFFDE6A22),
                      actionLabel: 'إنشاء طلب عاجل',
                      detail: 'للحالات المستعجلة',
                      onTap: () => _navigate(
                        context,
                        const UrgentRequestScreen(),
                        requireFullClient: true,
                      ),
                    ),
                    _ServiceOptionData(
                      title: 'طلب عروض أسعار',
                      subtitle:
                          'صف احتياجك مرة واحدة واستلم عروضًا متعددة للمقارنة بثقة.',
                      badge: 'أفضل للتفاوض',
                      icon: Icons.request_quote_rounded,
                      primary: const Color(0xFF2D8B7B),
                      secondary: const Color(0xFF1F6B5F),
                      actionLabel: 'طلب عروض الآن',
                      detail: 'مقارنة ذكية',
                      onTap: () => _navigate(
                        context,
                        const RequestQuoteScreen(),
                        requireFullClient: true,
                      ),
                    ),
                  ];

                  final optionWidgets = List<Widget>.generate(options.length, (
                    index,
                  ) {
                    final item = options[index];
                    final begin = 0.16 + (index * 0.18);
                    final end = ((begin + 0.45).clamp(0.0, 1.0)).toDouble();

                    return SizedBox(
                      width: metrics.cardWidth(constraints.maxWidth),
                      child: _StaggeredEntrance(
                        controller: _entranceController,
                        begin: begin,
                        end: end,
                        child: _ServiceOptionCard(
                          compact: metrics.compact,
                          title: item.title,
                          subtitle: item.subtitle,
                          badge: item.badge,
                          icon: item.icon,
                          primary: item.primary,
                          secondary: item.secondary,
                          actionLabel: item.actionLabel,
                          detail: item.detail,
                          onTap: item.onTap,
                        ),
                      ),
                    );
                  });

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      metrics.horizontalPadding,
                      12,
                      metrics.horizontalPadding,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StaggeredEntrance(
                          controller: _entranceController,
                          begin: 0.00,
                          end: 0.34,
                          child: _HeroPanel(compact: metrics.compact),
                        ),
                        SizedBox(height: metrics.gap),
                        _StaggeredEntrance(
                          controller: _entranceController,
                          begin: 0.10,
                          end: 0.42,
                          child: _SectionLead(compact: metrics.compact),
                        ),
                        SizedBox(height: metrics.gap),
                        Wrap(
                          spacing: metrics.gap,
                          runSpacing: metrics.gap,
                          children: optionWidgets,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaggeredEntrance extends StatelessWidget {
  const _StaggeredEntrance({
    required this.controller,
    required this.begin,
    required this.end,
    required this.child,
  });

  final AnimationController controller;
  final double begin;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.11),
      end: Offset.zero,
    ).animate(curved);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 18,
        compact ? 14 : 18,
        compact ? 14 : 18,
        compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F3D98), Color(0xFF6D58C4), Color(0xFF8C78E8)],
          stops: [0.0, 0.58, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F3D98).withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: compact ? 110 : 128,
              height: compact ? 110 : 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: compact ? 40 : 46,
                height: compact ? 40 : 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                  ),
                ),
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white,
                  size: compact ? 22 : 24,
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Text(
                  'ابدأ طلبك',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: compact ? 15 : 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            'اختر نوع الخدمة وابدأ طلبك بخطوات واضحة وسريعة.',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: compact ? 11.5 : 12.5,
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.5,
            ),
          ),
          SizedBox(height: compact ? 10 : 12),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: compact ? 16 : 18,
                ),
                SizedBox(width: compact ? 8 : 10),
                Expanded(
                  child: Text(
                    'اختر المسار المناسب لاحتياجك: بحث مباشر، طلب عاجل، أو مقارنة عروض.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: compact ? 10.5 : 11.5,
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 10 : 12),
          Wrap(
            spacing: compact ? 6 : 8,
            runSpacing: compact ? 6 : 8,
            children: const [
              _HeroChip(label: 'مسار واضح'),
              _HeroChip(label: 'سرعة في التنفيذ'),
              _HeroChip(label: 'نتائج أدق'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLead extends StatelessWidget {
  const _SectionLead({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E2F7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF251A4F).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 36 : 40,
            height: compact ? 36 : 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF6B57BF), Color(0xFF8B75E7)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: const Icon(
              Icons.widgets_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: compact ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اختر مسار تنفيذ الخدمة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: compact ? 12.5 : 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E2550),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'كل بطاقة تقودك لرحلة مناسبة حسب السرعة ونمط التعاقد.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: compact ? 10.5 : 11.5,
                    color: const Color(0xFF6E6888),
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

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ServiceOptionCard extends StatelessWidget {
  const _ServiceOptionCard({
    required this.compact,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.primary,
    required this.secondary,
    required this.actionLabel,
    required this.detail,
    required this.onTap,
  });

  final bool compact;
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color primary;
  final Color secondary;
  final String actionLabel;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8E3F6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF251A4F).withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 11,
                  compact ? 8 : 9,
                  compact ? 10 : 11,
                  compact ? 8 : 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  gradient: LinearGradient(
                    colors: [primary, secondary],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: compact ? 34 : 38,
                      height: compact ? 34 : 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withValues(alpha: 0.18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: compact ? 18 : 19,
                      ),
                    ),
                    SizedBox(width: compact ? 7 : 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: compact ? 13.5 : 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 7 : 8,
                        vertical: compact ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: compact ? 9.5 : 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 11,
                  compact ? 9 : 10,
                  compact ? 10 : 11,
                  compact ? 10 : 11,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: compact ? 11.5 : 12.5,
                        color: const Color(0xFF5B5670),
                        height: 1.48,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 9),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 8 : 9,
                              vertical: compact ? 6 : 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F1FE),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFEAE5FC),
                              ),
                            ),
                            child: Text(
                              detail,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: compact ? 10 : 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF5A489B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: onTap,
                          style: TextButton.styleFrom(
                            foregroundColor: primary,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            textStyle: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: compact ? 11 : 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            size: compact ? 16 : 17,
                          ),
                          label: Text(actionLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceOptionData {
  const _ServiceOptionData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.primary,
    required this.secondary,
    required this.actionLabel,
    required this.detail,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color primary;
  final Color secondary;
  final String actionLabel;
  final String detail;
  final VoidCallback onTap;
}

class _ScreenMetrics {
  const _ScreenMetrics({
    required this.compact,
    required this.twoColumns,
    required this.horizontalPadding,
    required this.gap,
  });

  final bool compact;
  final bool twoColumns;
  final double horizontalPadding;
  final double gap;

  static _ScreenMetrics fromWidth(double width) {
    final compact = width < 390;
    final twoColumns = width >= 700;
    return _ScreenMetrics(
      compact: compact,
      twoColumns: twoColumns,
      horizontalPadding: twoColumns ? 20 : (compact ? 10 : 12),
      gap: twoColumns ? 14 : 12,
    );
  }

  double cardWidth(double maxWidth) {
    if (!twoColumns) return maxWidth - (horizontalPadding * 2);
    final available = maxWidth - (horizontalPadding * 2) - gap;
    return available / 2;
  }
}
