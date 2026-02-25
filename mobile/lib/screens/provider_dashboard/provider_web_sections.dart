import 'package:flutter/material.dart';

import 'provider_web_shell_screen.dart';

class ProviderOrdersWebPage extends StatelessWidget {
  const ProviderOrdersWebPage({
    super.key,
    this.routeState,
  });

  final ProviderOrdersRouteState? routeState;

  @override
  Widget build(BuildContext context) {
    return ProviderWebShellScreen(
      section: ProviderWebSection.orders,
      ordersRouteState: routeState,
    );
  }
}

class ProviderServicesWebPage extends StatelessWidget {
  const ProviderServicesWebPage({
    super.key,
    this.routeState,
  });

  final ProviderServicesRouteState? routeState;

  @override
  Widget build(BuildContext context) {
    return ProviderWebShellScreen(
      section: ProviderWebSection.services,
      servicesRouteState: routeState,
    );
  }
}

class ProviderReviewsWebPage extends StatelessWidget {
  const ProviderReviewsWebPage({
    super.key,
    this.routeState,
  });

  final ProviderReviewsRouteState? routeState;

  @override
  Widget build(BuildContext context) {
    return ProviderWebShellScreen(
      section: ProviderWebSection.reviews,
      reviewsRouteState: routeState,
    );
  }
}

class ProviderNotificationsWebPage extends StatelessWidget {
  const ProviderNotificationsWebPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderWebShellScreen(
      section: ProviderWebSection.notifications,
    );
  }
}

class ProviderProfileWebPage extends StatelessWidget {
  const ProviderProfileWebPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderWebShellScreen(
      section: ProviderWebSection.profile,
    );
  }
}
