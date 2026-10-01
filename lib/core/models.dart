import 'dart:typed_data';

enum UserRole { student, cashier, kitchen, pickup, admin }

enum OrderStatus { pending, paid, preparing, ready, completed, cancelled }

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String emoji;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final String description;
  final bool available;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.emoji,
    this.imageBytes,
    this.imageUrl,
    this.description = '',
    this.available = true,
  });
}

class CartItem {
  final Product product;
  int quantity;
  final List<String> modifiers;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.modifiers = const [],
  });

  double get total => product.price * quantity;
}

class Order {
  final String id;
  final String orderNumber;
  final String customer;
  final String studentId;
  final String phoneNumber;
  final List<CartItem> items;
  OrderStatus status;
  final DateTime createdAt;
  final double total;
  final String qrToken;

  Order({
    required this.id,
    required this.orderNumber,
    required this.customer,
    this.studentId = '',
    this.phoneNumber = '',
    required this.items,
    required this.status,
    required this.createdAt,
    required this.total,
    required this.qrToken,
  });
}
