// lib/data/models/order.dart
class Order {
  final String id;
  final String tableId;
  final String userId;
  final String status;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final int customerCount;

  Order({
    required this.id,
    required this.tableId,
    required this.userId,
    required this.status,
    required this.items,
    required this.createdAt,
    required this.customerCount,
    this.updatedAt,
    this.notes,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedAt;
    DateTime? parsedUpdatedAt;
    
    try {
      parsedCreatedAt = DateTime.parse(json['createdAt'] as String);
      parsedUpdatedAt = json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt'] as String) 
        : null;
    } catch (e) {
      parsedCreatedAt = DateTime.now();
      parsedUpdatedAt = null;
    }

    List<OrderItem> items = [];
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    }

    return Order(
      id: json['id'] as String,
      tableId: json['tableId'] as String,
      userId: json['userId'] as String,
      status: json['status'] as String,
      items: items,
      createdAt: parsedCreatedAt,
      customerCount: json['customerCount'] as int,
      updatedAt: parsedUpdatedAt,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableId': tableId,
      'userId': userId,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'customerCount': customerCount,
      'notes': notes,
    };
  }

  Order copyWith({
    String? id,
    String? tableId,
    String? userId,
    String? status,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    int? customerCount,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      customerCount: customerCount ?? this.customerCount,
    );
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final List<String>? options;

  OrderItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.options,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    List<String>? options;
    if (json['options'] != null) {
      options = (json['options'] as List).map((e) => e as String).toList();
    }

    return OrderItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      options: options,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'options': options,
    };
  }
}