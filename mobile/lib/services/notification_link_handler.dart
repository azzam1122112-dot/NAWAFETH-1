import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/client_order.dart';
import '../models/provider_order.dart';
import '../screens/client_order_details_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/provider_dashboard/provider_order_details_screen.dart';
import 'chat_nav.dart';
import 'marketplace_api.dart';
import 'role_controller.dart';

class NotificationLinkHandler {
  static final RegExp _requestChatPath = RegExp(r'^/?requests/(\d+)/chat/?$', caseSensitive: false);
  static final RegExp _requestPath = RegExp(r'^/?requests/(\d+)/?$', caseSensitive: false);
  static final RegExp _threadPath = RegExp(r'^/?thread[s]?/(\d+)(?:/chat)?/?$', caseSensitive: false);
  static final RegExp _supportTicketPath = RegExp(r'^/?support/tickets/(\d+)/?$', caseSensitive: false);

  static int? tryExtractRequestId({
    required String kind,
    required String? url,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) {
    final target = _resolveTarget(
      kind: kind,
      url: url,
      title: title,
      body: body,
      payload: payload,
    );
    return target?.requestId;
  }

  static Future<bool> openRequestDetails(
    BuildContext context, {
    required int requestId,
  }) {
    return _openRequestDetails(context, requestId: requestId);
  }

  static Future<bool> openFromNotification(BuildContext context, AppNotification notification) async {
    final target = _resolveTarget(
      kind: notification.kind,
      url: notification.url,
      title: notification.title,
      body: notification.body,
    );
    assert(() {
      debugPrint(
        '[NotificationLinkHandler] openFromNotification kind=${notification.kind} url=${notification.url} -> '
        'threadId=${target?.threadId} requestId=${target?.requestId} isDirect=${target?.isDirect}',
      );
      return true;
    }());
    if (target == null) return false;
    return _openTarget(context, target, fallbackName: notification.title);
  }

  static Future<bool> openFromPayload(
    BuildContext context, {
    required Map<String, dynamic> payload,
  }) async {
    final kind = (payload['kind'] ?? payload['type'] ?? '').toString();
    final url = (payload['url'] ?? payload['deep_link'] ?? '').toString();
    final title = (payload['title'] ?? '').toString();
    final body = (payload['body'] ?? '').toString();
    final target = _resolveTarget(
      kind: kind,
      url: url,
      title: title,
      body: body,
      payload: payload,
    );
    assert(() {
      debugPrint(
        '[NotificationLinkHandler] openFromPayload kind=$kind url=$url -> '
        'threadId=${target?.threadId} requestId=${target?.requestId} isDirect=${target?.isDirect}',
      );
      return true;
    }());
    if (target == null) return false;
    return _openTarget(context, target, fallbackName: title);
  }

  static Future<bool> _openTarget(
    BuildContext context,
    _Target target, {
    required String fallbackName,
  }) async {
    if (target.openRequestDetails && target.requestId != null) {
      return _openRequestDetails(context, requestId: target.requestId!);
    }
    if (target.supportTicketId != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContactScreen(initialTicketId: target.supportTicketId),
        ),
      );
      return true;
    }
    if (target.threadId != null || target.requestId != null) {
      await ChatNav.openThread(
        context,
        requestId: target.requestId,
        threadId: target.threadId,
        isDirect: target.isDirect,
        name: fallbackName.trim().isEmpty ? 'محادثة الطلب' : fallbackName.trim(),
      );
      return true;
    }
    if (target.openInbox) {
      await ChatNav.openInbox(context);
      return true;
    }
    return false;
  }

  static _Target? _resolveTarget({
    required String kind,
    required String? url,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) {
    final isDirectFromPayload = _extractIsDirectFromPayload(payload) ?? false;

    final threadIdFromPayload = _extractThreadIdFromPayload(payload);
    if (threadIdFromPayload != null) {
      final requestIdFromPayload = _extractRequestIdFromPayload(payload);
      return _Target(
        threadId: threadIdFromPayload,
        requestId: requestIdFromPayload,
        supportTicketId: null,
        isDirect: isDirectFromPayload || (requestIdFromPayload == null && _isDirectThreadUrl(kind: kind, url: url)),
        openInbox: false,
        openRequestDetails: false,
      );
    }

    final supportTicketIdFromPayload = _extractSupportTicketIdFromPayload(payload);
    if (supportTicketIdFromPayload != null) {
      return _Target(
        threadId: null,
        requestId: null,
        supportTicketId: supportTicketIdFromPayload,
        isDirect: false,
        openInbox: false,
        openRequestDetails: false,
      );
    }

    final threadIdFromUrl = _extractThreadIdFromUrl(url);
    if (threadIdFromUrl != null) {
      return _Target(
        threadId: threadIdFromUrl,
        requestId: _extractRequestIdFromUrl(url),
        supportTicketId: null,
        isDirect: isDirectFromPayload || _isDirectThreadUrl(kind: kind, url: url),
        openInbox: false,
        openRequestDetails: false,
      );
    }

    final requestIdFromUrl = _extractRequestIdFromUrl(url);
    if (requestIdFromUrl != null) {
      return _Target(
        threadId: null,
        requestId: requestIdFromUrl,
        supportTicketId: null,
        isDirect: false,
        openInbox: false,
        openRequestDetails: !_isChatUrl(url),
      );
    }

    final supportTicketIdFromUrl = _extractSupportTicketIdFromUrl(url);
    if (supportTicketIdFromUrl != null) {
      return _Target(
        threadId: null,
        requestId: null,
        supportTicketId: supportTicketIdFromUrl,
        isDirect: false,
        openInbox: false,
        openRequestDetails: false,
      );
    }

    final requestIdFromText = _extractRequestIdFromText('$title $body');
    if (requestIdFromText != null && _isMessageKind(kind)) {
      return _Target(
        threadId: null,
        requestId: requestIdFromText,
        supportTicketId: null,
        isDirect: false,
        openInbox: false,
        openRequestDetails: false,
      );
    }

    if (_isMessageKind(kind)) {
      return const _Target(
        threadId: null,
        requestId: null,
        supportTicketId: null,
        isDirect: false,
        openInbox: true,
        openRequestDetails: false,
      );
    }
    return null;
  }

  static Future<bool> _openRequestDetails(
    BuildContext context, {
    required int requestId,
  }) async {
    final isProvider = RoleController.instance.notifier.value.isProvider;
    if (isProvider) {
      return _openProviderRequestDetails(context, requestId: requestId);
    }
    return _openClientRequestDetails(context, requestId: requestId);
  }

  static Future<bool> _openClientRequestDetails(
    BuildContext context, {
    required int requestId,
  }) async {
    final data = await MarketplaceApi().getMyRequestDetail(requestId: requestId);
    if (data == null || !context.mounted) return false;

    final order = ClientOrder.fromJson(data);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientOrderDetailsScreen(order: order),
      ),
    );
    return true;
  }

  static Future<bool> _openProviderRequestDetails(
    BuildContext context, {
    required int requestId,
  }) async {
    final data = await MarketplaceApi().getProviderRequestDetail(requestId: requestId);
    if (data == null || !context.mounted) return false;

    final order = _toProviderOrder(data, requestId: requestId);
    final logs = (data['status_logs'] is List)
        ? (data['status_logs'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : const <Map<String, dynamic>>[];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderOrderDetailsScreen(
          order: order,
          requestId: requestId,
          rawStatus: (data['status'] ?? '').toString(),
          requestType: (data['request_type'] ?? '').toString(),
          statusLogs: logs,
        ),
      ),
    );
    return true;
  }

  static ProviderOrder _toProviderOrder(
    Map<String, dynamic> data, {
    required int requestId,
  }) {
    DateTime parseDate(dynamic raw) =>
        DateTime.tryParse((raw ?? '').toString()) ?? DateTime.now();

    final attachments = <ProviderOrderAttachment>[];
    if (data['attachments'] is List) {
      for (final item in (data['attachments'] as List)) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final type = (map['file_type'] ?? 'file').toString();
        final url = (map['file_url'] ?? '').toString();
        attachments.add(
          ProviderOrderAttachment(
            name: url.isEmpty ? 'مرفق' : url,
            type: type,
          ),
        );
      }
    }

    final statusLabel = (data['status_label'] ?? '').toString().trim();
    final rawStatus = (data['status'] ?? '').toString();
    return ProviderOrder(
      id: '#$requestId',
      serviceCode: (data['subcategory_name'] ?? '').toString(),
      createdAt: parseDate(data['created_at']),
      status: statusLabel.isNotEmpty ? statusLabel : _mapStatus(rawStatus),
      clientName: (data['client_name'] ?? '-').toString(),
      clientHandle: '',
      clientPhone: (data['client_phone'] ?? '').toString(),
      clientCity: (data['city'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      details: (data['description'] ?? '').toString(),
      attachments: attachments,
      expectedDeliveryAt: DateTime.tryParse((data['expected_delivery_at'] ?? '').toString()),
      estimatedServiceAmountSR: double.tryParse((data['estimated_service_amount'] ?? '').toString()),
      receivedAmountSR: double.tryParse((data['received_amount'] ?? '').toString()),
      remainingAmountSR: double.tryParse((data['remaining_amount'] ?? '').toString()),
      deliveredAt: DateTime.tryParse((data['delivered_at'] ?? '').toString()),
      actualServiceAmountSR: double.tryParse((data['actual_service_amount'] ?? '').toString()),
      canceledAt: DateTime.tryParse((data['canceled_at'] ?? '').toString()),
      cancelReason: (data['cancel_reason'] ?? '').toString().trim().isEmpty
          ? null
          : (data['cancel_reason'] ?? '').toString(),
    );
  }

  static String _mapStatus(String status) {
    final raw = status.trim().toLowerCase();
    if (raw == 'open' || raw == 'pending' || raw == 'new' || raw == 'sent') {
      return 'جديد';
    }
    if (raw == 'accepted') return 'بانتظار اعتماد العميل';
    if (raw == 'in_progress') return 'تحت التنفيذ';
    if (raw == 'completed') return 'مكتمل';
    if (raw == 'cancelled' || raw == 'canceled' || raw == 'expired') {
      return 'ملغي';
    }
    return 'جديد';
  }

  static bool _isMessageKind(String kind) {
    final normalized = kind.trim().toLowerCase();
    return normalized == 'message' ||
        normalized == 'message_new' ||
        normalized == 'chat' ||
        normalized == 'chat_message';
  }

  static bool _isDirectThreadUrl({required String kind, required String? url}) {
    if (!_isMessageKind(kind)) return false;
    final s = (url ?? '').trim();
    if (s.isEmpty) return false;

    // Backend uses /threads/<id>/chat for direct threads.
    // Request threads use /requests/<id>/chat.
    final threadId = _extractThreadIdFromUrl(s);
    if (threadId == null) return false;
    final requestId = _extractRequestIdFromUrl(s);
    return requestId == null;
  }

  static bool? _extractIsDirectFromPayload(Map<String, dynamic>? payload) {
    if (payload == null) return null;

    dynamic raw = payload['is_direct'] ?? payload['isDirect'];
    if (raw == null) {
      final meta = payload['meta'];
      if (meta is Map) {
        raw = meta['is_direct'] ?? meta['isDirect'];
      } else if (meta is String && meta.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(meta);
          if (decoded is Map) {
            raw = decoded['is_direct'] ?? decoded['isDirect'];
          }
        } catch (_) {}
      }
    }

    if (raw is bool) return raw;
    if (raw is num) return raw.toInt() == 1;
    final s = (raw ?? '').toString().trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return null;
  }

  static int? _extractThreadIdFromPayload(Map<String, dynamic>? payload) {
    if (payload == null) return null;
    dynamic raw = payload['thread_id'] ?? payload['threadId'] ?? payload['thread'];
    if (raw == null) {
      final meta = payload['meta'];
      if (meta is Map) {
        raw = meta['thread_id'] ?? meta['threadId'] ?? meta['thread'];
      } else if (meta is String && meta.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(meta);
          if (decoded is Map) {
            raw = decoded['thread_id'] ?? decoded['threadId'] ?? decoded['thread'];
          }
        } catch (_) {}
      }
    }
    return _asInt(raw);
  }

  static int? _extractRequestIdFromPayload(Map<String, dynamic>? payload) {
    if (payload == null) return null;
    dynamic raw = payload['request_id'] ?? payload['requestId'] ?? payload['request'];
    if (raw == null) {
      final meta = payload['meta'];
      if (meta is Map) {
        raw = meta['request_id'] ?? meta['requestId'] ?? meta['request'];
      } else if (meta is String && meta.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(meta);
          if (decoded is Map) {
            raw = decoded['request_id'] ?? decoded['requestId'] ?? decoded['request'];
          }
        } catch (_) {}
      }
    }
    return _asInt(raw);
  }

  static int? _extractSupportTicketIdFromPayload(Map<String, dynamic>? payload) {
    if (payload == null) return null;
    return _asInt(
      payload['ticket_id'] ??
          payload['ticketId'] ??
          payload['support_ticket_id'] ??
          payload['supportTicketId'],
    );
  }

  static int? _extractThreadIdFromUrl(String? rawUrl) {
    final s = (rawUrl ?? '').trim();
    if (s.isEmpty) return null;

    final uri = Uri.tryParse(s);
    if (uri != null) {
      final fromQuery = _asInt(
        uri.queryParameters['thread_id'] ??
            uri.queryParameters['threadId'] ??
            uri.queryParameters['thread'],
      );
      if (fromQuery != null) return fromQuery;
      final m = _threadPath.firstMatch(uri.path);
      if (m != null) return int.tryParse(m.group(1) ?? '');
      return null;
    }

    final m = _threadPath.firstMatch(s);
    if (m == null) return null;
    return int.tryParse(m.group(1) ?? '');
  }

  static int? _extractRequestIdFromUrl(String? rawUrl) {
    final s = (rawUrl ?? '').trim();
    if (s.isEmpty) return null;

    final uri = Uri.tryParse(s);
    if (uri != null) {
      final fromQuery = _asInt(
        uri.queryParameters['request_id'] ??
            uri.queryParameters['requestId'] ??
            uri.queryParameters['request'],
      );
      if (fromQuery != null) return fromQuery;
      final m = _requestChatPath.firstMatch(uri.path);
      if (m != null) return int.tryParse(m.group(1) ?? '');
      final m2 = _requestPath.firstMatch(uri.path);
      if (m2 != null) return int.tryParse(m2.group(1) ?? '');
      return null;
    }

    final m = _requestChatPath.firstMatch(s);
    if (m != null) return int.tryParse(m.group(1) ?? '');
    final m2 = _requestPath.firstMatch(s);
    if (m2 == null) return null;
    return int.tryParse(m2.group(1) ?? '');
  }

  static int? _extractSupportTicketIdFromUrl(String? rawUrl) {
    final s = (rawUrl ?? '').trim();
    if (s.isEmpty) return null;

    final uri = Uri.tryParse(s);
    if (uri != null) {
      final fromQuery = _asInt(
        uri.queryParameters['ticket_id'] ??
            uri.queryParameters['ticketId'] ??
            uri.queryParameters['support_ticket_id'],
      );
      if (fromQuery != null) return fromQuery;
      final m = _supportTicketPath.firstMatch(uri.path);
      if (m != null) return int.tryParse(m.group(1) ?? '');
      return null;
    }

    final m = _supportTicketPath.firstMatch(s);
    if (m == null) return null;
    return int.tryParse(m.group(1) ?? '');
  }

  static bool _isChatUrl(String? rawUrl) {
    final s = (rawUrl ?? '').trim();
    if (s.isEmpty) return false;
    final uri = Uri.tryParse(s);
    if (uri != null) {
      return _requestChatPath.hasMatch(uri.path);
    }
    return _requestChatPath.hasMatch(s);
  }

  static int? _extractRequestIdFromText(String text) {
    final m = RegExp(r'(?<!\d)(\d{1,10})(?!\d)').firstMatch(text);
    if (m == null) return null;
    return int.tryParse(m.group(1) ?? '');
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString());
  }
}

class _Target {
  final int? threadId;
  final int? requestId;
  final int? supportTicketId;
  final bool isDirect;
  final bool openInbox;
  final bool openRequestDetails;

  const _Target({
    required this.threadId,
    required this.requestId,
    required this.supportTicketId,
    required this.isDirect,
    required this.openInbox,
    required this.openRequestDetails,
  });
}
