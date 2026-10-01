import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/models.dart';

class KitchenPage extends ConsumerWidget {
  const KitchenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final newOrders = orders.where((o) => o.status == OrderStatus.paid).toList();
    final preparing = orders.where((o) => o.status == OrderStatus.preparing).toList();
    final ready = orders.where((o) => o.status == OrderStatus.ready).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('KITCHEN DISPLAY SYSTEM'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Row(
        children: [
          _Column(title: 'NEW', orders: newOrders, action: 'START', onAction: (o) => ref.read(ordersProvider.notifier).setStatus(o.id, OrderStatus.preparing)),
          _Column(title: 'PREPARING', orders: preparing, action: 'READY', onAction: (o) => ref.read(ordersProvider.notifier).setStatus(o.id, OrderStatus.ready)),
          _Column(title: 'READY', orders: ready, action: 'WAITING FOR PICKUP', onAction: null),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  final String title;
  final List<Order> orders;
  final String action;
  final void Function(Order)? onAction;

  const _Column({
    required this.title,
    required this.orders,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final o = orders[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${o.orderNumber}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(o.customer),
                          const Divider(),
                          ...o.items.map((x) => Text('${x.quantity}× ${x.product.name}')),
                          const SizedBox(height: 12),
                          if (onAction != null)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => onAction!(o),
                                child: Text(action),
                              ),
                            )
                          else
                            const Chip(label: Text('READY FOR PICKUP')),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
