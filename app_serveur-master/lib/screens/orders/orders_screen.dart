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
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
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
    bool isWaiting = order.status.toLowerCase() == 'new' || 
                     order.status.toLowerCase() == 'pending';
    bool isPreparing = order.status.toLowerCase() == 'preparing';
    bool isReady = order.status.toLowerCase() == 'ready';
    bool isServed = order.status.toLowerCase() == 'served';
    bool isCancelled = order.status.toLowerCase() == 'cancelled';

    String statusText = '';
    Color statusColor = Colors.grey;

    switch (order.status.toLowerCase()) {
      case 'pending':
      case 'new':
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
        statusText = order.status;
    }

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
                        'Table ${order.getActualTableNumber()}',
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
              Row(
                children: [
                  if (!isServed && !isCancelled) ...[
                    if (isReady)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
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
  // Charge d'abord les détails
  context.read<OrderBloc>().add(LoadOrderDetails(orderId: order.id));
  
    
    showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state.status == OrderStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state.status == OrderStatus.error) {
            return Center(child: Text(state.errorMessage ?? 'Error loading details'));
          }
          
          final detailedOrder = state.currentOrderDetails ?? order;
          return _OrderDetailsContent(order: detailedOrder);
        },
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
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1:
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/tables');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }
}

class _OrderDetailsContent extends StatelessWidget {
  final Order order;

  const _OrderDetailsContent({required this.order});

  @override
  Widget build(BuildContext context) {
    final totalPrice = order.items.fold(
      0.0, 
      (sum, item) => sum + (item.price * (item.quantity ?? 1))
    );

    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                          'Table ${order.getActualTableNumber()}',
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
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, dd MMMM yyyy', 'fr_FR').format(order.createdAt),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  DateFormat('HH:mm').format(order.createdAt),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Éléments',
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
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(item is OrderItem ? item.name : item['name'] ?? ''),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${item is OrderItem ? item.quantity : item['quantity'] ?? 1}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${(item is OrderItem ? item.price : item['price'] ?? 0).toStringAsFixed(2)} €',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${totalPrice.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            if (order.notes != null && order.notes!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Notes:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  Text(order.notes!),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'new':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'served':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'new':
        return 'En attente';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prête';
      case 'served':
        return 'Servie';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }
}