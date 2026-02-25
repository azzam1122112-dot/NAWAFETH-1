import 'package:flutter/material.dart';

import '../../models/client_order.dart';
import '../../services/marketplace_api.dart';
import '../client_order_details_screen.dart';

class ClientOrderDetailsWebEntryScreen extends StatefulWidget {
  const ClientOrderDetailsWebEntryScreen({
    super.key,
    required this.requestId,
  });

  final int requestId;

  @override
  State<ClientOrderDetailsWebEntryScreen> createState() =>
      _ClientOrderDetailsWebEntryScreenState();
}

class _ClientOrderDetailsWebEntryScreenState
    extends State<ClientOrderDetailsWebEntryScreen> {
  late Future<ClientOrder> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ClientOrder> _load() async {
    final data = await MarketplaceApi().getMyRequestDetail(requestId: widget.requestId);
    if (data == null) {
      throw StateError('تعذر تحميل تفاصيل الطلب.');
    }
    return ClientOrder.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ClientOrder>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError || snap.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل الطلب')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 44),
                    const SizedBox(height: 10),
                    const Text(
                      'تعذر تحميل تفاصيل الطلب',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'رقم الطلب: ${widget.requestId}',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(
                        'إعادة المحاولة',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ClientOrderDetailsScreen(order: snap.data!);
      },
    );
  }
}

