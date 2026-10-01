import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../orders/order_dialogs.dart';

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});
  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  String category = 'Meals';

  Future<void> pay() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;
    final total = ref.read(cartProvider.notifier).total;
    final cash = await showDialog<double>(
      context: context,
      builder: (_) => _CashDialog(total: total),
    );
    if (cash == null) return;
    if (cash < total) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient cash.')));
      return;
    }
    final order = ref.read(ordersProvider.notifier).createOrder(
      customer: 'Walk-in Customer',
      items: cart,
      total: total,
    );
    ref.read(cartProvider.notifier).clear();
    if (!mounted) return;
    await showReceiptDialog(context, order, cash: cash, change: cash - total);
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider).where((p) => p.category == category).toList();
    final cart = ref.watch(cartProvider);
    final total = ref.read(cartProvider.notifier).total;
    return Scaffold(
      appBar: AppBar(
        title: const Text('CASHIER POS'),
        actions: [
          IconButton(
            tooltip: 'POS order history',
            onPressed: () => showOrderHistoryDialog(
              context,
              ref.read(ordersProvider).where((order) => order.customer == 'Walk-in Customer').toList(),
              title: 'POS order history',
            ),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 150,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: ['Meals', 'Snacks', 'Drinks', 'Desserts'].map((c) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.tonal(
                    onPressed: () => setState(() => category = c),
                    child: Text(c),
                  ),
                )).toList(),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190, mainAxisExtent: 150, crossAxisSpacing: 12, mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                return Card(
                  child: InkWell(
                    onTap: () => ref.read(cartProvider.notifier).add(p),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p.emoji, style: const TextStyle(fontSize: 42)),
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('₱${p.price.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: 360,
            child: Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('CURRENT ORDER', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        children: cart.map((item) => ListTile(
                          title: Text(item.product.name),
                          subtitle: Text('₱${item.product.price.toStringAsFixed(2)} × ${item.quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(onPressed: () => ref.read(cartProvider.notifier).remove(item.product), icon: const Icon(Icons.remove)),
                              Text('${item.quantity}'),
                              IconButton(onPressed: () => ref.read(cartProvider.notifier).add(item.product), icon: const Icon(Icons.add)),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('₱${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: FilledButton.icon(
                      onPressed: pay,
                      icon: const Icon(Icons.payments),
                      label: const Text('PAY CASH'),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CashDialog extends StatefulWidget {
  final double total;
  const _CashDialog({required this.total});
  @override State<_CashDialog> createState() => _CashDialogState();
}
class _CashDialogState extends State<_CashDialog> {
  final controller = TextEditingController();
  @override Widget build(BuildContext context) => AlertDialog(
    title: const Text('Cash Payment'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('TOTAL  ₱${widget.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cash received', prefixText: '₱ ')),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [50,100,200,500,1000].map((v) => ActionChip(label: Text('₱$v'), onPressed: () => controller.text = '$v')).toList()),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
      FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(controller.text)), child: const Text('CONFIRM')),
    ],
  );
}
