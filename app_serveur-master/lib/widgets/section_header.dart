// lib/widgets/home/section_header.dart
import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onSeeMorePressed;

  const SectionHeader({
    super.key,
    required this.title,
    required this.count,
    this.onSeeMorePressed,
  })  ;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              count > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: title == 'Nouvelles commandes'
                            ? const Color(0xFFF5EDD9)
                            : AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: title == 'Nouvelles commandes'
                              ? AppTheme.accentColor
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
          if (onSeeMorePressed != null)
            GestureDetector(
              onTap: onSeeMorePressed,
              child: const Text(
                'voir plus',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}