// lib/widgets/tables/order_detail_modal.dart
import 'package:app_serveur/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/order.dart';


class OrderDetailModal extends StatelessWidget {
  final Order order;

  const OrderDetailModal({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate total price
    final totalPrice = order.items.fold(
      0.0, 
      (sum, item) => sum + (item.price * (item.quantity ?? 1))
    );

    // Format dates
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm');
    final formattedDate = dateFormat.format(order.createdAt);
    final formattedTime = timeFormat.format(order.createdAt);

    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with table info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppTheme.accentColor,
                      child: Icon(Icons.table_restaurant, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Table ${order.getActualTableNumber()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${order.items.length} Éléments',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Date and time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  formattedTime,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            
            // Items list header
            const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Éléments',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Qté',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Prix',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            
            // Items list
            ...order.items.map((item) {
              final orderItem = item is OrderItem ? item : OrderItem.fromJson(item as Map<String, dynamic>);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(orderItem.name),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${orderItem.quantity}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${orderItem.price.toStringAsFixed(2)} €',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            const Divider(),
            
            // Total
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${totalPrice.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            // Notes if available
            if (order.notes != null && order.notes!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Notes:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  Text(order.notes!),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'served':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'new':
        return 'En attente';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prête';
      case 'served':
        return 'Servie';
      case 'cancelled':
        return 'Annulée';
      default:
        return 'Inconnu';
    }
  }
}