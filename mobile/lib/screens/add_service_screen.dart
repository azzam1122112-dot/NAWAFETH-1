import 'package:flutter/material.dart';

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
        backgroundColor: const Color(0xFFF7F4EE),
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
              top: -120,
              right: -90,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF5B3EA6).withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0.01),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: -60,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(38),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2A9D8F).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF08A35).withValues(alpha: 0.14),
                      Colors.white.withValues(alpha: 0.01),
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
        compact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF3A276F), Color(0xFF5A40A8), Color(0xFF7B63D6)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A276F).withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'مسار طلب مناسب',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: compact ? 10 : 10.8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                width: compact ? 44 : 50,
                height: compact ? 44 : 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: Colors.white,
                  size: compact ? 22 : 26,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ابدأ طلبك',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: compact ? 24 : 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اختر نوع الخدمة وابدأ فورًا بخطوات واضحة وسريعة تناسب جميع المستخدمين.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: compact ? 11.5 : 12.5,
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: compact ? 76 : 86,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 10,
                  vertical: compact ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '3',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: compact ? 18 : 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'مسارات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                Expanded(
                  child: _heroMetric(
                    compact: compact,
                    icon: Icons.speed_rounded,
                    label: 'سرعة البدء',
                    value: 'خطوات قليلة',
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
                Expanded(
                  child: _heroMetric(
                    compact: compact,
                    icon: Icons.compare_arrows_rounded,
                    label: 'خيارات متعددة',
                    value: 'بحث / عاجل / عروض',
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
              _HeroChip(label: 'بحث مباشر'),
              _HeroChip(label: 'طلب عاجل'),
              _HeroChip(label: 'مقارنة عروض'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric({
    required bool compact,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: compact ? 13 : 14, color: Colors.white),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: compact ? 9.4 : 10.4,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
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
        vertical: compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E0D7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF251A4F).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: compact ? 38 : 42,
                height: compact ? 38 : 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF2ECFF),
                ),
                child: const Icon(
                  Icons.account_tree_outlined,
                  color: Color(0xFF5D45B5),
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
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2E2550),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'كل بطاقة تقودك لرحلة مختلفة حسب السرعة وطريقة التعاقد.',
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
          SizedBox(height: compact ? 10 : 12),
          Row(
            children: [
              Expanded(child: _stepBadge(compact, '1', 'حدد احتياجك')),
              _leadConnector(),
              Expanded(child: _stepBadge(compact, '2', 'اختر المسار')),
              _leadConnector(),
              Expanded(child: _stepBadge(compact, '3', 'ابدأ الطلب')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _leadConnector() => Container(
    width: 14,
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: const Color(0xFFE7E0D7),
  );

  Widget _stepBadge(bool compact, String no, String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6EF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7E0D7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF5D45B5),
              shape: BoxShape.circle,
            ),
            child: Text(
              no,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: compact ? 9.8 : 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF413758),
              ),
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
    final surfaceTint = primary.withValues(alpha: 0.035);
    final borderColor = primary.withValues(alpha: 0.14);
    final chipBg = primary.withValues(alpha: 0.09);
    final chipBorder = primary.withValues(alpha: 0.16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.07),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(
                  compact ? 12 : 14,
                  compact ? 11 : 13,
                  compact ? 12 : 14,
                  compact ? 12 : 13,
                ),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      primary.withValues(alpha: 0.96),
                      secondary.withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: compact ? 38 : 42,
                      height: compact ? 38 : 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withValues(alpha: 0.16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: compact ? 19 : 21,
                      ),
                    ),
                    SizedBox(width: compact ? 9 : 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: compact ? 13.5 : 14.8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: compact ? 10.3 : 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.90),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 9,
                        vertical: compact ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: compact ? 9.3 : 10.2,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  compact ? 12 : 14,
                  compact ? 11 : 12,
                  compact ? 12 : 14,
                  compact ? 12 : 13,
                ),
                decoration: BoxDecoration(
                  color: surfaceTint,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 9 : 10,
                        vertical: compact ? 7 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE9E2D8)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: compact ? 24 : 26,
                            height: compact ? 24 : 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.route_rounded,
                              color: primary,
                              size: compact ? 14 : 15,
                            ),
                          ),
                          SizedBox(width: compact ? 7 : 8),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: compact ? 11.2 : 12.1,
                                color: const Color(0xFF555064),
                                height: 1.33,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 11),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _miniStatChip(
                          compact: compact,
                          label: detail,
                          icon: Icons.bolt_rounded,
                          color: primary,
                          bg: chipBg,
                          border: chipBorder,
                        ),
                        _miniStatChip(
                          compact: compact,
                          label: badge,
                          icon: Icons.verified_outlined,
                          color: const Color(0xFF6A617B),
                          bg: const Color(0xFFF7F4EE),
                          border: const Color(0xFFE6DED2),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 11 : 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 10 : 12,
                                vertical: compact ? 11 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_back_rounded,
                                  size: compact ? 16 : 17,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    actionLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: compact ? 11.2 : 12.1,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: compact ? 8 : 9),
                        Container(
                          width: compact ? 42 : 44,
                          height: compact ? 42 : 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: primary,
                            size: compact ? 20 : 22,
                          ),
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

  Widget _miniStatChip({
    required bool compact,
    required String label,
    required IconData icon,
    required Color color,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 10,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: compact ? 9.8 : 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
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
