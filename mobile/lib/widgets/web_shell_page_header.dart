import 'package:flutter/material.dart';

class WebShellPageHeader extends StatelessWidget {
  const WebShellPageHeader({
    super.key,
    required this.panelLabel,
    required this.sectionLabel,
    required this.accentColor,
  });

  final String panelLabel;
  final String sectionLabel;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.home_work_outlined, size: 14, color: Color(0xFF64748B)),
              Text(
                panelLabel,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                '/',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Text(
                sectionLabel,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            sectionLabel,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
