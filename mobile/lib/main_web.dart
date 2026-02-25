import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/entry_screen.dart';
import 'screens/home_screen.dart';
import 'screens/interactive_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/orders_hub_screen.dart';
import 'screens/client_dashboard/client_order_details_web_entry_screen.dart';
import 'screens/client_dashboard/client_web_sections.dart';
import 'screens/client_dashboard/client_web_shell_screen.dart';
import 'screens/provider_dashboard/provider_order_details_web_entry_screen.dart';
import 'screens/provider_dashboard/provider_web_shell_screen.dart';
import 'screens/provider_dashboard/provider_web_sections.dart';
import 'screens/request_quote_screen.dart';
import 'screens/role_mode_access_guard_screen.dart';
import 'screens/search_provider_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/add_service_screen.dart';
import 'screens/chats_web_screen.dart';
import 'screens/urgent_request_screen.dart';
import 'services/app_navigation.dart';
import 'services/app_snackbar.dart';
import 'services/role_controller.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/web_global_loading_overlay.dart';
import 'widgets/web_global_inline_banner_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RoleController.instance.initialize();
  runApp(const NawafethWebApp());
}

class NawafethWebApp extends StatefulWidget {
  const NawafethWebApp({super.key});

  @override
  State<NawafethWebApp> createState() => _NawafethWebAppState();
}

class _NawafethWebAppState extends State<NawafethWebApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ar', 'SA');

  void _changeTheme(ThemeMode mode) => setState(() => _themeMode = mode);
  void _changeLanguage(Locale locale) => setState(() => _locale = locale);

  Widget _guardClient(Widget child, {String? intendedPath}) {
    return RoleModeAccessGuardScreen(
      mode: WebDashboardRoleMode.client,
      intendedPath: intendedPath,
      child: child,
    );
  }

  Widget _guardProvider(Widget child, {String? intendedPath}) {
    return RoleModeAccessGuardScreen(
      mode: WebDashboardRoleMode.provider,
      intendedPath: intendedPath,
      child: child,
    );
  }

  Widget _buildProtectedNotificationsRoute() {
    final isProviderMode = RoleController.instance.notifier.value.isProvider;
    if (isProviderMode) {
      return _guardProvider(
        const ProviderWebShellScreen(section: ProviderWebSection.notifications),
        intendedPath: '/notifications',
      );
    }
    return _guardClient(
      const ClientWebShellScreen(section: ClientWebSection.notifications),
      intendedPath: '/notifications',
    );
  }

  Widget _buildProtectedProfileRoute() {
    final isProviderMode = RoleController.instance.notifier.value.isProvider;
    if (isProviderMode) {
      return _guardProvider(
        const ProviderWebShellScreen(section: ProviderWebSection.profile),
        intendedPath: '/profile',
      );
    }
    return _guardClient(
      const ClientWebShellScreen(section: ClientWebSection.profile),
      intendedPath: '/profile',
    );
  }

  Widget _guardNonStaffWebApp(Widget child, {String? intendedPath}) {
    return StaffBlockForFlutterWebScreen(
      intendedPath: intendedPath,
      child: child,
    );
  }

  WidgetBuilder _publicWebRouteBuilder(
    String routePath,
    Widget child,
  ) {
    return (_) => _guardNonStaffWebApp(
          child,
          intendedPath: routePath,
        );
  }

  WidgetBuilder _clientWebRouteBuilder(
    String routePath,
    Widget child,
  ) {
    return (_) => _guardClient(
          child,
          intendedPath: routePath,
        );
  }

  WidgetBuilder _providerWebRouteBuilder(
    String routePath,
    Widget child,
  ) {
    return (_) => _guardProvider(
          child,
          intendedPath: routePath,
        );
  }

  Route<dynamic> _clientGeneratedRoute(RouteSettings settings, Widget child) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => _guardClient(
        child,
        intendedPath: settings.name,
      ),
    );
  }

  Route<dynamic> _publicGeneratedRoute(RouteSettings settings, Widget child) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => _guardNonStaffWebApp(
        child,
        intendedPath: settings.name,
      ),
    );
  }

  Route<dynamic> _providerGeneratedRoute(RouteSettings settings, Widget child) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => _guardProvider(
        child,
        intendedPath: settings.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MyThemeController(
      changeTheme: _changeTheme,
      themeMode: _themeMode,
      changeLanguage: _changeLanguage,
      locale: _locale,
      child: MaterialApp(
        title: 'Nawafeth Web',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        themeMode: _themeMode,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: _locale,
        supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return WebGlobalInlineBannerOverlay(
            child: WebGlobalLoadingOverlay(
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        onGenerateRoute: (settings) {
          final name = settings.name ?? '';
          if (name.isEmpty) return null;

          if (name == '/chats') {
            final args = settings.arguments;
            if (args is Map) {
              int? asInt(dynamic v) {
                if (v is int) return v;
                if (v is num) return v.toInt();
                return int.tryParse((v ?? '').toString().trim());
              }

              String? asText(dynamic v) {
                final s = (v ?? '').toString().trim();
                return s.isEmpty ? null : s;
              }

              return _publicGeneratedRoute(
                settings,
                ChatsWebScreen(
                  requestId: asInt(args['requestId']),
                  threadId: asInt(args['threadId']),
                  name: asText(args['name']),
                  isDirect: args['isDirect'] == true,
                  requestCode: asText(args['requestCode']),
                  requestTitle: asText(args['requestTitle']),
                  peerId: asText(args['peerId']),
                  peerName: asText(args['peerName']),
                ),
              );
            }
            return _publicGeneratedRoute(settings, const ChatsWebScreen());
          }

          final uri = Uri.tryParse(name);
          if (uri == null) return null;
          final segments = uri.pathSegments;

          if (segments.isNotEmpty && segments[0] == 'chats') {
            int? intQuery(String key) =>
                int.tryParse((uri.queryParameters[key] ?? '').trim());
            String? textQuery(List<String> keys) {
              for (final key in keys) {
                final s = (uri.queryParameters[key] ?? '').trim();
                if (s.isNotEmpty) return s;
              }
              return null;
            }

            bool boolQuery(List<String> keys) {
              final raw = (textQuery(keys) ?? '').toLowerCase();
              return raw == '1' || raw == 'true' || raw == 'yes';
            }

            final pathThreadId =
                segments.length >= 2 ? int.tryParse(segments[1]) : null;

            return _publicGeneratedRoute(
              settings,
              ChatsWebScreen(
                requestId: intQuery('requestId') ?? intQuery('request_id'),
                threadId:
                    intQuery('threadId') ?? intQuery('thread_id') ?? pathThreadId,
                name: textQuery(const ['name']),
                isDirect: boolQuery(const ['direct', 'isDirect', 'is_direct']),
                requestCode: textQuery(const ['requestCode', 'request_code']),
                requestTitle: textQuery(const ['requestTitle', 'request_title']),
                peerId: textQuery(const ['peerId', 'peer_id']),
                peerName: textQuery(const ['peerName', 'peer_name']),
                initialSearchQuery: textQuery(const ['q', 'search']),
                initialFilter: textQuery(const ['filter']),
              ),
            );
          }

          // Supports:
          // /provider_dashboard/orders/<id>
          // /provider_dashboard/order/<id>
          if (segments.length == 3 &&
              segments[0] == 'client_dashboard' &&
              (segments[1] == 'orders' || segments[1] == 'order')) {
            final requestId = int.tryParse(segments[2]);
            if (requestId != null && requestId > 0) {
              return _clientGeneratedRoute(
                settings,
                ClientOrderDetailsWebEntryScreen(
                  requestId: requestId,
                ),
              );
            }
          }

          if (segments.length == 2 &&
              segments[0] == 'client_dashboard' &&
              segments[1] == 'orders') {
            String? cleanParam(String key) {
              final v = (uri.queryParameters[key] ?? '').trim();
              return v.isEmpty ? null : v;
            }

            final routeState = ClientOrdersRouteState(
              searchQuery: cleanParam('q') ?? cleanParam('search'),
              statusFilter: cleanParam('status'),
              typeFilter: cleanParam('type'),
            );

            return _clientGeneratedRoute(
              settings,
              ClientOrdersWebPage(routeState: routeState),
            );
          }

          if (segments.length == 1 && segments[0] == 'search_provider') {
            String? cleanParam(String key) {
              final v = (uri.queryParameters[key] ?? '').trim();
              return v.isEmpty ? null : v;
            }

            final categoryId = int.tryParse(
              (uri.queryParameters['category'] ?? uri.queryParameters['category_id'] ?? '')
                  .trim(),
            );

            final hasAnyFilter =
                categoryId != null ||
                cleanParam('q') != null ||
                cleanParam('search') != null ||
                cleanParam('city') != null;

            if (hasAnyFilter) {
              return _publicGeneratedRoute(
                settings,
                SearchProviderScreen.withFilters(
                  initialCategoryId: categoryId,
                  initialQuery: cleanParam('q') ?? cleanParam('search'),
                  initialCity: cleanParam('city'),
                ),
              );
            }
          }

          if (segments.length == 3 &&
              segments[0] == 'provider_dashboard' &&
              (segments[1] == 'orders' || segments[1] == 'order')) {
            final requestId = int.tryParse(segments[2]);
            if (requestId != null && requestId > 0) {
              return _providerGeneratedRoute(
                settings,
                ProviderOrderDetailsWebEntryScreen(
                  requestId: requestId,
                ),
              );
            }
          }

          // Supports query-driven provider orders page, e.g.
          // /provider_dashboard/orders?tab=urgent&q=riyadh&urgent_status=new

          if (segments.length == 2 &&
              segments[0] == 'provider_dashboard' &&
              segments[1] == 'orders') {
            int tabIndexFromQuery(String? raw) {
              final v = (raw ?? '').trim().toLowerCase();
              if (v == '1' || v == 'urgent' || v == 'عاجل') return 1;
              if (v == '2' || v == 'competitive' || v == 'quotes' || v == 'عروض') {
                return 2;
              }
              return 0;
            }

            String? cleanParam(String key) {
              final v = (uri.queryParameters[key] ?? '').trim();
              return v.isEmpty ? null : v;
            }

            final routeState = ProviderOrdersRouteState(
              tabIndex: tabIndexFromQuery(uri.queryParameters['tab']),
              searchQuery: cleanParam('q') ?? cleanParam('search'),
              assignedStatus: cleanParam('assigned_status') ?? cleanParam('status'),
              urgentStatus: cleanParam('urgent_status'),
            );

            return _providerGeneratedRoute(
              settings,
              ProviderOrdersWebPage(routeState: routeState),
            );
          }

          if (segments.length == 2 &&
              segments[0] == 'provider_dashboard' &&
              segments[1] == 'services') {
            String? cleanParam(String key) {
              final v = (uri.queryParameters[key] ?? '').trim();
              return v.isEmpty ? null : v;
            }

            final routeState = ProviderServicesRouteState(
              searchQuery: cleanParam('q') ?? cleanParam('search'),
              statusFilter: cleanParam('status'),
            );

            return _providerGeneratedRoute(
              settings,
              ProviderServicesWebPage(routeState: routeState),
            );
          }

          if (segments.length == 2 &&
              segments[0] == 'provider_dashboard' &&
              segments[1] == 'reviews') {
            String? cleanParam(String key) {
              final v = (uri.queryParameters[key] ?? '').trim();
              return v.isEmpty ? null : v;
            }

            final minRating = int.tryParse((uri.queryParameters['min_rating'] ?? '').trim());

            final routeState = ProviderReviewsRouteState(
              searchQuery: cleanParam('q') ?? cleanParam('search'),
              replyFilter: cleanParam('reply'),
              minRating: minRating,
            );

            return _providerGeneratedRoute(
              settings,
              ProviderReviewsWebPage(routeState: routeState),
            );
          }

          return null;
        },
        initialRoute: '/entry',
        routes: {
          '/entry': _publicWebRouteBuilder('/entry', const EntryScreen()),
          '/onboarding':
              _publicWebRouteBuilder('/onboarding', const OnboardingScreen()),
          '/home': _publicWebRouteBuilder('/home', const HomeScreen()),
          '/orders': _publicWebRouteBuilder('/orders', const OrdersHubScreen()),
          '/add_service': _publicWebRouteBuilder(
            '/add_service',
            const AddServiceScreen(),
          ),
          '/search_provider': _publicWebRouteBuilder(
            '/search_provider',
            const SearchProviderScreen(),
          ),
          '/urgent_request': _publicWebRouteBuilder(
            '/urgent_request',
            const UrgentRequestScreen(),
          ),
          '/request_quote': _publicWebRouteBuilder(
            '/request_quote',
            const RequestQuoteScreen(),
          ),
          '/interactive': _publicWebRouteBuilder(
            '/interactive',
            ValueListenableBuilder<RoleState>(
              valueListenable: RoleController.instance.notifier,
              builder: (context, role, _) {
                return InteractiveScreen(
                  mode: role.isProvider
                      ? InteractiveMode.provider
                      : InteractiveMode.client,
                );
              },
            ),
          ),
          '/login': _publicWebRouteBuilder('/login', const LoginScreen()),
          '/notifications': (context) => _buildProtectedNotificationsRoute(),
          '/profile': (context) => _buildProtectedProfileRoute(),
          '/signup': _publicWebRouteBuilder('/signup', const SignUpScreen()),
          '/client_dashboard': _clientWebRouteBuilder(
            '/client_dashboard',
            const ClientWebShellScreen(section: ClientWebSection.summary),
          ),
          '/client_dashboard/orders': _clientWebRouteBuilder(
            '/client_dashboard/orders',
            const ClientOrdersWebPage(),
          ),
          '/client_dashboard/notifications': _clientWebRouteBuilder(
            '/client_dashboard/notifications',
            const ClientWebShellScreen(section: ClientWebSection.notifications),
          ),
          '/client_dashboard/profile': _clientWebRouteBuilder(
            '/client_dashboard/profile',
            const ClientWebShellScreen(section: ClientWebSection.profile),
          ),
          '/provider_dashboard': _providerWebRouteBuilder(
            '/provider_dashboard',
            const ProviderWebShellScreen(section: ProviderWebSection.summary),
          ),
          '/provider_dashboard/orders': _providerWebRouteBuilder(
            '/provider_dashboard/orders',
            const ProviderOrdersWebPage(),
          ),
          '/provider_dashboard/services': _providerWebRouteBuilder(
            '/provider_dashboard/services',
            const ProviderServicesWebPage(),
          ),
          '/provider_dashboard/reviews': _providerWebRouteBuilder(
            '/provider_dashboard/reviews',
            const ProviderReviewsWebPage(),
          ),
          '/provider_dashboard/notifications': _providerWebRouteBuilder(
            '/provider_dashboard/notifications',
            const ProviderNotificationsWebPage(),
          ),
          '/provider_dashboard/profile': _providerWebRouteBuilder(
            '/provider_dashboard/profile',
            const ProviderProfileWebPage(),
          ),
        },
        home: const EntryScreen(),
      ),
    );
  }
}
