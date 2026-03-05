import 'account_mode_service.dart';
import 'messaging_service.dart';
import 'notification_service.dart';

class UnreadBadges {
  final int notifications;
  final int chats;

  const UnreadBadges({
    required this.notifications,
    required this.chats,
  });
}

class UnreadBadgeService {
  static Future<UnreadBadges> fetch() async {
    final mode = await AccountModeService.apiMode();
    final results = await Future.wait<int>([
      NotificationService.fetchUnreadCount(mode: mode),
      MessagingService.fetchUnreadCount(mode: mode),
    ]);
    return UnreadBadges(
      notifications: results[0],
      chats: results[1],
    );
  }
}
