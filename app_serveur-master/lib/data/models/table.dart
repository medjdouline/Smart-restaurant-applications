// lib/data/models/table.dart

class RestaurantTable {
  final String id;
  final int capacity;
  final bool isOccupied;
  final int orderCount;
  final int customerCount;

  RestaurantTable({
    required this.id,
    required this.capacity,
    required this.isOccupied,
    required this.orderCount,
    required this.customerCount,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: json['id'] as String,
      capacity: json['capacity'] as int,
      isOccupied: json['isOccupied'] as bool,
      orderCount: json['orderCount'] as int,
      customerCount: json['customerCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'capacity': capacity,
      'isOccupied': isOccupied,
      'orderCount': orderCount,
      'customerCount': customerCount,
    };
  }

  // Add copyWith method to create a copy with modified fields
  RestaurantTable copyWith({
    String? id,
    int? capacity,
    bool? isOccupied,
    int? orderCount,
    int? customerCount,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      capacity: capacity ?? this.capacity,
      isOccupied: isOccupied ?? this.isOccupied,
      orderCount: orderCount ?? this.orderCount,
      customerCount: customerCount ?? this.customerCount,
    );
  }
}