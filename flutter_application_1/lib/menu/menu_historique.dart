import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../order_history_service.dart';

class Historique extends StatelessWidget {
  const Historique({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderHistory = Provider.of<OrderHistoryService>(context);
    final orders = orderHistory.orders;

    return Container(
      color: const Color(0xFFDFB976),
      child: Column(
        children: [
          // Titre central uniquement
          _buildCentralTitle(),

          // Liste des commandes ou message vide
          Expanded(
            child: orders.isEmpty
                ? _buildEmptyHistory()
                : _buildHistoriqueSection(orders),
          ),
        ],
      ),
    );
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
    return ListView.builder(
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
                // En-tête de commande
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Commande #${order.id.substring(order.id.length - 6)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${order.date.day}/${order.date.month}/${order.date.year} ${order.date.hour}:${order.date.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Liste des articles
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '• ${item.nom}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          Text(
                            'x${item.quantite}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(item.prix * item.quantite).toInt()} DA',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 10),
                const Divider(),

                // Détails de la réduction si appliquée
                if (order.reductionAppliquee) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sous-total',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${(order.total + order.montantReduction).toInt()} DA',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Réduction 50%',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '-${order.montantReduction.toInt()} DA',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${order.total.toInt()} DA',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),

                // Points utilisés
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Points utilisés',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${order.pointsUtilises} pts',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}