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
    
    orderHistory.setMenuService(menuService);
    orderHistory.setUserService(userService);
    
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
      return Column(
        children: [
          _buildCancellationRequestsSection(orderHistory.cancellationRequests),
          Expanded(child: _buildHistoriqueSection(orderHistory.orders)),
        ],
      );
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
                  if (_canCancelOrder(order.etat)) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showCancelDialog(order),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: Text(
                          order.etat == 'en_attente' 
                            ? 'Annuler la commande'
                            : 'Demander l\'annulation'
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
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

  Widget _buildCancellationRequestsSection(List<CancellationRequest> requests) {
    if (requests.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Demandes d\'annulation en cours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.brown[700],
            ),
          ),
        ),
        ...requests.map((request) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Commande #${request.orderId.substring(request.orderId.length > 6 ? request.orderId.length - 6 : 0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCancellationStatusColor(request.statut),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getCancellationStatusText(request.statut),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (request.motif.isNotEmpty) ...[
                  Text(
                    'Motif: ${request.motif}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  '${request.createdAt.day.toString().padLeft(2, '0')}/${request.createdAt.month.toString().padLeft(2, '0')}/${request.createdAt.year} ${request.createdAt.hour.toString().padLeft(2, '0')}:${request.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  bool _canCancelOrder(String? etat) {
    return etat != null && ['en_attente', 'en_preparation', 'prete'].contains(etat);
  }

  Future<void> _showCancelDialog(OrderHistoryItem order) async {
    final TextEditingController motifController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Annuler la commande'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Êtes-vous sûr de vouloir annuler la commande #${order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0)} ?'),
                const SizedBox(height: 16),
                if (order.etat == 'en_attente')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cette commande sera annulée immédiatement.',
                            style: TextStyle(color: Colors.orange[700], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pending_outlined, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Une demande d\'annulation sera envoyée au manager.',
                            style: TextStyle(color: Colors.blue[700], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: motifController,
                  decoration: const InputDecoration(
                    labelText: 'Motif (optionnel)',
                    hintText: 'Raison de l\'annulation...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _cancelOrder(order, motifController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelOrder(OrderHistoryItem order, String motif) async {
    final orderHistory = Provider.of<OrderHistoryService>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF800000)),
      ),
    );
    
    try {
      final success = await orderHistory.cancelOrder(order.id, motif: motif.isNotEmpty ? motif : null);
      
      Navigator.of(context).pop();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              order.etat == 'en_attente' 
                ? 'Commande annulée avec succès'
                : 'Demande d\'annulation envoyée au manager'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'annulation'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur réseau'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

Color _getStatusColor(String? etat) {
    switch (etat) {
      case 'en_attente':
        return Colors.orange;
      case 'en_preparation':
        return Colors.blue;
      case 'prete':
      case 'pret':
      case 'prets':
        return const Color(0xFF4CAF50); // Vert plus vif pour "prêt"
      case 'servi':
      case 'servie':
        return const Color(0xFF9C27B0); // Violet pour "servi"
      case 'annulee':
      case 'annule':
        return const Color(0xFFE53935); // Rouge pour "annulé"
      case 'livree':
      case 'livre':
        return const Color(0xFF2E7D32); // Vert foncé pour "livré"
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
      case 'pret':
      case 'prets':
        return 'Prête';
      case 'servi':
      case 'servie':
        return 'Servie';
      case 'annulee':
      case 'annule':
        return 'Annulée';
      case 'livree':
      case 'livre':
        return 'Livrée';
      default:
        return 'Statut inconnu';
    }
  }

  Color _getCancellationStatusColor(String statut) {
    switch (statut) {
      case 'en_attente':
        return Colors.orange;
      case 'approuvee':
        return Colors.green;
      case 'rejetee':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getCancellationStatusText(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'approuvee':
        return 'Approuvée';
      case 'rejetee':
        return 'Rejetée';
      default:
        return 'Inconnu';
    }
  }
}