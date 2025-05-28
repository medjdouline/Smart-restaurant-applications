import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../order_history_service.dart';
import '../services/menu_service.dart';
import '../user_service.dart';
import '../cart_service.dart';
import './menu_invite.dart';

class Historique extends StatefulWidget {
  const Historique({Key? key}) : super(key: key);

  @override
  State<Historique> createState() => _HistoriqueState();
}

class _HistoriqueState extends State<Historique> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final orderHistory = Provider.of<OrderHistoryService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    final menuService = Provider.of<MenuService>(context, listen: false);
    
    // CORRECTION: Initialiser le MenuService dans OrderHistoryService
    orderHistory.setMenuService(menuService);
    orderHistory.setUserService(userService); // ADD THIS LINE
    
    if (userService.isLoggedIn && !userService.isGuest) {
      await orderHistory.loadOrderHistory();
    }
  }

  Widget _buildGuestMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 100,
            color: Colors.brown[300],
          ),
          const SizedBox(height: 20),
          Text(
            'Connectez-vous pour voir votre historique',
            style: TextStyle(
              color: Colors.brown[700],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'L\'historique des commandes est réservé aux utilisateurs connectés.',
            style: TextStyle(
              color: Colors.brown[500],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderHistory = Provider.of<OrderHistoryService>(context);
    final userService = Provider.of<UserService>(context);

    return Container(
      color: const Color(0xFFDFB976),
      child: Column(
        children: [
          _buildCentralTitle(),
          Expanded(
            child: userService.isGuest
                ? _buildGuestMessage()
                : _buildHistoryContent(orderHistory),
          ),
        ],
      ),
    );
  }

  // CORRECTION: Nouvelle méthode pour gérer le contenu de l'historique
  Widget _buildHistoryContent(OrderHistoryService orderHistory) {
    if (orderHistory.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF800000),
        ),
      );
    }

    if (orderHistory.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                color: Colors.brown[700],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              orderHistory.errorMessage!,
              style: TextStyle(
                color: Colors.brown[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF800000),
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (orderHistory.orders.isEmpty) {
      return _buildEmptyHistory();
    }

    return _buildHistoriqueSection(orderHistory.orders);
  }

  Widget _buildCentralTitle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF800000),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            'Historique',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 100,
            color: Colors.brown[300],
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune commande passée',
            style: TextStyle(
              color: Colors.brown[700],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Vos commandes apparaîtront ici',
            style: TextStyle(
              color: Colors.brown[500],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
Widget _buildHistoriqueSection(List<OrderHistoryItem> orders) {
  return RefreshIndicator(
    onRefresh: _loadData,
    color: const Color(0xFF800000),
    child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête de commande avec statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Commande #${order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Statut de la commande
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.etat),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(order.etat),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Date
                        Text(
                          '${order.date.day.toString().padLeft(2, '0')}/${order.date.month.toString().padLeft(2, '0')}/${order.date.year} ${order.date.hour.toString().padLeft(2, '0')}:${order.date.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Nombre total d'articles
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    '${order.items.fold(0, (sum, item) => sum + item.quantite)} article(s) commandé(s)',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Liste des articles avec plus de détails
                ...order.items.map((item) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          // Quantity badge
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF800000),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Text(
                                '${item.quantite}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Item details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nom,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${item.prix.toInt()} DA × ${item.quantite}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Total price for this item
                          Text(
                            '${(item.prix * item.quantite).toInt()} DA',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Total final
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${order.total.toInt()} DA',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),

                // Confirmation status
                if (order.confirmation != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        order.confirmation == true ? Icons.check_circle : Icons.pending,
                        color: order.confirmation == true ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.confirmation == true ? 'Confirmée' : 'En attente de confirmation',
                        style: TextStyle(
                          fontSize: 14,
                          color: order.confirmation == true ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

// Helper methods to add at the end of the _HistoriqueState class
Color _getStatusColor(String? etat) {
  switch (etat) {
    case 'en_attente':
      return Colors.orange;
    case 'en_preparation':
      return Colors.blue;
    case 'prete':
      return Colors.green;
    case 'livree':
      return Colors.purple;
    case 'annulee':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String _getStatusText(String? etat) {
  switch (etat) {
    case 'en_attente':
      return 'En attente';
    case 'en_preparation':
      return 'En préparation';
    case 'prete':
      return 'Prête';
    case 'livree':
      return 'Livrée';
    case 'annulee':
      return 'Annulée';
    default:
      return 'Statut inconnu';
  }
}

}