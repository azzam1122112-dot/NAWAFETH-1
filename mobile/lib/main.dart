import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

// 🟣 الشاشات الرئيسية
import 'screens/home_screen.dart';
import 'screens/my_chats_screen.dart';
import 'screens/chat_detail_screen.dart';
import 'screens/interactive_screen.dart';
import 'screens/my_profile_screen.dart';
import 'screens/add_service_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/provider_dashboard/provider_home_screen.dart';

// 🟢 الشاشات الجديدة
import 'screens/login_screen.dart';
import 'screens/search_provider_screen.dart';
import 'screens/urgent_request_screen.dart';
import 'screens/request_quote_screen.dart';
import 'screens/orders_hub_screen.dart';

// 🆕 شاشة الترحيب (Onboarding)
import 'screens/onboarding_screen.dart';
import 'screens/entry_screen.dart';

import 'services/app_snackbar.dart';
import 'services/app_navigation.dart';
import 'services/fcm_notification_service.dart';
import 'services/notifications_badge_controller.dart';
import 'services/role_controller.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  await RoleController.instance.initialize();
  await FcmNotificationService.instance.initialize();
  NotificationsBadgeController.instance.initialize();
  runApp(const NawafethApp());
}

class NawafethApp extends StatefulWidget {
  const NawafethApp({super.key});

  @override
  State<NawafethApp> createState() => _NawafethAppState();
}

class _NawafethAppState extends State<NawafethApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ar', 'SA'); // ✅ اللغة الافتراضية العربية

  /// 🔄 تبديل الثيم
  void _changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  /// 🔄 تبديل اللغة
  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MyThemeController(
      changeTheme: _changeTheme,
      themeMode: _themeMode,
      changeLanguage: _changeLanguage,
      locale: _locale,
      child: MaterialApp(
        title: 'Nawafeth App',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        scaffoldMessengerKey: rootScaffoldMessengerKey,

        // ✅ إعدادات الثيم
        themeMode: _themeMode,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeAnimationDuration: const Duration(milliseconds: 220),
        themeAnimationCurve: Curves.easeOutCubic,

        // ✅ دعم تعدد اللغات
        locale: _locale,
        supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        onGenerateRoute: (settings) {
          if (settings.name == '/chats') {
            final args = settings.arguments;
            if (args is Map) {
              final requestId = _asInt(args['requestId']);
              final threadId = _asInt(args['threadId']);
              final name = (args['name'] ?? '').toString().trim();
              final isOnline = args['isOnline'] == true;
              final requestCode = (args['requestCode'] ?? '').toString().trim();
              final requestTitle = (args['requestTitle'] ?? '')
                  .toString()
                  .trim();
              final isDirect = args['isDirect'] == true;
              final peerId = (args['peerId'] ?? '').toString().trim();
              final peerName = (args['peerName'] ?? '').toString().trim();
              if (requestId != null || threadId != null) {
                return MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    name: name.isEmpty ? (isDirect ? 'محادثة مباشرة' : 'محادثة الطلب') : name,
                    isOnline: isOnline,
                    requestId: requestId,
                    threadId: threadId,
                    requestCode: requestCode.isEmpty ? null : requestCode,
                    requestTitle: requestTitle.isEmpty ? null : requestTitle,
                    isDirect: isDirect,
                    peerId: peerId.isEmpty ? null : peerId,
                    peerName: peerName.isEmpty ? null : peerName,
                  ),
                );
              }
            }
            return MaterialPageRoute(builder: (_) => const MyChatsScreen());
          }
          return null;
        },

        // ✅ المسارات
        initialRoute: '/home', // بدء التطبيق مباشرة من الصفحة الرئيسية
        routes: {
          '/entry': (context) => const EntryScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const HomeScreen(),
          '/orders': (context) => const OrdersHubScreen(),
          '/interactive': (context) => ValueListenableBuilder<RoleState>(
            valueListenable: RoleController.instance.notifier,
            builder: (context, role, _) {
              return InteractiveScreen(
                mode: role.isProvider
                    ? InteractiveMode.provider
                    : InteractiveMode.client,
              );
            },
          ),
          '/profile': (context) => const MyProfileScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/add_service': (context) => const AddServiceScreen(),

          // Provider dashboard (separate from bottom-nav core screens)
          '/provider_dashboard': (context) => const ProviderHomeScreen(),

          // ✅ الشاشات الجديدة
          '/login': (context) => const LoginScreen(),
          '/search_provider': (context) => const SearchProviderScreen(),
          '/urgent_request': (context) => const UrgentRequestScreen(),
          '/request_quote': (context) => const RequestQuoteScreen(),
        },
      ),
    );
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString());
  }
}
