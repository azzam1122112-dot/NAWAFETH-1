import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../services/web_inline_banner.dart';

class PlatformFeedback {
  const PlatformFeedback._();

  static void show(
    BuildContext context,
    String message, {
    bool error = false,
    bool success = false,
  }) {
    final text = message.trim();
    if (text.isEmpty) return;

    if (kIsWeb) {
      if (error) {
        WebInlineBannerController.instance.error(text);
      } else if (success) {
        WebInlineBannerController.instance.success(text);
      } else {
        WebInlineBannerController.instance.info(text);
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: error ? Colors.red : (success ? Colors.green : null),
      ),
    );
  }
}
