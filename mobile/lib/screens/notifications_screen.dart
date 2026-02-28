import 'package:flutter/material.dart';
import 'notification_settings_screen.dart'; // ✅ صفحة الإعدادات

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // ✅ بيانات الإشعارات
  List<Map<String, dynamic>> notifications = [
    {
      "icon": Icons.warning_amber_rounded,
      "title": "لديك طلب عاجل",
      "subtitle": "عميل: محمد الغامدي • منذ 5 دقائق",
      "color": Colors.red,
      "urgent": true,
      "important": false,
      "pinned": false,
    },
    {
      "icon": Icons.person_add_alt,
      "title": "قام @111222 بمتابعة منصتك",
      "subtitle": "16:35 • 01/01/2024",
      "color": Colors.deepPurple,
      "urgent": false,
      "important": false,
      "pinned": false,
    },
    {
      "icon": Icons.hourglass_bottom, // ⏳ للباقة
      "title": "قرب انتهاء فترة الباقة",
      "subtitle":
          "تنبيه: ستنتهي باقتك الحالية بعد 3 أيام. يُوصى بتجديد الاشتراك للاستمرار بالخدمات.",
      "color": Colors.orange,
      "urgent": false,
      "important": false,
      "pinned": false,
    },
    {
      "icon": Icons.campaign,
      "title": "عرض خاص لليوم الوطني 🇸🇦",
      "subtitle":
          "كود الخصم: SAUDIA95 — احصل على 20% خصم على الترويج الإعلاني بمناسبة اليوم الوطني.",
      "color": Colors.green,
      "urgent": false,
      "important": false,
      "pinned": false,
    },
  ];

  // ✅ تحديث الترتيب
  void _reorderNotifications() {
    // العاجلة دائمًا بالأعلى
    notifications.sort((a, b) {
      if (a["urgent"] == true && b["urgent"] != true) return -1;
      if (b["urgent"] == true && a["urgent"] != true) return 1;
      if (a["pinned"] == true && b["pinned"] != true) return -1;
      if (b["pinned"] == true && a["pinned"] != true) return 1;
      return 0;
    });
  }

  // ✅ كارت الإشعار
  Widget _notificationCard(
    Map<String, dynamic> notification,
    int index,
    BuildContext context,
  ) {
    bool isUrgent = notification["urgent"] ?? false;
    bool isImportant = notification["important"] ?? false;
    bool isPinned = notification["pinned"] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isUrgent
                ? Colors.red
                : isImportant
                ? const Color(0xFFFFF8E1) // ذهبي فاتح
                : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            isImportant
                ? Border.all(color: Colors.amber, width: 2)
                : Border.all(color: Colors.transparent),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            notification["icon"],
            color:
                isUrgent
                    ? Colors.white
                    : isImportant
                    ? Colors.amber.shade800
                    : notification["color"],
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      notification["title"],
                      style: TextStyle(
                        fontFamily: "Cairo",
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color:
                            isUrgent
                                ? Colors.white
                                : isImportant
                                ? Colors.amber.shade900
                                : Colors.black87,
                      ),
                    ),
                    if (isPinned) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.push_pin,
                        color: Colors.deepPurple,
                        size: 18,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notification["subtitle"],
                  style: TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 12,
                    color:
                        isUrgent
                            ? Colors.white70
                            : isImportant
                            ? Colors.amber.shade700
                            : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // ✅ قائمة الخيارات
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'follow') {
                setState(() {
                  notification["important"] = !(notification["important"]);
                });
              } else if (value == 'pin') {
                setState(() {
                  notification["pinned"] = true;
                  _reorderNotifications();
                });
              } else if (value == 'unpin') {
                setState(() {
                  notification["pinned"] = false;
                  _reorderNotifications();
                });
              } else if (value == 'delete') {
                setState(() {
                  notifications.remove(notification);
                });
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 'follow',
                  child: Text(
                    (notification["important"] ?? false)
                        ? "⭐ إزالة التمييز"
                        : "⭐ تمييز مهم للمتابعة",
                  ),
                ),
                if (notification["pinned"] == true)
                  const PopupMenuItem(
                    value: 'unpin',
                    child: Text("❌ إلغاء التثبيت"),
                  )
                else
                  const PopupMenuItem(
                    value: 'pin',
                    child: Text("📌 تثبيت بالأعلى"),
                  ),
                const PopupMenuItem(value: 'delete', child: Text("🗑 حذف")),
              ];
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _reorderNotifications(); // ✅ تحديث الترتيب عند البناء
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor ?? Colors.deepPurple,
          title: const Text(
            "الإشعارات",
            style: TextStyle(
              fontFamily: "Cairo",
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return _notificationCard(notifications[index], index, context);
          },
        ),
      ),
    );
  }
}
