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
    // Utiliser la méthode modifiée pour obtenir le numéro de table
  String tableNumber = order.getActualTableNumber();
    
    // Déterminer le texte du statut et la couleur
    String statusText = '';
    Color statusColor = Colors.grey;
    
    switch (order.status.toLowerCase()) {
      case 'pending':
      case 'new':
      case 'en_attente':
      case 'en attente':
        statusText = 'En attente';
        statusColor = Colors.orange;
        break;
      case 'preparing':
      case 'en preparation':
      case 'en_preparation':
        statusText = 'En préparation';
        statusColor = Colors.blue;
        break;
      case 'ready':
      case 'pret':
      case 'prete':
        statusText = 'Prête';
        statusColor = Colors.green;
        break;
      case 'served':
      case 'servi':
      case 'servie':
        statusText = 'Servie';
        statusColor = Colors.purple;
        break;
      case 'cancelled':
      case 'annule':
      case 'annulee':
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
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.accentColor,
                child: Icon(
                  Icons.table_restaurant,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Table $tableNumber',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
Text(
  '${order.items.isNotEmpty ? order.items.length : order.customerCount} Éléments',
  style: const TextStyle(
    color: Colors.black54,
    fontSize: 12,
  ),
),
                  ],
                ),
              ),
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
          // Ajout du bouton Annuler seulement si la commande n'est pas déjà annulée ou servie
          if (order.status.toLowerCase() != 'cancelled' && 
              order.status.toLowerCase() != 'annule' && 
              order.status.toLowerCase() != 'annulee' && 
              order.status.toLowerCase() != 'served' && 
              order.status.toLowerCase() != 'servi' && 
              order.status.toLowerCase() != 'servie')
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onActionPressed,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Annuler'),
              ),
            ),
        ],
      ),
    ),
  );
  }
}