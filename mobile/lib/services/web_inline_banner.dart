import 'dart:async';

import 'package:flutter/foundation.dart';

enum WebInlineBannerKind { info, success, error }

@immutable
class WebInlineBannerState {
  const WebInlineBannerState({
    required this.visible,
    this.kind = WebInlineBannerKind.info,
    this.message,
  });

  final bool visible;
  final WebInlineBannerKind kind;
  final String? message;

  static const hidden = WebInlineBannerState(visible: false);
}

class WebInlineBannerController {
  WebInlineBannerController._();

  static final WebInlineBannerController instance = WebInlineBannerController._();

  final ValueNotifier<WebInlineBannerState> notifier =
      ValueNotifier<WebInlineBannerState>(WebInlineBannerState.hidden);

  Timer? _hideTimer;

  void show(
    String message, {
    WebInlineBannerKind kind = WebInlineBannerKind.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _hideTimer?.cancel();
    notifier.value = WebInlineBannerState(
      visible: true,
      kind: kind,
      message: message.trim(),
    );
    _hideTimer = Timer(duration, hide);
  }

  void success(String message, {Duration duration = const Duration(seconds: 3)}) {
    show(message, kind: WebInlineBannerKind.success, duration: duration);
  }

  void error(String message, {Duration duration = const Duration(seconds: 4)}) {
    show(message, kind: WebInlineBannerKind.error, duration: duration);
  }

  void info(String message, {Duration duration = const Duration(seconds: 3)}) {
    show(message, kind: WebInlineBannerKind.info, duration: duration);
  }

  void hide() {
    _hideTimer?.cancel();
    _hideTimer = null;
    notifier.value = WebInlineBannerState.hidden;
  }
}
