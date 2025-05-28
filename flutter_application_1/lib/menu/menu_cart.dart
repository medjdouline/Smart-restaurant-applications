import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cart_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);
    @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String? _selectedTableId;

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final cartItems = cartService.items.values.toList();

    return Scaffold(
      body: Container(
        color: const Color(0xFFE6C89D),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40, left: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, 
                            color: Colors.brown[700], 
                            size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    'Votre Commande',
                    style: TextStyle(
                      color: Colors.brown[700],
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: cartItems.isEmpty 
                ? _buildEmptyCart()
                : _buildCartList(cartItems, cartService),
            ),
            
            if (cartItems.isNotEmpty)
              _buildCartSummary(context, cartService),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.brown[300],
          ),
          const SizedBox(height: 20),
          Text(
            'Auncune Commande',
            style: TextStyle(
              color: Colors.brown[700],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ajoutez des plats à votre commande',
            style: TextStyle(
              color: Colors.brown[500],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(List<CartItem> cartItems, CartService cartService) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: NetworkImage(item.imageUrl ?? 'https://via.placeholder.com/150'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nom,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${item.prix.toInt()} DA (${item.pointsFidelite} pts)',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.brown[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.red[400],
                      onPressed: () => cartService.removeSingleItem(item.id),
                    ),
                    Text(
                      '${item.quantite}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: Colors.green[600],
                      onPressed: () => cartService.addItem(
                        id: item.id,
                        nom: item.nom,
                        prix: item.prix,
                        imageUrl: item.imageUrl,
                        pointsFidelite: item.pointsFidelite,
                      ),
                    ),
                  ],
                ),
                
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[600],
                  onPressed: () => cartService.removeItem(item.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartSummary(BuildContext context, CartService cartService) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AJOUTER CE WIDGET POUR LA SÉLECTION DE TABLE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTableId,
                hint: const Text('Sélectionner une table'),
                isExpanded: true,
                items: List.generate(7, (index) => 'table${index + 1}')
                    .map((tableId) => DropdownMenuItem<String>(
                          value: tableId,
                          child: Text('Table ${tableId.substring(5)}'),
                        ))
                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTableId = newValue;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 15),
          
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      '${cartService.totalPointsFidelite} pts',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (cartService.reductionActive)
                  Text(
                    'Réduction de 50% appliquée!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sous-total:', style: theme.textTheme.bodyMedium),
                Text(
                  '${cartService.montantAvantReduction.toInt()} DA',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          if (cartService.reductionActive)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Réduction (50%):', style: theme.textTheme.bodyMedium),
                  Text(
                    '-${cartService.montantReduction.toInt()} DA',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${cartService.totalAmount.toInt()} DA',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: _selectedTableId == null 
                ? null  // Désactiver si aucune table sélectionnée
                : () => cartService.confirmOrder(context, _selectedTableId!),  // Passer la table
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedTableId == null 
                  ? Colors.grey 
                  : const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              _selectedTableId == null 
                  ? 'SÉLECTIONNER UNE TABLE' 
                  : 'CONFIRMER LA COMMANDE',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}