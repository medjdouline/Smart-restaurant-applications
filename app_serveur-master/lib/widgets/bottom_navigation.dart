// lib/widgets/bottom_navigation.dart
import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, Icons.home, currentIndex == 0),
            _buildNavItem(1, Icons.restaurant_menu, currentIndex == 1),
            _buildNavItem(2, Icons.table_bar, currentIndex == 2),
            _buildNavItem(3, Icons.person, currentIndex == 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color:
              isSelected ? AppTheme.accentColor : Colors.white.withAlpha(200),
          size: 22,
        ),
      ),
    );
  }
}
