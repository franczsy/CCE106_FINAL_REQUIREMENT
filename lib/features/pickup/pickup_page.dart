import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/providers.dart';
import '../../core/models.dart';

class PickupPage extends ConsumerStatefulWidget {
  const PickupPage({super.key});
  @override ConsumerState<PickupPage> createState() => _PickupPageState();
}

class _PickupPageState extends ConsumerState<PickupPage> {
  bool scanning = false;

  void verify(String token) {
    final order = ref.read(ordersProvider.notifier).byQr(token);
    setState(() => scanning = false);
    if (order == null) {
      _message('INVALID QR CODE', false);
      return;
    }
    if (order.status != OrderStatus.ready) {
      _message('ORDER NOT READY — ${statusText(order.status).toUpperCase()}', false);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('✓ ORDER VERIFIED'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Order #${order.orderNumber}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(order.customer),
          const Divider(),
          ...order.items.map((x) => Text('${x.quantity}× ${x.product.name}')),
        ]),
        actions: [
          FilledButton(
            onPressed: () {
              ref.read(ordersProvider.notifier).setStatus(order.id, OrderStatus.completed);
              Navigator.pop(context);
              _message('ORDER RELEASED', true);
            },
            child: const Text('RELEASE ORDER'),
          ),
        ],
      ),
    );
  }

  void _message(String text, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR EXPRESS PICKUP'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.qr_code_scanner, size: 90),
              const SizedBox(height: 20),
              Text('EXPRESS PICKUP', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Scan the student QR code to verify the order.'),
              const SizedBox(height: 28),
              if (scanning)
                SizedBox(
                  height: 350,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MobileScanner(onDetect: (capture) {
                      final code = capture.barcodes.firstOrNull?.rawValue;
                      if (code != null) verify(code);
                    }),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: () => setState(() => scanning = true),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('SCAN QR CODE'),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
