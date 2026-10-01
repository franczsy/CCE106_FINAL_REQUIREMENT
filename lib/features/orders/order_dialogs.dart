import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../core/providers.dart';

Future<void> showReceiptDialog(
  BuildContext context,
  Order order, {
  double? cash,
  double? change,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ReceiptDialog(order: order, cash: cash, change: change),
  );
}

Future<void> showOrderHistoryDialog(
  BuildContext context,
  List<Order> orders, {
  String title = 'Order history',
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _OrderHistoryDialog(title: title, orders: orders),
  );
}

class _ReceiptDialog extends StatelessWidget {
  final Order order;
  final double? cash;
  final double? change;

  const _ReceiptDialog({required this.order, this.cash, this.change});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Receipt #${order.orderNumber}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(order.customer, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('Status: ${statusText(order.status)}'),
            Text('${order.createdAt}'),
            const Divider(),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text('${item.quantity}x ${item.product.name}')),
                  Text('P${item.total.toStringAsFixed(2)}'),
                ],
              ),
            )),
            const Divider(),
            _ReceiptLine(label: 'Total', value: 'P${order.total.toStringAsFixed(2)}', emphasized: true),
            if (cash != null) _ReceiptLine(label: 'Cash', value: 'P${cash!.toStringAsFixed(2)}'),
            if (change != null) _ReceiptLine(label: 'Change', value: 'P${change!.toStringAsFixed(2)}'),
            if (order.studentId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Student ID: ${order.studentId}'),
              Text('Phone: ${order.phoneNumber}'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
      ],
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _ReceiptLine({required this.label, required this.value, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: emphasized ? FontWeight.w800 : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

class _OrderHistoryDialog extends StatelessWidget {
  final String title;
  final List<Order> orders;

  const _OrderHistoryDialog({required this.title, required this.orders});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: orders.isEmpty
            ? const Text('No orders yet.')
            : ListView.separated(
                shrinkWrap: true,
                itemCount: orders.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, index) {
                  final order = orders[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Order #${order.orderNumber}'),
                    subtitle: Text('${statusText(order.status)} - P${order.total.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      tooltip: 'View receipt',
                      icon: const Icon(Icons.receipt_long_outlined),
                      onPressed: () => showReceiptDialog(context, order),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
      ],
    );
  }
}
