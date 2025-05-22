// lib/data/models/table.dart

class RestaurantTable {
  final String id;
  final int capacity;
  final bool isOccupied;
  final bool isReserved; 
  final int orderCount;
  final int customerCount;
  final DateTime? reservationStart; 
  final DateTime? reservationEnd; 
  final String? clientName; 
  final int? reservationPersonCount; 
  final String? reservationStatus; 

  RestaurantTable({
    required this.id,
    required this.capacity,
    required this.isOccupied,
    this.isReserved = false,
    required this.orderCount,
    required this.customerCount,
    this.reservationStart,
    this.reservationEnd,
    this.clientName,
    this.reservationPersonCount,
    this.reservationStatus,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: json['id'] as String,
      capacity: json['capacity'] as int,
      isOccupied: json['isOccupied'] as bool,
      isReserved: json['isReserved'] as bool? ?? false,
      orderCount: json['orderCount'] as int,
      customerCount: json['customerCount'] as int,
      reservationStart: json['reservationStart'] != null 
          ? DateTime.parse(json['reservationStart']) 
          : null,
      reservationEnd: json['reservationEnd'] != null 
          ? DateTime.parse(json['reservationEnd']) 
          : null,
      clientName: json['clientName'] as String?,
      reservationPersonCount: json['reservationPersonCount'] as int?,
      reservationStatus: json['reservationStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'capacity': capacity,
      'isOccupied': isOccupied,
      'isReserved': isReserved,
      'orderCount': orderCount,
      'customerCount': customerCount,
      'reservationStart': reservationStart?.toIso8601String(),
      'reservationEnd': reservationEnd?.toIso8601String(),
      'clientName': clientName,
      'reservationPersonCount': reservationPersonCount,
      'reservationStatus': reservationStatus,
    };
  }

  // Add copyWith method to create a copy with modified fields
  RestaurantTable copyWith({
    String? id,
    int? capacity,
    bool? isOccupied,
    bool? isReserved,
    int? orderCount,
    int? customerCount,
    DateTime? reservationStart,
    DateTime? reservationEnd,
    String? clientName,
    int? reservationPersonCount,
    String? reservationStatus,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      capacity: capacity ?? this.capacity,
      isOccupied: isOccupied ?? this.isOccupied,
      isReserved: isReserved ?? this.isReserved,
      orderCount: orderCount ?? this.orderCount,
      customerCount: customerCount ?? this.customerCount,
      reservationStart: reservationStart ?? this.reservationStart,
      reservationEnd: reservationEnd ?? this.reservationEnd,
      clientName: clientName ?? this.clientName,
      reservationPersonCount: reservationPersonCount ?? this.reservationPersonCount,
      reservationStatus: reservationStatus ?? this.reservationStatus,
    );
  }
}