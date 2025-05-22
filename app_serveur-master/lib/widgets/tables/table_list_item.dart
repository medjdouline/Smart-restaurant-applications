import 'package:flutter/material.dart';
import '../../data/models/table.dart';
import '../../utils/theme.dart';

class TableListItem extends StatelessWidget {
  final RestaurantTable table;
  final Function onTap;

  const TableListItem({
    super.key,
    required this.table,
    required this.onTap,
  });

 @override
  Widget build(BuildContext context) {
    // Déterminer la couleur de la table en fonction de son statut
    Color tableColor;
    if (table.isOccupied) {
      tableColor = AppTheme.secondaryColor; // Rouge pour occupée
    } else if (table.isReserved) {
      tableColor = const Color(0xFFAA2C10); // Violet pour réservée
    } else {
      tableColor = const Color(0xFFE19356); // Orange pour libre
    }

    // Déterminer le statut affiché
    String tableStatus;
    if (table.isOccupied) {
      tableStatus = 'Occupée';
    } else if (table.isReserved) {
      tableStatus = 'Réservée';
    } else {
      tableStatus = 'Libre';
    }

    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: tableColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Row(
            children: [
              Icon(
                table.isReserved && !table.isOccupied ? Icons.event_available : Icons.restaurant,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    table.id,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tableStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}