import 'package:flutter/material.dart';

import '../services/account_api.dart';
import '../services/role_controller.dart';
import '../services/session_storage.dart';
import '../services/web_inline_banner.dart';
import '../services/web_loading_overlay.dart';
import '../utils/local_user_state.dart';

class WebShellAccountActions extends StatefulWidget {
  const WebShellAccountActions({
    super.key,
    required this.roleLabel,
    this.accentColor = const Color(0xFF475569),
  });

  final String roleLabel;
  final Color accentColor;

  @override
  State<WebShellAccountActions> createState() => _WebShellAccountActionsState();
}

class _WebShellAccountActionsState extends State<WebShellAccountActions> {
  late Future<_WebShellSessionInfo> _sessionFuture;
  bool _loggingOut = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _loadSessionInfo();
  }

  Future<_WebShellSessionInfo> _loadSessionInfo() async {
    try {
      final me = await AccountApi().me(forceRefresh: true);
      final first = (me['first_name'] ?? '').toString().trim();
      final last = (me['last_name'] ?? '').toString().trim();
      final username = (me['username'] ?? '').toString().trim();
      final fullName = [if (first.isNotEmpty) first, if (last.isNotEmpty) last].join(' ').trim();
      final displayName = fullName.isNotEmpty
          ? fullName
          : (username.isNotEmpty ? '@$username' : 'الحساب');
      return _WebShellSessionInfo(displayName: displayName);
    } catch (_) {
      // Fall back to locally cached session profile values.
    }

    const storage = SessionStorage();
    final fullName = (await storage.readFullName())?.trim();
    final username = (await storage.readUsername())?.trim();
    final displayName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : ((username != null && username.isNotEmpty) ? '@$username' : 'الحساب');
    return _WebShellSessionInfo(displayName: displayName);
  }

  Future<void> _refreshAccountContext() async {
    if (_refreshing || _loggingOut) return;
    setState(() => _refreshing = true);
    bool refreshed = false;
    try {
      await WebLoadingOverlayController.instance.run(() async {
        AccountApi.invalidateMeCache();
        try {
          await RoleController.instance.syncFromBackend();
          refreshed = true;
        } catch (_) {
          await RoleController.instance.refreshFromPrefs();
          refreshed = true;
        }
      }, message: 'جاري تحديث بيانات الحساب...');
      if (!mounted) return;
      setState(() {
        _sessionFuture = _loadSessionInfo();
      });
      WebInlineBannerController.instance.success('تم تحديث بيانات الحساب.');
    } catch (_) {
      WebInlineBannerController.instance.error(
        refreshed ? 'تم تحديث الدور محليًا لكن تعذر تحديث بيانات الحساب.' : 'تعذر تحديث بيانات الحساب حاليًا.',
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await WebLoadingOverlayController.instance.run(() async {
        await LocalUserState.clearOnLogout();
        await const SessionStorage().clear();
        AccountApi.invalidateMeCache();
        await RoleController.instance.refreshFromPrefs();
      }, message: 'جاري تسجيل الخروج...');
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/entry', (route) => false);
    } catch (_) {
      WebInlineBannerController.instance.error('تعذر تسجيل الخروج حاليًا.');
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_WebShellSessionInfo>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        final info = snapshot.data ?? const _WebShellSessionInfo(displayName: 'الحساب');
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.accentColor.withAlpha(14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: widget.accentColor.withAlpha(45)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_circle_outlined, size: 17, color: widget.accentColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${info.displayName} • ${widget.roleLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              enabled: !(_loggingOut || _refreshing),
              tooltip: 'الحساب',
              onSelected: (value) async {
                if (value == 'refresh') {
                  await _refreshAccountContext();
                }
                if (value == 'logout') {
                  await _logout();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'identity',
                  enabled: false,
                  child: Text(
                    info.displayName,
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: widget.accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _refreshing ? 'جاري التحديث...' : 'تحديث البيانات',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFB91C1C)),
                      const SizedBox(width: 8),
                      Text(
                        _loggingOut ? 'جاري تسجيل الخروج...' : 'تسجيل الخروج',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: _loggingOut
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.accentColor,
                        ),
                      )
                    : _refreshing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.accentColor,
                        ),
                      )
                    : Icon(Icons.more_vert_rounded, color: widget.accentColor, size: 18),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WebShellSessionInfo {
  const _WebShellSessionInfo({required this.displayName});

  final String displayName;
}
