// lib/screens/orders/orders_screen.dart (with fixes)
// ignore_for_file: unnecessary_type_check, unnecessary_cast

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/orders/order_bloc.dart';
import '../../blocs/orders/order_event.dart';
import '../../blocs/orders/order_state.dart';
import '../../data/models/order.dart';
import '../../utils/theme.dart';
import '../../widgets/bottom_navigation.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _currentIndex = 1; // Index pour la barre de navigation (commandes)

  @override
  void initState() {
    super.initState();
    // Charger les commandes au démarrage
    context.read<OrderBloc>().add(LoadOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state.status == OrderStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Une erreur est survenue'),
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<OrderBloc>().add(LoadOrders());
                },
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Filtres en haut
                    _buildFilters(state),
                    const SizedBox(height: 20),
                    // Liste des commandes
                    Expanded(
                      child:
                          state.status == OrderStatus.loading
                              ? const Center(child: CircularProgressIndicator())
                              : _buildOrdersList(state),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) => _navigateToScreen(context, index),
      ),
    );
  }

 Widget _buildFilters(OrderState state) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _buildFilterButton('Tous', state),
        const SizedBox(width: 8),
        _buildFilterButton('En attente', state),
        const SizedBox(width: 8),
        _buildFilterButton('En préparation', state),
        const SizedBox(width: 8),
        _buildFilterButton('Prête', state),
        const SizedBox(width: 8),
        _buildFilterButton('Servie', state),
        const SizedBox(width: 8),
        _buildFilterButton('Annulées', state),
      ],
    ),
  );
}

  Widget _buildFilterButton(String filter, OrderState state) {
    final isSelected = state.currentFilter == filter;

    return GestureDetector(
      onTap: () {
        context.read<OrderBloc>().add(FilterOrders(filter: filter));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(OrderState state) {
    if (state.filteredOrders.isEmpty) {
      return const Center(
        child: Text(
          'Aucune commande disponible',
          style: TextStyle(color: AppTheme.accentColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: state.filteredOrders.length,
      itemBuilder: (context, index) {
        final order = state.filteredOrders[index];
        return _buildOrderCard(order, state.currentFilter);
      },
    );
  }


Widget _buildOrderCard(Order order, String currentFilter) {
  // Déterminer l'état et les actions disponibles pour la commande
  bool isWaiting = order.status == 'new';
  bool isPreparing = order.status == 'preparing';
  bool isReady = order.status == 'ready';
  bool isServed = order.status == 'served';
  bool isCancelled = order.status == 'cancelled';

  // Texte du statut à afficher
  String statusText = '';
  Color statusColor = Colors.grey;

  switch (order.status.toLowerCase()) {
    case 'pending':
      statusText = 'En attente';
      statusColor = Colors.orange;
      break;
    case 'preparing':
      statusText = 'En préparation';
      statusColor = Colors.blue;
      break;
    case 'ready':
      statusText = 'Prête';
      statusColor = Colors.green;
      break;
    case 'served':
      statusText = 'Servie';
      statusColor = Colors.purple;
      break;
    case 'cancelled':
      statusText = 'Annulée';
      statusColor = Colors.red;
      break;
    default:
      statusText = order.status; // Afficher le statut brut si inconnu
  }
  
  // Placer l'InkWell à l'extérieur du Card pour que les événements tactiles fonctionnent correctement
  return InkWell(
    onTap: () {
      _showOrderDetailsModal(context, order);
    },
    child: Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête modifié: seulement table, nombre d'éléments et statut
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.accentColor,
                  child: Icon(Icons.table_restaurant, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.tableId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${order.customerCount} Éléments',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                const Spacer(),
                // Badge d'état
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Boutons d'action
            Row(
              children: [
                // Ne pas afficher de boutons d'action pour les commandes déjà servies ou annulées
                if (!isServed && !isCancelled) ...[
                  // Bouton Servir (uniquement pour les commandes prêtes)
                  if (isReady)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Confirmation avant de servir la commande
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirmer'),
                                content: const Text('Marquer cette commande comme servie ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.read<OrderBloc>().add(
                                        ConfirmOrderServed(orderId: order.id),
                                      );
                                    },
                                    child: const Text('Confirmer'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                        ),
                        child: const Text('Servir'),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Bouton Annuler (pour toutes les commandes non servies/annulées)
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        String message = 'Annuler cette commande ?';
                        if (isPreparing || isReady) {
                          message = 'Cette demande d\'annulation sera transmise au manager pour approbation. Continuer ?';
                        }
                        
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirmation'),
                              content: Text(message),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Non'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.read<OrderBloc>().add(
                                      RequestCancelOrder(
                                        orderId: order.id,
                                        currentStatus: order.status,
                                      ),
                                    );
                                  },
                                  child: const Text('Oui'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                ],
                if (isServed || isCancelled)
                  const Expanded(
                    child: Text(
                      'Aucune action disponible',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
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
  
void _showOrderDetailsModal(BuildContext context, Order order) {
  // Calculer le total
  double total = 0;
  for (var item in order.items) {
    if (item is OrderItem) {
      total += item.price * item.quantity;
    }
  }
  
  // Déterminer l'état et les couleurs comme dans _buildOrderCard
  String statusText = 'Inconnu';
  Color statusColor = Colors.grey;
  
  if (order.status == 'new') {
    statusText = 'En attente';
    statusColor = Colors.orange;
  } else if (order.status == 'preparing') {
    statusText = 'En préparation';
    statusColor = Colors.blue;
  } else if (order.status == 'ready') {
    statusText = 'Prête';
    statusColor = Colors.green;
  } else if (order.status == 'served') {
    statusText = 'Servie';
    statusColor = Colors.purple;
  } else if (order.status == 'cancelled') {
    statusText = 'Annulée';
    statusColor = Colors.red;
  }
  
  // Vérifier les actions disponibles
  bool isReady = order.status == 'ready';
  bool isServed = order.status == 'served';
  bool isCancelled = order.status == 'cancelled';
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête avec seulement la table
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.accentColor,
                  radius: 20,
                  child: Icon(Icons.table_restaurant, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Table ${order.tableId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${order.customerCount} Éléments',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Date et heure
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mardi, ${DateFormat('dd MMMM yyyy').format(order.createdAt)}',
                  style: const TextStyle(color: Colors.black54),
                ),
                Text(
                  DateFormat('HH:mm').format(order.createdAt),
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // En-têtes de la liste
            const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Élements',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Qté',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Prix',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const Divider(),
            
            // Liste des articles
            Expanded(
              child: ListView.builder(
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  if (order.items[index] is OrderItem) {
                    OrderItem item = order.items[index] as OrderItem;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(item.name),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${item.quantity}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              item.price.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            
            const Divider(),
            
            // Total
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    total.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            
            // Afficher les boutons conditionnellement
            if (!isServed && !isCancelled) ...[
              // Bouton Annuler
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Afficher une confirmation pour annuler
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirmation'),
                        content: const Text('Voulez-vous annuler cette commande ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Non'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.read<OrderBloc>().add(
                                RequestCancelOrder(
                                  orderId: order.id,
                                  currentStatus: order.status,
                                ),
                              );
                            },
                            child: const Text('Oui'),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              // Bouton Servir (uniquement pour les commandes prêtes)
              if (isReady)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<OrderBloc>().add(
                      ConfirmOrderServed(orderId: order.id),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Servir',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
            ],
            if (isServed || isCancelled)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Aucune action disponible',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

  void _navigateToScreen(BuildContext context, int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        // Navigation vers l'écran d'accueil
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1:
        // Déjà sur l'écran des commandes
        break;
      case 2:
        // Navigation vers l'écran de table
        Navigator.of(context).pushReplacementNamed('/tables');
        break;
      case 3:
        // Navigation vers l'écran de profil
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }
}