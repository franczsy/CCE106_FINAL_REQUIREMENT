import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';

final productsProvider = NotifierProvider<ProductsNotifier, List<Product>>(
  ProductsNotifier.new,
);

class ProductsNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() => const [
    Product(
      id: 'p1',
      name: 'Chicken Meal',
      category: 'Meals',
      price: 85,
      emoji: '🍗',
      imageUrl: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=800&q=85',
      description: 'Juicy chicken with rice and savory sides.',
    ),
    Product(
      id: 'p2',
      name: 'Burger Steak',
      category: 'Meals',
      price: 75,
      emoji: '🍔',
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=85',
      description: 'Hearty burger steak with a rich gravy finish.',
    ),
    Product(
      id: 'p3',
      name: 'Spaghetti',
      category: 'Meals',
      price: 65,
      emoji: '🍝',
      imageUrl: 'https://images.unsplash.com/photo-1551892374-ecf8754cf8b0?auto=format&fit=crop&w=800&q=85',
      description: 'Classic tomato spaghetti made for quick hunger fixes.',
    ),
    Product(
      id: 'p4',
      name: 'Fries',
      category: 'Snacks',
      price: 40,
      emoji: '🍟',
      imageUrl: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=800&q=85',
      description: 'Crispy golden fries, perfect for sharing.',
    ),
    Product(
      id: 'p5',
      name: 'Iced Tea',
      category: 'Drinks',
      price: 25,
      emoji: '🧋',
      imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?auto=format&fit=crop&w=800&q=85',
      description: 'Cool and refreshing sweet iced tea.',
    ),
    Product(
      id: 'p6',
      name: 'Soft Drink',
      category: 'Drinks',
      price: 30,
      emoji: '🥤',
      imageUrl: 'https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=800&q=85',
      description: 'Chilled soda for a quick energy boost.',
    ),
    Product(
      id: 'p7',
      name: 'Ice Cream',
      category: 'Desserts',
      price: 35,
      emoji: '🍦',
      imageUrl: 'https://images.unsplash.com/photo-1501446529957-6226bd447c46?auto=format&fit=crop&w=800&q=85',
      description: 'Creamy dessert to cool down after class.',
    ),
  ];

  void add(Product product) => state = [...state, product];

  void update(Product product) {
    state = [
      for (final item in state)
        if (item.id == product.id) product else item,
    ];
  }

  void remove(String productId) {
    state = state.where((product) => product.id != productId).toList();
  }
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void add(Product p) {
    final existing = state.where((x) => x.product.id == p.id).firstOrNull;
    if (existing != null) {
      existing.quantity++;
      state = [...state];
    } else {
      state = [...state, CartItem(product: p)];
    }
  }

  void remove(Product p) {
    final item = state.where((x) => x.product.id == p.id).firstOrNull;
    if (item == null) return;
    if (item.quantity > 1) {
      item.quantity--;
      state = [...state];
    } else {
      state = state.where((x) => x.product.id != p.id).toList();
    }
  }

  void clear() => state = [];

  double get total => state.fold(0, (sum, item) => sum + item.total);
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

class OrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() => [];

  Order createOrder({
    required String customer,
    String studentId = '',
    String phoneNumber = '',
    required List<CartItem> items,
    required double total,
  }) {
    final n = 1001 + state.length;
    final order = Order(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      orderNumber: n.toString(),
      customer: customer,
      studentId: studentId,
      phoneNumber: phoneNumber,
      items: items
          .map(
            (x) => CartItem(
              product: x.product,
              quantity: x.quantity,
              modifiers: x.modifiers,
            ),
          )
          .toList(),
      status: OrderStatus.paid,
      createdAt: DateTime.now(),
      total: total,
      qrToken: 'SMART-CANTEEN-$n-${DateTime.now().millisecondsSinceEpoch}',
    );
    state = [order, ...state];
    return order;
  }

  void setStatus(String id, OrderStatus status) {
    final order = state.firstWhere((x) => x.id == id);
    order.status = status;
    state = [...state];
  }

  Order? byQr(String token) {
    try {
      return state.firstWhere((x) => x.qrToken == token);
    } catch (_) {
      return null;
    }
  }

  List<Order> byCustomer(String customer) {
    return state.where((x) => x.customer == customer).toList();
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(
  OrdersNotifier.new,
);

String statusText(OrderStatus s) => switch (s) {
  OrderStatus.pending => 'Pending',
  OrderStatus.paid => 'New',
  OrderStatus.preparing => 'Preparing',
  OrderStatus.ready => 'Ready',
  OrderStatus.completed => 'Completed',
  OrderStatus.cancelled => 'Cancelled',
};
