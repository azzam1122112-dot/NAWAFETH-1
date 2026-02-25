import 'package:flutter/material.dart';

import '../services/web_inline_banner.dart';

class WebGlobalInlineBannerOverlay extends StatelessWidget {
  const WebGlobalInlineBannerOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WebInlineBannerState>(
      valueListenable: WebInlineBannerController.instance.notifier,
      builder: (context, state, _) {
        return Stack(
          children: [
            child,
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: IgnorePointer(
                ignoring: !state.visible,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: !state.visible
                      ? const SizedBox.shrink()
                      : _BannerCard(
                          key: ValueKey('${state.kind}:${state.message}'),
                          state: state,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    super.key,
    required this.state,
  });

  final WebInlineBannerState state;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, icon) = switch (state.kind) {
      WebInlineBannerKind.success => (
          const Color(0xFFF0FDF4),
          const Color(0xFF86EFAC),
          const Color(0xFF166534),
          Icons.check_circle_rounded,
        ),
      WebInlineBannerKind.error => (
          const Color(0xFFFEF2F2),
          const Color(0xFFFCA5A5),
          const Color(0xFF991B1B),
          Icons.error_rounded,
        ),
      WebInlineBannerKind.info => (
          const Color(0xFFEFF6FF),
          const Color(0xFF93C5FD),
          const Color(0xFF1D4ED8),
          Icons.info_rounded,
        ),
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Material(
          elevation: 2,
          color: bg,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (state.message ?? '').trim(),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        color: fg,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: WebInlineBannerController.instance.hide,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(Icons.close_rounded, size: 18, color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
