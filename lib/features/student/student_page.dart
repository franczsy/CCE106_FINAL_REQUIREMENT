import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/providers.dart';
import '../orders/order_dialogs.dart';

class StudentPage extends ConsumerStatefulWidget {
  const StudentPage({super.key, this.initialCategory = 'Meals'});

  final String initialCategory;

  @override
  ConsumerState<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends ConsumerState<StudentPage> {
  late String category;

  @override
  void initState() {
    super.initState();
    category = widget.initialCategory;
  }

  Future<void> checkout() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final customerDetails = await showDialog<_CustomerDetails>(
      context: context,
      builder: (_) => const _CustomerDetailsDialog(),
    );
    if (customerDetails == null) return;

    final order = ref
        .read(ordersProvider.notifier)
        .createOrder(
          customer: customerDetails.name,
          studentId: customerDetails.studentId,
          phoneNumber: customerDetails.phoneNumber,
          items: cart,
          total: ref.read(cartProvider.notifier).total,
        );
    ref.read(cartProvider.notifier).clear();
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Order #${order.orderNumber} Confirmed'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Show this QR code at Express Pickup.'),
              const SizedBox(height: 16),
              QrImageView(data: order.qrToken, size: 220),
              Text('Status: ${statusText(order.status)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => showReceiptDialog(context, order),
            child: const Text('RECEIPT'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref
        .watch(productsProvider)
        .where(
          (product) =>
              product.category == category ||
              (category == 'Snacks' && product.category == 'Desserts'),
        )
        .toList();
    final cart = ref.watch(cartProvider);
    final orders = ref
        .watch(ordersProvider)
        .where((order) => order.studentId.isNotEmpty)
        .toList();
    final cartCount = cart.fold<int>(0, (count, item) => count + item.quantity);
    final cartTotal = ref.read(cartProvider.notifier).total;
    const categories = ['Meals', 'Drinks', 'Snacks'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Ordering'),
        actions: [
          IconButton(
            tooltip: 'Order history',
            onPressed: () => showOrderHistoryDialog(
              context,
              orders,
              title: 'My order history',
            ),
            icon: const Icon(Icons.history_outlined),
          ),
          IconButton(
            tooltip: 'Back to menu',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ready to order?',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Choose your campus favorites and head to pickup when ready.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.fastfood_outlined,
                            size: 34,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final option = categories[index];
                        return ChoiceChip(
                          label: Text(option),
                          selected: option == category,
                          onSelected: (_) => setState(() => category = option),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$category Menu',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${products.length} items',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          mainAxisExtent: 248,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: SizedBox(
                                  height: 64,
                                  width: 64,
                                  child: product.imageUrl != null
                                      ? Image.network(
                                          product.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Text(
                                            product.emoji,
                                            style: const TextStyle(
                                              fontSize: 48,
                                            ),
                                          ),
                                        )
                                      : product.imageBytes != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.memory(
                                            product.imageBytes!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            product.emoji,
                                            style: const TextStyle(
                                              fontSize: 48,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.description.isEmpty
                                    ? 'Freshly prepared campus favorite'
                                    : product.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '₱${product.price.toStringAsFixed(2)}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    tooltip: 'Add ${product.name} to cart',
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .add(product),
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.add_shopping_cart),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (orders.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent orders',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () => showOrderHistoryDialog(
                            context,
                            orders,
                            title: 'My order history',
                          ),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                    ...orders
                        .take(2)
                        .map(
                          (order) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: QrImageView(data: order.qrToken, size: 52),
                            title: Text('Order #${order.orderNumber}'),
                            subtitle: Text(
                              '${statusText(order.status)} · ₱${order.total.toStringAsFixed(2)}',
                            ),
                            trailing: IconButton(
                              tooltip: 'View receipt',
                              onPressed: () =>
                                  showReceiptDialog(context, order),
                              icon: const Icon(Icons.receipt_long_outlined),
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
            Card(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Cart',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            cart.isEmpty
                                ? 'No items yet'
                                : '$cartCount items · ₱${cartTotal.toStringAsFixed(2)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: cart.isEmpty ? null : checkout,
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerDetails {
  final String name;
  final String studentId;
  final String phoneNumber;

  const _CustomerDetails({
    required this.name,
    required this.studentId,
    required this.phoneNumber,
  });
}

class _CustomerDetailsDialog extends StatefulWidget {
  const _CustomerDetailsDialog();

  @override
  State<_CustomerDetailsDialog> createState() => _CustomerDetailsDialogState();
}

class _CustomerDetailsDialogState extends State<_CustomerDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _CustomerDetails(
        name: _nameController.text.trim(),
        studentId: _studentIdController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Student details'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => _required(value, 'Enter your name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) => _required(value, 'Enter your student ID'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  final error = _required(value, 'Enter your phone number');
                  if (error != null) return error;
                  if (value!.trim().length < 7) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check),
          label: const Text('PLACE ORDER'),
        ),
      ],
    );
  }

  String? _required(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }
}
