// lib/data/models/order.dart
class Order {
  final String id;
  final String tableId;
  final String userId;
  final String status;
  final List<dynamic> items;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final int customerCount;
  final Map<String, dynamic>? tableData;
  final Map<String, dynamic>? clientData;
  final Map<String, dynamic>? serverData;
  final double? totalAmount;
  final double? calculatedTotal;
  final bool? confirmation;

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
    this.tableData,
    this.clientData,
    this.serverData,
    this.totalAmount,
    this.calculatedTotal,
    this.confirmation,
  });
  int get displayItemCount {
  if (items.isNotEmpty) {
    return items.fold(0, (sum, item) => sum + (item is OrderItem ? item.quantity : 1));
  }
  return customerCount;
}

  factory Order.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedAt;
    DateTime? parsedUpdatedAt;
    
    try {
      // Handle different date field names
      String? dateStr = json['createdAt'] as String? ?? 
                        json['dateCreation'] as String? ??
                        DateTime.now().toIso8601String();
      parsedCreatedAt = DateTime.parse(dateStr);
      
      parsedUpdatedAt = json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt'] as String) 
        : null;
    } catch (e) {
      parsedCreatedAt = DateTime.now();
      parsedUpdatedAt = null;
    }

    // Handle items - prioritize the detailed API format
    List<dynamic> items = [];
    if (json['items'] != null) {
      items = (json['items'] as List).map((item) {
        if (item is OrderItem) return item;
        
        // Handle the detailed format from get_order_details API
        if (item is Map<String, dynamic> && item.containsKey('dish')) {
          return OrderItem.fromDetailedJson(item);
        }
        
        return OrderItem.fromJson(item as Map<String, dynamic>);
      }).toList();
    }

    // Extract table ID and data
    String tableId = '';
    Map<String, dynamic>? tableData;
    
    // Handle detailed API response format
    if (json['table'] != null && json['table'] is Map<String, dynamic>) {
      tableData = json['table'] as Map<String, dynamic>;
      tableId = tableData['id'] as String? ?? '';
    } 
    // Handle direct tableId field
    else if (json['tableId'] != null) {
      tableId = json['tableId'] as String;
    }
    // Handle idTable field from Python API
    else if (json['idTable'] != null) {
      tableId = json['idTable'] as String;
    }

    // Extract client data and userId
    String userId = '';
    Map<String, dynamic>? clientData;
    
    // Handle detailed API response format
    if (json['client'] != null && json['client'] is Map<String, dynamic>) {
      clientData = json['client'] as Map<String, dynamic>;
      userId = clientData['id'] as String? ?? '';
    }
    // Fallback to other possible userId fields
    else {
      userId = json['userId'] as String? ?? 
               json['idC'] as String? ?? '';
    }

    // Extract server data
    Map<String, dynamic>? serverData;
    if (json['server'] != null && json['server'] is Map<String, dynamic>) {
      serverData = json['server'] as Map<String, dynamic>;
    }

    // Extract customer count
    int customerCount = 0;
    if (json['total_quantity'] != null) {
      customerCount = json['total_quantity'] as int;
    } else if (json['items_count'] != null) {
      customerCount = json['items_count'] as int;
    } else if (json['customerCount'] != null) {
      customerCount = json['customerCount'] as int;
    } else if (tableData != null && tableData['nbrPersonne'] != null) {
      customerCount = tableData['nbrPersonne'] as int;
    } else if (json['items'] != null) {
      customerCount = (json['items'] as List).length;
    }

    // Extract status - handle different status field names
    String status = json['status'] as String? ?? 
                   json['etat'] as String? ?? 
                   'unknown';

    // Extract total amounts
    double? totalAmount;
    double? calculatedTotal;
    
    if (json['montant'] != null) {
      totalAmount = (json['montant'] as num).toDouble();
    }
    if (json['calculated_total'] != null) {
      calculatedTotal = (json['calculated_total'] as num).toDouble();
    }

    return Order(
      id: json['id'] as String,
      tableId: tableId,
      userId: userId,
      status: status,
      items: items,
      createdAt: parsedCreatedAt,
      customerCount: customerCount,
      updatedAt: parsedUpdatedAt,
      notes: json['notes'] as String?,
      tableData: tableData,
      clientData: clientData,
      serverData: serverData,
      totalAmount: totalAmount,
      calculatedTotal: calculatedTotal,
      confirmation: json['confirmation'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableId': tableId,
      'userId': userId,
      'status': status,
      'items': items.map((item) {
        if (item is OrderItem) {
          return item.toJson();
        }
        return item;
      }).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'customerCount': customerCount,
      'notes': notes,
      'tableData': tableData,
      'clientData': clientData,
      'serverData': serverData,
      'totalAmount': totalAmount,
      'calculatedTotal': calculatedTotal,
      'confirmation': confirmation,
    };
  }

  Order copyWith({
    String? id,
    String? tableId,
    String? userId,
    String? status,
    List<dynamic>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    int? customerCount,
    Map<String, dynamic>? tableData,
    Map<String, dynamic>? clientData,
    Map<String, dynamic>? serverData,
    double? totalAmount,
    double? calculatedTotal,
    bool? confirmation,
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
      tableData: tableData ?? this.tableData,
      clientData: clientData ?? this.clientData,
      serverData: serverData ?? this.serverData,
      totalAmount: totalAmount ?? this.totalAmount,
      calculatedTotal: calculatedTotal ?? this.calculatedTotal,
      confirmation: confirmation ?? this.confirmation,
    );
  }
  
  // Improved method to extract table number
  String getActualTableNumber() {
    // If we have complete table data
    if (tableData != null && tableData!.containsKey('id')) {
      String tableIdentifier = tableData!['id'].toString();
      // If table ID contains "table", extract only the number
      if (tableIdentifier.toLowerCase().contains('table')) {
        return tableIdentifier.toLowerCase().replaceAll('table', '').trim();
      }
      return tableIdentifier;
    }
    
    // Otherwise, use tableId directly
    if (tableId.isNotEmpty) {
      if (tableId.toLowerCase().contains('table')) {
        // Extract number after "table"
        String numberPart = tableId.toLowerCase().replaceAll('table', '').trim();
        return numberPart.isNotEmpty ? numberPart : '1';
      }
      return tableId;
    }
    
    return '?';
  }

  // Get client username - prioritize clientData
  String getClientUsername() {
    if (clientData != null && clientData!['username'] != null) {
      return clientData!['username'] as String;
    }
    return userId.isNotEmpty ? userId : 'Client inconnu';
  }

  // Get total price
  double getTotalPrice() {
    if (calculatedTotal != null && calculatedTotal! > 0) {
      return calculatedTotal!;
    }
    if (totalAmount != null && totalAmount! > 0) {
      return totalAmount!;
    }
    // Calculate from items
    return items.fold(0.0, (sum, item) {
      if (item is OrderItem) {
        return sum + (item.price * item.quantity);
      }
      return sum;
    });
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final List<String>? options;
  final String? description;
  final double? note;
  final int? estimation;

  OrderItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.description,
    this.options,
    this.note,
    this.estimation,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    List<String>? options;
    if (json['options'] != null) {
      options = (json['options'] as List).map((e) => e as String).toList();
    }

    return OrderItem(
      id: json['id'] as String? ?? json['plat_id'] as String? ?? '',
      productId: json['productId'] as String? ?? json['plat_id'] as String? ?? '',
      name: json['name'] as String? ?? json['nom'] as String? ?? 'Produit',
      quantity: json['quantity'] as int? ?? json['quantite'] as int? ?? 1,
      price: (json['price'] is num) 
          ? (json['price'] as num).toDouble() 
          : (json['prix'] is num) 
              ? (json['prix'] as num).toDouble() 
              : 0.0,
      description: json['description'] as String?,
      options: options,
      note: json['note'] != null ? (json['note'] as num).toDouble() : null,
      estimation: json['estimation'] as int?,
    );
  }

  // Updated factory method for the detailed API response
  factory OrderItem.fromDetailedJson(Map<String, dynamic> json) {
    final dish = json['dish'] as Map<String, dynamic>?;
    
    return OrderItem(
      id: dish?['id'] as String? ?? '',
      productId: dish?['id'] as String? ?? '',
      name: dish?['nom'] as String? ?? 'Produit inconnu',
      quantity: json['quantity'] as int? ?? 1,
      price: json['unit_price'] != null 
          ? (json['unit_price'] as num).toDouble() 
          : (dish?['prix'] != null ? (dish!['prix'] as num).toDouble() : 0.0),
      description: dish?['description'] as String?,
      note: dish?['note'] != null ? (dish!['note'] as num).toDouble() : null,
      estimation: dish?['estimation'] as int?,
      options: null, // Not provided in current API format
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'description': description,
      'options': options,
      'note': note,
      'estimation': estimation,
    };
  }
  
}
