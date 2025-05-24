// lib/widgets/tables/order_detail_modal.dart
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
    final totalPrice = order.items.fold(
      0.0, 
      (sum, item) => sum + (item.price * item.quantity)
    );
    
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm');
    final formattedDate = dateFormat.format(order.createdAt);
    final formattedTime = timeFormat.format(order.createdAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with client and table info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client: ${order.userId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Table: ${order.getActualTableNumber()}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  if (order.tableData?['nbrPersonne'] != null)
                    Text(
                      '${order.tableData?['nbrPersonne']} personnes',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _getStatusText(order.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Date and time
          Row(
            children: [
              Expanded(
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          const Divider(),
          
          // Items header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Éléments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Qté',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Prix',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Items list
          Column(
            children: order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (item is OrderItem && item.description?.isNotEmpty == true)
                            Text(
                              item.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
  '${(item.price * item.quantity).toStringAsFixed(2)} DA',
  style: const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
  ),
),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          const Divider(),
          
          // Total
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
  '${totalPrice.toStringAsFixed(2)} DA',
  style: const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
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
                const Text(
                  'Notes:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(order.notes!),
              ],
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'new':
      case 'en_attente':
        return Colors.orange;
      case 'preparing':
      case 'en_preparation':
        return Colors.blue;
      case 'ready':
      case 'pret':
      case 'prete':
        return Colors.green;
      case 'served':
      case 'servi':
      case 'servie':
        return Colors.purple;
      case 'cancelled':
      case 'annule':
      case 'annulee':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'new':
      case 'en_attente':
        return 'En attente';
      case 'preparing':
      case 'en_preparation':
        return 'En préparation';
      case 'ready':
      case 'pret':
      case 'prete':
        return 'Prête';
      case 'served':
      case 'servi':
      case 'servie':
        return 'Servie';
      case 'cancelled':
      case 'annule':
      case 'annulee':
        return 'Annulée';
      default:
        return status;
    }
  }
}