// lib/widgets/tables/table_list_item.dart
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
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: table.isOccupied ? AppTheme.secondaryColor : const Color(0xFFE19356),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Row(
            children: [
              const Icon(
                Icons.restaurant,
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
                    table.isOccupied ? 'Occupée' : 'Libre',
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