// lib/widgets/home/order_card.dart
import 'package:flutter/material.dart';
import '../../data/models/order.dart';
import '../../utils/theme.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onActionPressed;
  final bool isNew; 

  const OrderCard({
    super.key,
    required this.order,
    required this.onActionPressed,
    required this.isNew,
  });

  @override
  Widget build(BuildContext context) {
    // Déterminer le texte du statut et la couleur
    String statusText = '';
    Color statusColor = Colors.grey;
    
    switch (order.status.toLowerCase()) {
      case 'pending':
        statusText = 'En attente';
        statusColor = Colors.orange;
        break;
      case 'preparing':
        statusText = 'En préparation';
        statusColor = Colors.blue;
        break;
      case 'ready':
        statusText = 'Prête';
        statusColor = Colors.green;
        break;
      case 'served':
        statusText = 'Servie';
        statusColor = Colors.purple;
        break;
      case 'cancelled':
        statusText = 'Annulée';
        statusColor = Colors.red;
        break;
      default:
        statusText = order.status;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppTheme.accentColor,
              child: Icon(
                Icons.table_restaurant,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            // Détails de la commande (uniquement table et nombre d'éléments)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Table ${order.tableId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${order.customerCount} Éléments',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Affichage du statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}