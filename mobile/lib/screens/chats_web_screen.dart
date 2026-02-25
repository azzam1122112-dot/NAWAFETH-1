// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../services/account_api.dart';
import '../services/marketplace_api.dart';
import '../services/messaging_api.dart';
import '../services/role_controller.dart';
import '../utils/auth_guard.dart';
import '../utils/platform_feedback.dart';
import '../widgets/chat_web_shared_widgets.dart';
import '../widgets/custom_drawer.dart';

class ChatsWebScreen extends StatefulWidget {
  final int? requestId;
  final int? threadId;
  final String? name;
  final bool isDirect;
  final String? requestCode;
  final String? requestTitle;
  final String? peerId;
  final String? peerName;
  final String? initialSearchQuery;
  final String? initialFilter;

  const ChatsWebScreen({
    super.key,
    this.requestId,
    this.threadId,
    this.name,
    this.isDirect = false,
    this.requestCode,
    this.requestTitle,
    this.peerId,
    this.peerName,
    this.initialSearchQuery,
    this.initialFilter,
  });

  bool get opensDetail => requestId != null || threadId != null;

  @override
  State<ChatsWebScreen> createState() => _ChatsWebScreenState();
}

class _ChatsWebScreenState extends State<ChatsWebScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.opensDetail) {
      return _ChatDetailWebScaffold(
        requestId: widget.requestId,
        threadId: widget.threadId,
        isDirect: widget.isDirect,
        name: widget.name,
        requestCode: widget.requestCode,
        requestTitle: widget.requestTitle,
        peerName: widget.peerName,
      );
    }
    return _ChatsInboxWebScaffold(
      initialSearchQuery: widget.initialSearchQuery,
      initialFilter: widget.initialFilter,
    );
  }
}

class _ChatsInboxWebScaffold extends StatefulWidget {
  final String? initialSearchQuery;
  final String? initialFilter;

  const _ChatsInboxWebScaffold({
    this.initialSearchQuery,
    this.initialFilter,
  });

  @override
  State<_ChatsInboxWebScaffold> createState() => _ChatsInboxWebScaffoldState();
}

class _ChatsInboxWebScaffoldState extends State<_ChatsInboxWebScaffold> {
  final MessagingApi _messagingApi = MessagingApi();
  final MarketplaceApi _marketplaceApi = MarketplaceApi();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  bool _isProvider = false;
  String? _error;
  String _activeFilter = 'all'; // all | unread | requests | direct
  List<Map<String, dynamic>> _chats = <Map<String, dynamic>>[];
  Timer? _searchUrlDebounce;

  @override
  void initState() {
    super.initState();
    final initialSearch = (widget.initialSearchQuery ?? '').trim();
    if (initialSearch.isNotEmpty) {
      _searchController.text = initialSearch;
    }
    const allowedFilters = {'all', 'unread', 'requests', 'direct', 'favorite', 'archived'};
    final initialFilter = (widget.initialFilter ?? '').trim().toLowerCase();
    if (allowedFilters.contains(initialFilter)) {
      _activeFilter = initialFilter;
    }
    RoleController.instance.notifier.addListener(_onRoleChanged);
    _load();
  }

  @override
  void dispose() {
    RoleController.instance.notifier.removeListener(_onRoleChanged);
    _searchUrlDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onRoleChanged() {
    _load();
  }

  void _syncInboxUrl({bool immediate = false}) {
    if (!kIsWeb || !mounted) return;

    void pushState() {
      if (!mounted) return;
      final query = <String, String>{};
      final q = _searchController.text.trim();
      if (q.isNotEmpty) query['q'] = q;
      if (_activeFilter != 'all') query['filter'] = _activeFilter;
      SystemNavigator.routeInformationUpdated(
        uri: Uri(path: '/chats', queryParameters: query.isEmpty ? null : query),
        replace: true,
      );
    }

    if (immediate) {
      _searchUrlDebounce?.cancel();
      pushState();
      return;
    }
    _searchUrlDebounce?.cancel();
    _searchUrlDebounce = Timer(const Duration(milliseconds: 450), pushState);
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final s = (value ?? '').toString().trim();
    return int.tryParse(s);
  }

  String _pickNonEmpty(List<dynamic> values, String fallback) {
    for (final v in values) {
      final s = (v ?? '').toString().trim();
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  Future<void> _copyChatMeta(Map<String, dynamic> chat, {required bool copyCode}) async {
    final value = copyCode
        ? (chat['requestCode'] ?? '').toString().trim()
        : (chat['name'] ?? '').toString().trim();
    if (value.isEmpty) {
      if (!mounted) return;
      PlatformFeedback.show(context, 'لا توجد بيانات قابلة للنسخ', error: true);
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    PlatformFeedback.show(
      context,
      copyCode ? 'تم نسخ رقم الطلب' : 'تم نسخ الاسم',
      success: true,
    );
  }

  Future<void> _load() async {
    final authed = await checkAuth(context);
    if (!authed || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final isProvider = RoleController.instance.notifier.value.isProvider;
    final chats = <Map<String, dynamic>>[];

    try {
      final requestRows = isProvider
          ? await _marketplaceApi.getMyProviderRequests()
          : await _marketplaceApi.getMyRequests();

      for (final row in requestRows.take(20)) {
        if (row is! Map) continue;
        final req = row.map((k, v) => MapEntry(k.toString(), v));
        final requestId = _asInt(req['id']);
        if (requestId == null) continue;

        int? threadId = _asInt(req['thread_id']);
        Map<String, dynamic>? latestMessage;
        int unread = 0;
        try {
          final messages = await _messagingApi.getThreadMessages(requestId);
          if (messages.isNotEmpty) {
            latestMessage = messages.last;
            final meId = await _currentUserId();
            if (meId != null) {
              unread = messages.where((m) {
                final sender = _asInt(m['sender']);
                final readAt = (m['read_at'] ?? '').toString().trim();
                return sender != null && sender != meId && readAt.isEmpty;
              }).length;
            }
            threadId ??= _asInt(latestMessage['thread']) ?? _asInt(latestMessage['thread_id']);
          }
        } catch (_) {
          // Keep request row visible even if messages endpoint fails.
        }

        final createdAt = DateTime.tryParse(
              (latestMessage?['created_at'] ?? req['created_at'] ?? '').toString(),
            ) ??
            DateTime.now();

        final title = _pickNonEmpty(
          isProvider
              ? <dynamic>[req['client_name'], req['client_phone']]
              : <dynamic>[req['provider_name'], req['provider_phone']],
          isProvider ? 'عميل #$requestId' : 'مقدم خدمة #$requestId',
        );

        chats.add({
          'requestId': requestId,
          'threadId': threadId,
          'name': title,
          'requestCode': 'R${requestId.toString().padLeft(6, '0')}',
          'requestTitle': (req['title'] ?? '').toString(),
          'isDirect': false,
          'lastMessage': _pickNonEmpty(
            <dynamic>[latestMessage?['body'], req['title']],
            'ابدأ المحادثة الآن',
          ),
          'timestamp': createdAt,
          'unread': unread,
        });
      }

      if (!isProvider) {
        try {
          final directThreads = await _messagingApi.getMyDirectThreads();
          for (final dt in directThreads) {
            final threadId = _asInt(dt['thread_id']) ?? _asInt(dt['id']);
            if (threadId == null) continue;
            final t = DateTime.tryParse((dt['last_message_at'] ?? '').toString()) ?? DateTime.now();
            final peerName = (dt['peer_name'] ?? '').toString().trim();
            final peerId = _asInt(dt['peer_provider_id']) ?? _asInt(dt['peer_id']);
            chats.add({
              'requestId': null,
              'threadId': threadId,
              'name': peerName.isEmpty ? 'محادثة مباشرة' : peerName,
              'requestCode': null,
              'requestTitle': null,
              'isDirect': true,
              'peerId': peerId,
              'peerName': peerName,
              'lastMessage': ((dt['last_message'] ?? '').toString().trim().isEmpty)
                  ? 'ابدأ المحادثة الآن'
                  : (dt['last_message'] ?? '').toString(),
              'timestamp': t,
              'unread': _asInt(dt['unread_count']) ?? 0,
            });
          }
        } catch (_) {}
      }

      chats.sort((a, b) {
        final da = (a['timestamp'] as DateTime?) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = (b['timestamp'] as DateTime?) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });

      try {
        final states = await _messagingApi.getMyThreadStates();
        final byThreadId = <int, Map<String, dynamic>>{};
        for (final s in states) {
          final tid = _asInt(s['thread']);
          if (tid != null) byThreadId[tid] = s;
        }
        for (final c in chats) {
          final tid = _asInt(c['threadId']);
          if (tid == null) continue;
          final st = byThreadId[tid];
          if (st == null) continue;
          c['favorite'] = st['is_favorite'] == true;
          c['archived'] = st['is_archived'] == true;
          c['blocked'] = st['is_blocked'] == true;
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _isProvider = isProvider;
        _chats = chats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل المحادثات';
      });
      PlatformFeedback.show(context, 'تعذر تحميل المحادثات', error: true);
    }
  }

  int? _cachedUserId;
  Future<int?> _currentUserId() async {
    if (_cachedUserId != null) return _cachedUserId;
    try {
      final me = await AccountApi().me();
      _cachedUserId = _asInt(me['id']);
      return _cachedUserId;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchController.text.trim().toLowerCase();
    var filtered = q.isEmpty
        ? _chats
        : _chats.where((c) {
            final name = (c['name'] ?? '').toString().toLowerCase();
            final title = (c['requestTitle'] ?? '').toString().toLowerCase();
            final code = (c['requestCode'] ?? '').toString().toLowerCase();
            final body = (c['lastMessage'] ?? '').toString().toLowerCase();
            return name.contains(q) || title.contains(q) || code.contains(q) || body.contains(q);
          }).toList();

    if (_activeFilter == 'unread') {
      filtered = filtered.where((c) => (_asInt(c['unread']) ?? 0) > 0).toList();
    } else if (_activeFilter == 'requests') {
      filtered = filtered.where((c) => c['isDirect'] != true).toList();
    } else if (_activeFilter == 'direct') {
      filtered = filtered.where((c) => c['isDirect'] == true).toList();
    } else if (_activeFilter == 'favorite') {
      filtered = filtered.where((c) => c['favorite'] == true && c['archived'] != true).toList();
    } else if (_activeFilter == 'archived') {
      filtered = filtered.where((c) => c['archived'] == true).toList();
    }
    filtered = filtered.where((c) => c['blocked'] != true).toList();
    if (_activeFilter != 'archived') {
      filtered = filtered.where((c) => c['archived'] != true).toList();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: const CustomDrawer(),
        appBar: AppBar(
          title: const Text('المحادثات', style: TextStyle(fontFamily: 'Cairo')),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (_) {
                  setState(() {});
                  _syncInboxUrl();
                },
                decoration: InputDecoration(
                  hintText: 'ابحث في المحادثات',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            _syncInboxUrl(immediate: true);
                          },
                          icon: const Icon(Icons.close),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isProvider
                          ? 'محادثات الطلبات (وضع المزود)'
                          : 'محادثات الطلبات + المباشرة (وضع العميل)',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${filtered.length} محادثة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  _miniStat(
                    label: 'كلها',
                    value: _chats.length,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 8),
                  _miniStat(
                    label: 'مفضلة',
                    value: _chats.where((c) => c['favorite'] == true && c['archived'] != true).length,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 8),
                  _miniStat(
                    label: 'غير مقروءة',
                    value: _chats.where((c) => (_asInt(c['unread']) ?? 0) > 0).length,
                    color: Colors.redAccent,
                  ),
                  if (!_isProvider) ...[
                    const SizedBox(width: 8),
                    _miniStat(
                      label: 'مباشرة',
                      value: _chats.where((c) => c['isDirect'] == true).length,
                      color: Colors.blue,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _filterChip('all', 'الكل'),
                  const SizedBox(width: 8),
                  _filterChip('unread', 'غير المقروء'),
                  const SizedBox(width: 8),
                  _filterChip('requests', 'طلبات'),
                  if (!_isProvider) ...[
                    const SizedBox(width: 8),
                    _filterChip('direct', 'مباشرة'),
                  ],
                  const SizedBox(width: 8),
                  _filterChip('favorite', 'مفضلة'),
                  const SizedBox(width: 8),
                  _filterChip('archived', 'مؤرشفة'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_error != null
                      ? _errorState()
                      : (filtered.isEmpty ? _emptyState() : _listView(filtered))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final selected = _activeFilter == key;
    return ChatFilterChoiceChip(
      label: label,
      selected: selected,
      onTap: () {
        setState(() => _activeFilter = key);
        _syncInboxUrl(immediate: true);
      },
    );
  }

  Widget _miniStat({
    required String label,
    required int value,
    required Color color,
  }) {
    return ChatMiniStatPill(label: label, value: value, color: color);
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 42, color: Colors.redAccent),
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(fontFamily: 'Cairo')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Text(
        'لا توجد محادثات حتى الآن',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _listView(List<Map<String, dynamic>> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = items[index];
        final dt = (c['timestamp'] as DateTime?) ?? DateTime.now();
        final unread = _asInt(c['unread']) ?? 0;
        final isDirect = c['isDirect'] == true;
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.pushNamed(context, _chatRouteForItem(c, isDirect: isDirect));
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isDirect ? Colors.blue.shade50 : Colors.deepPurple.shade50,
                    child: Icon(
                      isDirect ? Icons.chat_bubble_outline_rounded : Icons.receipt_long_rounded,
                      color: isDirect ? Colors.blue.shade700 : Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                (c['name'] ?? '').toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('hh:mm a', 'ar').format(dt),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        if ((c['requestCode'] ?? '').toString().trim().isNotEmpty ||
                            (c['requestTitle'] ?? '').toString().trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            [
                              (c['requestCode'] ?? '').toString().trim(),
                              (c['requestTitle'] ?? '').toString().trim(),
                            ].where((e) => e.isNotEmpty).join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11.5,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          (c['lastMessage'] ?? '').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      if (unread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      PopupMenuButton<String>(
                        tooltip: 'إجراءات',
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        onSelected: (value) async {
                          if (value == 'open') {
                            if (!mounted) return;
                            Navigator.pushNamed(
                              context,
                              _chatRouteForItem(c, isDirect: isDirect),
                            );
                            return;
                          }
                          if (value == 'copy_name') {
                            await _copyChatMeta(c, copyCode: false);
                            return;
                          }
                          if (value == 'copy_code') {
                            await _copyChatMeta(c, copyCode: true);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'open',
                            child: Text('فتح المحادثة', style: TextStyle(fontFamily: 'Cairo')),
                          ),
                          const PopupMenuItem(
                            value: 'copy_name',
                            child: Text('نسخ الاسم', style: TextStyle(fontFamily: 'Cairo')),
                          ),
                          if ((c['requestCode'] ?? '').toString().trim().isNotEmpty)
                            const PopupMenuItem(
                              value: 'copy_code',
                              child: Text(
                                'نسخ رقم الطلب',
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _chatRouteForItem(Map<String, dynamic> c, {required bool isDirect}) {
    final query = <String, String>{};
    final requestId = _asInt(c['requestId']);
    final threadId = _asInt(c['threadId']);
    if (requestId != null) query['requestId'] = '$requestId';
    if (threadId != null) query['threadId'] = '$threadId';
    if (isDirect) query['direct'] = '1';

    String putText(String key, dynamic value) {
      final s = (value ?? '').toString().trim();
      if (s.isNotEmpty) query[key] = s;
      return s;
    }

    putText('name', c['name']);
    putText('requestCode', c['requestCode']);
    putText('requestTitle', c['requestTitle']);
    putText('peerId', c['peerId']);
    putText('peerName', c['peerName']);

    return Uri(path: '/chats', queryParameters: query.isEmpty ? null : query).toString();
  }
}

class _ChatDetailWebScaffold extends StatefulWidget {
  final int? requestId;
  final int? threadId;
  final bool isDirect;
  final String? name;
  final String? requestCode;
  final String? requestTitle;
  final String? peerName;

  const _ChatDetailWebScaffold({
    required this.requestId,
    required this.threadId,
    required this.isDirect,
    this.name,
    this.requestCode,
    this.requestTitle,
    this.peerName,
  });

  @override
  State<_ChatDetailWebScaffold> createState() => _ChatDetailWebScaffoldState();
}

class _ChatDetailWebScaffoldState extends State<_ChatDetailWebScaffold> {
  static final html.EventStreamProvider<html.BlobEvent> _mediaDataAvailableProvider =
      html.EventStreamProvider<html.BlobEvent>('dataavailable');
  static final html.EventStreamProvider<html.Event> _mediaStopProvider =
      html.EventStreamProvider<html.Event>('stop');
  static final html.EventStreamProvider<html.Event> _mediaErrorProvider =
      html.EventStreamProvider<html.Event>('error');

  final MessagingApi _messagingApi = MessagingApi();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _sending = false;
  bool _sendingAttachment = false;
  bool _recordingVoice = false;
  bool _wsConnected = false;
  bool _peerTyping = false;
  String? _error;
  List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[];
  int? _myUserId;
  Timer? _poller;
  int? _resolvedThreadId;
  html.WebSocket? _ws;
  StreamSubscription<html.MessageEvent>? _wsMessageSub;
  StreamSubscription<html.Event>? _wsOpenSub;
  StreamSubscription<html.Event>? _wsCloseSub;
  StreamSubscription<html.Event>? _wsErrorSub;
  html.MediaRecorder? _mediaRecorder;
  html.MediaStream? _mediaStream;
  StreamSubscription<html.BlobEvent>? _mediaDataSub;
  StreamSubscription<html.Event>? _mediaStopSub;
  StreamSubscription<html.Event>? _mediaErrorSub;
  final List<html.Blob> _mediaChunks = <html.Blob>[];
  Timer? _recordingTicker;
  Duration _recordingElapsed = Duration.zero;
  bool _sendRecordedAudioOnStop = true;
  html.AudioElement? _inlineAudioPlayer;
  StreamSubscription<html.Event>? _inlineAudioEndedSub;
  StreamSubscription<html.Event>? _inlineAudioPauseSub;
  String? _playingAudioUrl;
  bool _inlineAudioPlaying = false;
  Timer? _peerTypingTimer;
  Timer? _typingSendDebounce;

  @override
  void initState() {
    super.initState();
    _resolvedThreadId = widget.threadId;
    _load();
    _poller = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    _closeWs();
    _peerTypingTimer?.cancel();
    _typingSendDebounce?.cancel();
    _recordingTicker?.cancel();
    _disposeMediaRecorder();
    _disposeInlineAudioPlayer();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _disposeInlineAudioPlayer() {
    _inlineAudioEndedSub?.cancel();
    _inlineAudioPauseSub?.cancel();
    _inlineAudioEndedSub = null;
    _inlineAudioPauseSub = null;
    try {
      _inlineAudioPlayer?.pause();
    } catch (_) {}
    _inlineAudioPlayer = null;
    _playingAudioUrl = null;
    _inlineAudioPlaying = false;
  }

  void _disposeMediaRecorder() {
    _mediaDataSub?.cancel();
    _mediaStopSub?.cancel();
    _mediaErrorSub?.cancel();
    _mediaDataSub = null;
    _mediaStopSub = null;
    _mediaErrorSub = null;
    try {
      _mediaRecorder = null;
      _mediaStream?.getTracks().forEach((t) => t.stop());
    } catch (_) {}
    _mediaStream = null;
    _mediaChunks.clear();
    _recordingVoice = false;
    _recordingTicker?.cancel();
    _recordingElapsed = Duration.zero;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final s = (value ?? '').toString().trim();
    return int.tryParse(s);
  }

  List<int> _asIntList(dynamic raw) {
    if (raw is! List) return const [];
    final out = <int>[];
    for (final v in raw) {
      final i = _asInt(v);
      if (i != null) out.add(i);
    }
    return out;
  }

  bool _isReadByPeerFromPayload(dynamic rawReadByIds) {
    if (_myUserId == null || rawReadByIds is! List) return false;
    for (final v in rawReadByIds) {
      final id = _asInt(v);
      if (id != null && id != _myUserId) return true;
    }
    return false;
  }

  void _markMyMessagesRead({List<int>? ids, int? markedCount}) {
    if (!mounted || _myUserId == null) return;
    var changed = false;

    if (ids != null && ids.isNotEmpty) {
      final setIds = ids.toSet();
      for (final m in _messages) {
        final id = _asInt(m['id']);
        final sender = _asInt(m['sender']) ?? _asInt(m['sender_id']);
        if (id != null && setIds.contains(id) && sender == _myUserId) {
          if (m['readByPeer'] != true) {
            m['readByPeer'] = true;
            changed = true;
          }
        }
      }
    } else if ((markedCount ?? 0) > 0) {
      var remaining = markedCount!;
      for (var i = _messages.length - 1; i >= 0 && remaining > 0; i--) {
        final m = _messages[i];
        final sender = _asInt(m['sender']) ?? _asInt(m['sender_id']);
        if (sender == _myUserId && m['readByPeer'] != true) {
          m['readByPeer'] = true;
          changed = true;
          remaining -= 1;
        }
      }
    }

    if (changed) setState(() {});
  }

  Future<void> _openAttachment(String url) async {
    final link = url.trim();
    if (link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) {
      PlatformFeedback.show(context, 'رابط المرفق غير صالح', error: true);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!ok && mounted) {
      PlatformFeedback.show(context, 'تعذر فتح المرفق', error: true);
    }
  }

  Future<Uint8List> _blobToBytes(html.Blob blob) async {
    final reader = html.FileReader();
    final completer = Completer<Uint8List>();
    reader.onLoadEnd.first.then((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(Uint8List.view(result));
        return;
      }
      if (result is Uint8List) {
        completer.complete(result);
        return;
      }
      completer.completeError(StateError('تعذر قراءة البيانات الصوتية'));
    });
    reader.readAsArrayBuffer(blob);
    return completer.future;
  }

  Future<void> _toggleInlineAudio(String url) async {
    final link = url.trim();
    if (link.isEmpty) return;

    if (_playingAudioUrl == link && _inlineAudioPlayer != null) {
      try {
        if (_inlineAudioPlaying) {
          _inlineAudioPlayer!.pause();
          if (mounted) setState(() => _inlineAudioPlaying = false);
        } else {
          await _inlineAudioPlayer!.play();
          if (mounted) setState(() => _inlineAudioPlaying = true);
        }
      } catch (_) {
        if (mounted) {
          PlatformFeedback.show(context, 'تعذر تشغيل الصوت', error: true);
        }
      }
      return;
    }

    _disposeInlineAudioPlayer();
    try {
      final player = html.AudioElement(link);
      _inlineAudioPlayer = player;
      _playingAudioUrl = link;
      _inlineAudioEndedSub = player.onEnded.listen((_) {
        if (mounted) {
          setState(() => _inlineAudioPlaying = false);
        } else {
          _inlineAudioPlaying = false;
        }
      });
      _inlineAudioPauseSub = player.onPause.listen((_) {
        if (mounted) {
          setState(() => _inlineAudioPlaying = false);
        } else {
          _inlineAudioPlaying = false;
        }
      });
      await player.play();
      if (mounted) setState(() => _inlineAudioPlaying = true);
    } catch (_) {
      if (!mounted) return;
      PlatformFeedback.show(context, 'تعذر تشغيل الصوت داخل الرسالة', error: true);
    }
  }

  String _recordingElapsedLabel() {
    final mm = _recordingElapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = _recordingElapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Future<void> _startLiveVoiceRecording() async {
    if (_recordingVoice || _sendingAttachment) return;
    try {
      final devices = html.window.navigator.mediaDevices;
      if (devices == null) {
        throw StateError('المتصفح لا يدعم تسجيل الصوت');
      }
      final stream = await devices.getUserMedia({'audio': true});
      final recorder = html.MediaRecorder(stream);
      _mediaChunks.clear();
      _mediaStream = stream;
      _mediaRecorder = recorder;
      _sendRecordedAudioOnStop = true;

      _mediaDataSub = _mediaDataAvailableProvider.forTarget(recorder).listen((event) {
        final blob = event.data;
        if (blob != null && blob.size > 0) {
          _mediaChunks.add(blob);
        }
      });
      _mediaErrorSub = _mediaErrorProvider.forTarget(recorder).listen((_) {
        if (!mounted) return;
        PlatformFeedback.show(context, 'حدث خطأ أثناء تسجيل الصوت', error: true);
      });
      _mediaStopSub = _mediaStopProvider.forTarget(recorder).listen((_) async {
        final shouldSend = _sendRecordedAudioOnStop;
        final blobs = List<html.Blob>.from(_mediaChunks);
        _disposeMediaRecorder();
        if (!shouldSend || blobs.isEmpty || !mounted) return;
        try {
          final blob = html.Blob(blobs, 'audio/webm');
          final bytes = await _blobToBytes(blob);
          await _sendAttachmentDynamic(
            <String, dynamic>{
              'bytes': bytes,
              'name': 'voice_${DateTime.now().millisecondsSinceEpoch}.webm',
            },
            attachmentType: 'audio',
          );
        } catch (_) {
          if (!mounted) return;
          PlatformFeedback.show(context, 'تعذر معالجة التسجيل الصوتي', error: true);
        }
      });

      recorder.start(250);
      _recordingTicker?.cancel();
      _recordingElapsed = Duration.zero;
      _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordingElapsed += const Duration(seconds: 1));
      });
      if (!mounted) return;
      setState(() => _recordingVoice = true);
      PlatformFeedback.show(context, 'بدأ تسجيل الصوت', success: true);
    } catch (_) {
      if (!mounted) return;
      PlatformFeedback.show(context, 'تعذر بدء تسجيل الصوت من المتصفح', error: true);
    }
  }

  Future<void> _stopLiveVoiceRecording({bool send = true}) async {
    if (!_recordingVoice || _mediaRecorder == null) return;
    _sendRecordedAudioOnStop = send;
    try {
      _mediaRecorder!.stop();
      if (mounted) setState(() => _recordingVoice = false);
      if (!send && mounted) {
        PlatformFeedback.show(context, 'تم إلغاء التسجيل الصوتي');
      }
    } catch (_) {
      _disposeMediaRecorder();
      if (!mounted) return;
      PlatformFeedback.show(context, 'تعذر إيقاف التسجيل الصوتي', error: true);
    }
  }

  Future<void> _load({bool silent = false}) async {
    final authed = await checkAuth(context);
    if (!authed || !mounted) return;

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      _myUserId ??= _asInt((await AccountApi().me())['id']);

      if (widget.isDirect) {
        final tid = widget.threadId;
        if (tid == null) {
          throw StateError('رقم المحادثة غير صالح');
        }
        final msgs = await _messagingApi.getDirectThreadMessages(tid);
        await _messagingApi.markDirectRead(threadId: tid);
        if (!mounted) return;
        setState(() {
          _resolvedThreadId = tid;
          _messages = msgs
              .map(
                (m) => <String, dynamic>{
                  ...m,
                  'readByPeer': _isReadByPeerFromPayload(m['read_by_ids']),
                },
              )
              .toList();
          _loading = false;
          _error = null;
        });
        _ensureWebSocket();
      } else {
        final rid = widget.requestId;
        if (rid == null) {
          throw StateError('محادثات الطلب على الويب تحتاج requestId');
        }
        final msgs = await _messagingApi.getThreadMessages(rid);
        int? inferredThreadId = _resolvedThreadId;
        if (inferredThreadId == null && msgs.isNotEmpty) {
          final last = msgs.last;
          inferredThreadId = _asInt(last['thread']) ?? _asInt(last['thread_id']);
        }
        await _messagingApi.markRead(requestId: rid);
        if (!mounted) return;
        setState(() {
          _resolvedThreadId = inferredThreadId;
          _messages = msgs
              .map(
                (m) => <String, dynamic>{
                  ...m,
                  'readByPeer': _isReadByPeerFromPayload(m['read_by_ids']),
                },
              )
              .toList();
          _loading = false;
          _error = null;
        });
        _ensureWebSocket();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is StateError ? e.message : 'تعذر تحميل المحادثة';
      });
      if (!silent) {
        PlatformFeedback.show(context, _error ?? 'تعذر تحميل المحادثة', error: true);
      }
    }
  }

  void _closeWs() {
    _wsMessageSub?.cancel();
    _wsOpenSub?.cancel();
    _wsCloseSub?.cancel();
    _wsErrorSub?.cancel();
    _wsMessageSub = null;
    _wsOpenSub = null;
    _wsCloseSub = null;
    _wsErrorSub = null;
    try {
      _ws?.close();
    } catch (_) {}
    _ws = null;
    if (mounted && _wsConnected) {
      setState(() => _wsConnected = false);
    } else {
      _wsConnected = false;
    }
  }

  Future<void> _ensureWebSocket() async {
    if (!mounted) return;
    final threadId = _resolvedThreadId;
    if (threadId == null || threadId <= 0) return;
    if (_ws != null) return;

    try {
      final token = await _messagingApi.getAccessToken();
      if (token == null || token.trim().isEmpty) return;
      final uri = _messagingApi.buildThreadWsUri(threadId: threadId, token: token);
      final socket = html.WebSocket(uri.toString());
      _ws = socket;

      _wsOpenSub = socket.onOpen.listen((_) {
        if (mounted) setState(() => _wsConnected = true);
      });
      _wsCloseSub = socket.onClose.listen((_) {
        if (mounted) setState(() => _wsConnected = false);
        _ws = null;
      });
      _wsErrorSub = socket.onError.listen((_) {
        if (mounted) setState(() => _wsConnected = false);
      });
      _wsMessageSub = socket.onMessage.listen((event) {
        final raw = event.data;
        final payload = _messagingApi.decodeWsPayload(raw);
        _handleWsPayload(payload);
      });
    } catch (_) {
      if (mounted) setState(() => _wsConnected = false);
    }
  }

  void _handleWsPayload(Map<String, dynamic> payload) {
    final type = (payload['type'] ?? '').toString().trim().toLowerCase();
    if (type.isEmpty) return;

    if (type == 'connected') {
      if (mounted) setState(() => _wsConnected = true);
      return;
    }

    if (type == 'read') {
      final ids = _asIntList(payload['message_ids']);
      final marked = _asInt(payload['marked']) ?? _asInt(payload['count']);
      if (ids.isNotEmpty || (marked ?? 0) > 0) {
        _markMyMessagesRead(ids: ids.isEmpty ? null : ids, markedCount: marked);
      } else {
        _load(silent: true);
      }
      return;
    }

    if (type == 'typing') {
      final userId = _asInt(payload['user_id']);
      if (_myUserId != null && userId == _myUserId) return;
      final isTyping = payload['is_typing'] == true;
      _peerTypingTimer?.cancel();
      if (mounted) {
        setState(() => _peerTyping = isTyping);
      } else {
        _peerTyping = isTyping;
      }
      if (isTyping) {
        _peerTypingTimer = Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() => _peerTyping = false);
        });
      }
      return;
    }

    if (type != 'message') return;

    final msgId = _asInt(payload['id']);
    final exists = msgId != null &&
        _messages.any((m) => (_asInt(m['id']) ?? _asInt(m['message_id'])) == msgId);
    if (exists) return;

    final mapped = <String, dynamic>{
      'id': msgId,
      'sender': _asInt(payload['sender_id']) ?? _asInt(payload['sender']),
      'body': (payload['text'] ?? payload['body'] ?? '').toString(),
      'attachment_url': (payload['attachment_url'] ?? '').toString(),
      'attachment_type': (payload['attachment_type'] ?? '').toString(),
      'attachment_name': (payload['attachment_name'] ?? '').toString(),
      'created_at': (payload['sent_at'] ?? payload['created_at'] ?? '').toString(),
      if (_resolvedThreadId != null) 'thread_id': _resolvedThreadId,
    };

    if (!mounted) return;
    setState(() {
      _messages = <Map<String, dynamic>>[..._messages, mapped];
      _peerTyping = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  String _attachmentTypeForName(String name, {String fallback = 'file'}) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp')) {
      return 'image';
    }
    if (lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.webm')) {
      return 'audio';
    }
    return fallback;
  }

  Future<void> _sendAttachmentDynamic(
    dynamic fileLike, {
    required String attachmentType,
    String body = '',
  }) async {
    if (_sending || _sendingAttachment) return;
    setState(() => _sendingAttachment = true);
    try {
      if (widget.isDirect) {
        final tid = widget.threadId;
        if (tid == null) throw StateError('رقم المحادثة غير صالح');
        await _messagingApi.sendDirectAttachment(
          threadId: tid,
          file: fileLike,
          body: body,
          attachmentType: attachmentType,
        );
      } else {
        final rid = widget.requestId;
        if (rid == null) throw StateError('رقم الطلب غير صالح');
        await _messagingApi.sendMessageAttachment(
          requestId: rid,
          file: fileLike,
          body: body,
          attachmentType: attachmentType,
        );
      }
      if (!mounted) return;
      PlatformFeedback.show(context, 'تم رفع المرفق وإرساله', success: true);
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      PlatformFeedback.show(
        context,
        _messagingApi.errorMessageOf(e) ?? 'تعذر إرسال المرفق',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _sendingAttachment = false);
    }
  }

  Future<void> _pickAndSendAttachment({
    required FileType type,
    required String attachmentType,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final inferred = _attachmentTypeForName(file.name, fallback: attachmentType);
      await _sendAttachmentDynamic(file, attachmentType: inferred);
    } catch (_) {
      if (!mounted) return;
      PlatformFeedback.show(context, 'تعذر اختيار المرفق', error: true);
    }
  }

  Future<void> _pickAndSendAudioCapture() async {
    try {
      final input = html.FileUploadInputElement()..accept = 'audio/*';
      input.setAttribute('capture', 'microphone');
      final completer = Completer<html.File?>();
      input.onChange.first.then((_) {
        final f = input.files;
        completer.complete(f == null || f.isEmpty ? null : f.first);
      });
      input.click();
      final file = await completer.future;
      if (file == null) return;

      final reader = html.FileReader();
      final bytesCompleter = Completer<Uint8List>();
      reader.onLoadEnd.first.then((_) {
        final result = reader.result;
        if (result is ByteBuffer) {
          bytesCompleter.complete(Uint8List.view(result));
          return;
        }
        if (result is Uint8List) {
          bytesCompleter.complete(result);
          return;
        }
        bytesCompleter.completeError(StateError('تعذر قراءة ملف الصوت'));
      });
      reader.readAsArrayBuffer(file);
      final bytes = await bytesCompleter.future;

      await _sendAttachmentDynamic(
        <String, dynamic>{
          'bytes': bytes,
          'name': file.name.isEmpty ? 'voice.webm' : file.name,
        },
        attachmentType: 'audio',
      );
    } catch (_) {
      if (!mounted) return;
      PlatformFeedback.show(context, 'تعذر التقاط/رفع الصوت من المتصفح', error: true);
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      if (widget.isDirect) {
        final tid = widget.threadId;
        if (tid == null) throw StateError('رقم المحادثة غير صالح');
        await _messagingApi.sendDirectMessage(threadId: tid, body: text);
        try {
          _ws?.send(jsonEncode({'type': 'typing', 'is_typing': false}));
        } catch (_) {}
      } else {
        final rid = widget.requestId;
        if (rid == null) throw StateError('رقم الطلب غير صالح');
        await _messagingApi.sendMessage(requestId: rid, body: text);
        try {
          _ws?.send(jsonEncode({'type': 'typing', 'is_typing': false}));
        } catch (_) {}
      }
      _messageController.clear();
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      final msg = _messagingApi.errorMessageOf(e) ?? 'تعذر إرسال الرسالة';
      PlatformFeedback.show(context, msg, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.name ?? '').trim().isEmpty
        ? (widget.isDirect ? 'محادثة مباشرة' : 'محادثة الطلب')
        : widget.name!.trim();
    final subtitle = [
      (widget.requestCode ?? '').trim(),
      (widget.requestTitle ?? '').trim(),
    ].where((e) => e.isNotEmpty).join(' • ');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: const CustomDrawer(),
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              if (_wsConnected)
                Text(
                  'متصل الآن',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.deepPurple.withValues(alpha: 0.04),
                      Colors.blueGrey.withValues(alpha: 0.03),
                    ],
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      children: [
                        _chatMetaHeader(title: title, subtitle: subtitle),
                        Expanded(
                          child: _loading
                              ? const Center(child: CircularProgressIndicator())
                              : (_error != null ? _detailError() : _messagesList()),
                        ),
                        _composer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatMetaHeader({required String title, required String subtitle}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isDirect
                  ? Colors.blue.shade50
                  : Colors.deepPurple.withValues(alpha: 0.08),
            ),
            child: Icon(
              widget.isDirect
                  ? Icons.chat_bubble_outline_rounded
                  : Icons.receipt_long_rounded,
              color: widget.isDirect ? Colors.blue.shade700 : Colors.deepPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ChatConversationTitleBlock(
              title: title,
              subtitle: subtitle.isEmpty ? 'محادثة' : subtitle,
              titleStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
              ),
              subtitleStyle: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ChatConnectionPill(live: _wsConnected, typing: _peerTyping),
        ],
      ),
    );
  }

  Widget _detailError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.forum_outlined, size: 44),
          const SizedBox(height: 8),
          Text(_error ?? 'تعذر تحميل المحادثة', style: const TextStyle(fontFamily: 'Cairo')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Widget _messagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final m = _messages[index];
        final senderId = _asInt(m['sender']) ?? _asInt(m['sender_id']);
        final isMine = _myUserId != null && senderId == _myUserId;
        final body = (m['body'] ?? '').toString();
        final attachmentName = (m['attachment_name'] ?? '').toString().trim();
        final attachmentType = (m['attachment_type'] ?? '').toString().trim();
        final attachmentUrl = (m['attachment_url'] ?? '').toString().trim();
        final createdAt = DateTime.tryParse((m['created_at'] ?? '').toString());
        final isImageAttachment =
            attachmentUrl.isNotEmpty && attachmentType.toLowerCase().contains('image');
        final isAudioAttachment =
            attachmentUrl.isNotEmpty && attachmentType.toLowerCase().contains('audio');

        final shownText = body.trim().isNotEmpty
            ? body.trim()
            : (attachmentName.isNotEmpty
                ? 'مرفق (${attachmentType.isEmpty ? 'file' : attachmentType}): $attachmentName'
                : 'رسالة');

        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? Colors.deepPurple : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isMine
                    ? null
                    : Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (isImageAttachment) ...[
                    InkWell(
                      onTap: () => _openAttachment(attachmentUrl),
                      borderRadius: BorderRadius.circular(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 260,
                            minWidth: 160,
                            maxWidth: 360,
                          ),
                          child: Image.network(
                            attachmentUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 120,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (isAudioAttachment) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMine
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.blue.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.blue.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _toggleInlineAudio(attachmentUrl),
                            icon: Icon(
                              (_playingAudioUrl == attachmentUrl && _inlineAudioPlaying)
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: isMine ? Colors.white : Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              attachmentName.isEmpty ? 'رسالة صوتية' : attachmentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: isMine ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: () => _openAttachment(attachmentUrl),
                            child: Text(
                              'فتح',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: isMine ? Colors.white : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    shownText,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: isMine ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (attachmentUrl.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: isMine ? Colors.white : Colors.deepPurple,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _openAttachment(attachmentUrl),
                      icon: const Icon(Icons.attach_file_rounded, size: 16),
                      label: Text(
                        attachmentName.isEmpty ? 'فتح المرفق' : 'فتح: $attachmentName',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    ChatMessageMetaRow(
                      timeText: DateFormat('hh:mm a', 'ar').format(createdAt),
                      isMine: isMine,
                      readByPeer: m['readByPeer'] == true,
                      mineColor: Colors.white.withValues(alpha: 0.85),
                      otherColor: Colors.grey.shade600,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _composer() {
    final disabled = _error != null;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
            if (_recordingVoice)
              Container(
                margin: const EdgeInsetsDirectional.only(end: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic, size: 16, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Text(
                      _recordingElapsedLabel(),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            PopupMenuButton<String>(
              tooltip: 'إرسال مرفق',
              enabled: !disabled && !_sending && !_sendingAttachment,
              icon: _sendingAttachment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline_rounded),
              onSelected: (value) async {
                if (value == 'image') {
                  await _pickAndSendAttachment(
                    type: FileType.image,
                    attachmentType: 'image',
                  );
                  return;
                }
                if (value == 'file') {
                  await _pickAndSendAttachment(
                    type: FileType.any,
                    attachmentType: 'file',
                  );
                  return;
                }
                if (value == 'audio_upload') {
                  await _pickAndSendAttachment(
                    type: FileType.audio,
                    attachmentType: 'audio',
                  );
                  return;
                }
                if (value == 'audio_capture') {
                  await _pickAndSendAudioCapture();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'image',
                  child: Text('إرسال صورة', style: TextStyle(fontFamily: 'Cairo')),
                ),
                PopupMenuItem(
                  value: 'file',
                  child: Text('إرسال ملف', style: TextStyle(fontFamily: 'Cairo')),
                ),
                PopupMenuItem(
                  value: 'audio_upload',
                  child: Text('رفع صوت', style: TextStyle(fontFamily: 'Cairo')),
                ),
                PopupMenuItem(
                  value: 'audio_capture',
                  child: Text('تسجيل/التقاط صوت', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: _recordingVoice ? 'إيقاف وإرسال التسجيل' : 'تسجيل صوت حي',
              onPressed: disabled || _sendingAttachment
                  ? null
                  : () async {
                      if (_recordingVoice) {
                        await _stopLiveVoiceRecording(send: true);
                      } else {
                        await _startLiveVoiceRecording();
                      }
                    },
              icon: Icon(
                _recordingVoice ? Icons.stop_circle_outlined : Icons.mic_none_rounded,
                color: _recordingVoice ? Colors.redAccent : null,
              ),
            ),
            if (_recordingVoice)
              IconButton(
                tooltip: 'إلغاء التسجيل',
                onPressed: () => _stopLiveVoiceRecording(send: false),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              ),
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled:
                    !disabled && !_sending && !_sendingAttachment && !_recordingVoice,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onChanged: (value) {
                  if (!_wsConnected || _ws == null) return;
                  _typingSendDebounce?.cancel();
                  try {
                    _ws!.send(jsonEncode({'type': 'typing', 'is_typing': value.trim().isNotEmpty}));
                  } catch (_) {}
                  _typingSendDebounce = Timer(const Duration(milliseconds: 900), () {
                    if (_ws == null) return;
                    try {
                      _ws!.send(jsonEncode({'type': 'typing', 'is_typing': false}));
                    } catch (_) {}
                  });
                },
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: disabled ? 'تعذر الإرسال حاليًا' : 'اكتب رسالتك...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
                FilledButton.icon(
              onPressed:
                  disabled || _sending || _sendingAttachment || _recordingVoice ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('إرسال', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
            if (_peerTyping)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'يكتب الآن...',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
