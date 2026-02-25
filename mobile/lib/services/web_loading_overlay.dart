import 'package:flutter/foundation.dart';

@immutable
class WebLoadingOverlayState {
  const WebLoadingOverlayState({
    required this.visible,
    this.message,
  });

  final bool visible;
  final String? message;

  static const hidden = WebLoadingOverlayState(visible: false);
}

class WebLoadingOverlayController {
  WebLoadingOverlayController._();

  static final WebLoadingOverlayController instance =
      WebLoadingOverlayController._();

  final ValueNotifier<WebLoadingOverlayState> notifier =
      ValueNotifier<WebLoadingOverlayState>(WebLoadingOverlayState.hidden);

  void show([String? message]) {
    notifier.value = WebLoadingOverlayState(visible: true, message: message);
  }

  void hide() {
    notifier.value = WebLoadingOverlayState.hidden;
  }

  Future<T> run<T>(
    Future<T> Function() action, {
    String? message,
  }) async {
    show(message);
    try {
      return await action();
    } finally {
      hide();
    }
  }
}
