import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_service.dart';

class PointsFideliteWidget extends StatelessWidget {
  const PointsFideliteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text(
            '${cartService.totalPointsFidelite} pts',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (cartService.reductionDisponible)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cartService.reductionActive ? Colors.green : Colors.amber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  cartService.reductionActive ? 'RÉDUCTION ACTIVE' : '-50% DISPO',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}