import 'package:flutter/material.dart';

import 'client_web_shell_screen.dart';

class ClientOrdersWebPage extends StatelessWidget {
  const ClientOrdersWebPage({
    super.key,
    this.routeState,
  });

  final ClientOrdersRouteState? routeState;

  @override
  Widget build(BuildContext context) {
    return ClientWebShellScreen(
      section: ClientWebSection.orders,
      ordersRouteState: routeState,
    );
  }
}

