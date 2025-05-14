// lib/screens/orders/orders_screen.dart (with fixes)
// ignore_for_file: unnecessary_type_check, unnecessary_cast

import 'package:app_serveur/data/repositories/order_repository_impl.dart';
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
      body: // In the build method of OrdersScreen, replace the BlocConsumer with this:
BlocConsumer<OrderBloc, OrderState>(
  listener: (context, state) {
    if (state.status == OrderStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Une erreur est survenue'),
          backgroundColor: Colors.red,
        ),
      );
    }
    if (state.status == OrderStatus.cancelRequested && state.infoMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.infoMessage!),
          backgroundColor: Colors.green,
        ),
      );
      // Rechargement différé après 2 secondes
      Future.delayed(const Duration(seconds: 2), () {
        context.read<OrderBloc>().add(LoadOrders());
      });
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
              _buildFilters(state),
              const SizedBox(height: 20),
              Expanded(
                child: state.status == OrderStatus.loading
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
  bool isWaiting = order.status.toLowerCase() == 'new' || 
                   order.status.toLowerCase() == 'pending' || 
                   order.status.toLowerCase() == 'en attente' || 
                   order.status.toLowerCase() == 'en_attente';
  bool isPreparing = order.status.toLowerCase() == 'preparing' || 
                    order.status.toLowerCase() == 'en preparation' || 
                    order.status.toLowerCase() == 'en_preparation';
  bool isReady = order.status.toLowerCase() == 'ready' || 
                order.status.toLowerCase() == 'pret' || 
                order.status.toLowerCase() == 'prete';
  bool isServed = order.status.toLowerCase() == 'served' || 
                 order.status.toLowerCase() == 'servi' || 
                 order.status.toLowerCase() == 'servie';
  bool isCancelled = order.status.toLowerCase() == 'cancelled' || 
                    order.status.toLowerCase() == 'annule' || 
                    order.status.toLowerCase() == 'annulee';

  // Utiliser la méthode modifiée pour obtenir le numéro de table correct
  String tableNumber = order.getActualTableNumber();

  // Texte du statut à afficher
  String statusText = '';
  Color statusColor = Colors.grey;

  switch (order.status.toLowerCase()) {
    case 'pending':
    case 'new':
    case 'en_attente':
    case 'en attente':
      statusText = 'En attente';
      statusColor = Colors.orange;
      break;
    case 'preparing':
    case 'en preparation':
    case 'en_preparation':
      statusText = 'En préparation';
      statusColor = Colors.blue;
      break;
    case 'ready':
    case 'pret':
    case 'prete':
      statusText = 'Prête';
      statusColor = Colors.green;
      break;
    case 'served':
    case 'servi':
    case 'servie':
      statusText = 'Servie';
      statusColor = Colors.purple;
      break;
    case 'cancelled':
    case 'annule':
    case 'annulee':
      statusText = 'Annulée';
      statusColor = Colors.red;
      break;
    default:
      statusText = order.status;
  }
  
  // Le reste de la méthode reste inchangé...
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
                      'Table $tableNumber',
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
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    try {
                                      context.read<OrderBloc>().add(
                                        RequestCancelOrder(
                                          orderId: order.id,
                                          currentStatus: order.status,
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Erreur: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
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
  // Utiliser la méthode getActualTableNumber du modèle Order
  String tableNumber = order.getActualTableNumber();
  
  // Calculer le total
  double total = 0;
  for (var item in order.items) {
    if (item is OrderItem) {
      total += item.price * item.quantity;
    }
  }
  
  // Déterminer l'état et les couleurs
  String statusText = 'Inconnu';
  Color statusColor = Colors.grey;
  
  switch (order.status.toLowerCase()) {
    case 'pending':
    case 'new':
    case 'en_attente':
    case 'en attente':
      statusText = 'En attente';
      statusColor = Colors.orange;
      break;
    case 'preparing':
    case 'en preparation':
    case 'en_preparation':
      statusText = 'En préparation';
      statusColor = Colors.blue;
      break;
    case 'ready':
    case 'pret':
    case 'prete':
      statusText = 'Prête';
      statusColor = Colors.green;
      break;
    case 'served':
    case 'servi':
    case 'servie':
      statusText = 'Servie';
      statusColor = Colors.purple;
      break;
    case 'cancelled':
    case 'annule':
    case 'annulee':
      statusText = 'Annulée';
      statusColor = Colors.red;
      break;
    default:
      statusText = order.status;
  }
  
  // Vérifier les actions disponibles
  bool isReady = order.status.toLowerCase() == 'ready' || 
                order.status.toLowerCase() == 'pret' || 
                order.status.toLowerCase() == 'prete';
  bool isServed = order.status.toLowerCase() == 'served' || 
                 order.status.toLowerCase() == 'servi' || 
                 order.status.toLowerCase() == 'servie';
  bool isCancelled = order.status.toLowerCase() == 'cancelled' || 
                    order.status.toLowerCase() == 'annule' || 
                    order.status.toLowerCase() == 'annulee';
  
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
                        'Table $tableNumber',
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
            
            // Reste du code inchangé pour ne pas causer d'erreurs
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
            
            // Le reste du code reste le même...
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
            
            // Liste des articles - le reste du code inchangé
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