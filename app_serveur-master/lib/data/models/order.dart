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

    List<dynamic> items = [];
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((item) {
            if (item is OrderItem) return item;
            return OrderItem.fromJson(item as Map<String, dynamic>);
          })
          .toList();
    }

    // Récupérer tableId correctement depuis différentes structures possibles
    String tableId = '';
    
    // Format 1: via la structure 'table' du backend
    if (json['table'] != null && json['table']['id'] != null) {
      tableId = json['table']['id'] as String;
    } 
    // Format 2: via le champ 'tableId' direct
    else if (json['tableId'] != null) {
      tableId = json['tableId'] as String;
    }
    // Format 3: via le champ 'idTable' de l'API Python
    else if (json['idTable'] != null) {
      tableId = json['idTable'] as String;
    }

    // Extrait les données complètes de la table si disponibles
    Map<String, dynamic>? tableData;
    if (json['table'] != null && json['table'] is Map<String, dynamic>) {
      tableData = json['table'] as Map<String, dynamic>;
    }

    return Order(
      id: json['id'] as String,
      tableId: tableId,
      userId: json['userId'] as String? ?? json['idC'] as String? ?? '',
      status: json['status'] as String? ?? json['etat'] as String? ?? 'unknown',
      items: items,
      createdAt: parsedCreatedAt,
      customerCount: json['customerCount'] as int? ?? json['items']?.length ?? 0,
      updatedAt: parsedUpdatedAt,
      notes: json['notes'] as String?,
      tableData: tableData,
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
    );
  }
  
  // Méthode améliorée pour extraire le numéro de table
 String getActualTableNumber() {
    // Si nous avons des données de table complètes
    if (tableData != null && tableData!.containsKey('id')) {
      String tableIdentifier = tableData!['id'].toString();
      // Si l'ID de la table contient "table", extraire seulement le numéro
      if (tableIdentifier.toLowerCase().contains('table')) {
        return tableIdentifier.toLowerCase().replaceAll('table', '').trim();
      }
      return tableIdentifier;
    }
    
    // Sinon, utiliser directement idTable du document de commande (de l'API Python)
    if (tableId.isNotEmpty) {
      if (tableId.toLowerCase().contains('table')) {
        // Extraire le numéro après "table"
        String numberPart = tableId.toLowerCase().replaceAll('table', '').trim();
        return numberPart.isNotEmpty ? numberPart : '1'; // Valeur par défaut si vide
      }
      return tableId;
    }
    
    // Valeur par défaut si aucune information de table n'est disponible
    return '?';
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

    // Compatibilité avec le format de l'API Python
    final String idVal = json['id'] as String? ?? json['plat_id'] as String? ?? '';
    final String productIdVal = json['productId'] as String? ?? json['plat_id'] as String? ?? '';
    final String nameVal = json['name'] as String? ?? json['nom'] as String? ?? 'Produit';
    final int quantityVal = json['quantity'] as int? ?? json['quantite'] as int? ?? 1;
    final double priceVal = (json['price'] is num) 
        ? (json['price'] as num).toDouble() 
        : (json['prix'] is num) 
            ? (json['prix'] as num).toDouble() 
            : 0.0;

    return OrderItem(
      id: idVal,
      productId: productIdVal,
      name: nameVal,
      quantity: quantityVal,
      price: priceVal,
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