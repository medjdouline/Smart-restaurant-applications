// lib/screens/home/home_screen.dart
import 'package:app_serveur/blocs/auth/auth_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/orders/order_bloc.dart';
import '../../blocs/orders/order_event.dart';
import '../../blocs/orders/order_state.dart';
import '../../blocs/notifications/notification_bloc.dart';
import '../../blocs/notifications/notification_event.dart';
import '../../blocs/notifications/notification_state.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/home/home_event.dart';
import '../../blocs/home/home_state.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../utils/theme.dart';
import '../../widgets/section_header.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/assistance_request_card.dart';
import '../../data/models/order.dart';
import '../../data/repositories/assistance_repository.dart';
import '../notifications/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load data at startup
    context.read<OrderBloc>().add(LoadOrders());
    context.read<NotificationBloc>().add(LoadNotifications());
    context.read<HomeBloc>().add(LoadHomeDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        title: const Text('Accueil'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false, // Supprime la flèche retour
        actions: [
          // Icône de notification avec badge
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              final int unreadCount = state.notifications
                  .where((notification) => !notification.isRead)
                  .length;
              
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: AppTheme.accentColor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state.status == OrderStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Erreur inconnue'),
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<OrderBloc>().add(LoadOrders());
                context.read<HomeBloc>().add(LoadHomeDashboard());
              },
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildHeader(),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        _buildSummaryCards(),
                        const SizedBox(height: 24),
                        _buildOrdersSection(),
                        const SizedBox(height: 13),
                        BlocBuilder<HomeBloc, HomeState>(
                          builder: (context, state) {
                            return _buildAssistanceRequestsSection(context, state);
                          },
                        ),
                        const SizedBox(height: 13),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) => _navigateToScreen(context, index),
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (BuildContext context, AuthState state) {
        // Get username
        String username = "Utilisateur";
        if (state.status == AuthStatus.authenticated && state.user != null) {
          username = state.user!.firstName;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Salut!',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards() {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, orderState) {
        return BlocBuilder<HomeBloc, HomeState>(
          builder: (context, homeState) {
            return Row(
              children: [
                // Assistance Requests Summary
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EDD9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Demande d\'assistance',
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${homeState.assistanceRequests.length}',
                          style: const TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Ready Orders Summary
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Commandes prêtes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${orderState.readyOrders.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

 Widget _buildOrdersSection() {
  return BlocBuilder<OrderBloc, OrderState>(
    builder: (context, state) {
      if (state.status == OrderStatus.loading) {
        return const Center(child: CircularProgressIndicator());
      }

      final ordersToShow = [
        ...state.newOrders.where((order) => order.status == 'preparing'),
        ...state.readyOrders
      ];

      const maxOrdersToShow = 2;
      final showViewMore = ordersToShow.length > maxOrdersToShow;
      final displayedOrders = showViewMore && !state.currentFilter.contains('Tous')
          ? ordersToShow.take(maxOrdersToShow).toList()
          : ordersToShow;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Commandes prêtes',
            count: ordersToShow.length,
          ),
          ...displayedOrders.map((order) {
            String statusText = 'En attente';
            Color statusColor = Colors.orange;
            
            if (order.status == 'ready') {
              statusText = 'Prête';
              statusColor = Colors.green;
            } else if (order.status == 'preparing') {
              statusText = 'En préparation';
              statusColor = Colors.blue;
            }

            return GestureDetector(
              onTap: () => _showOrderDetailsModal(context, order),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppTheme.accentColor,
                              child: Icon(Icons.table_restaurant, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
  'Table ${order.getActualTableNumber()}',  // Use the method instead of tableId directly
  style: const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
),
                                 Text(
  'Table ${order.getActualTableNumber()}',  // Add "Table" prefix + method
  style: const TextStyle(color: Colors.black54),
),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (order.status != 'served' && order.status != 'cancelled')
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                String message = 'Annuler cette commande ?';
                                if (order.status == 'preparing' || order.status == 'ready') {
                                  message = 'Demande d\'annulation à envoyer au manager ?';
                                }
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirmation'),
                                    content: Text(message),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Non'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
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
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Annuler'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          if (showViewMore && !state.currentFilter.contains('Tous'))
            Center(
              child: TextButton(
                onPressed: () {
                  context.read<OrderBloc>().add(FilterOrders(filter: 'Tous'));
                },
                child: const Text(
                  'voir plus',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          if (state.currentFilter.contains('Tous') && ordersToShow.length > maxOrdersToShow)
            Center(
              child: TextButton(
                onPressed: () {
                  context.read<OrderBloc>().add(FilterOrders(filter: 'En attente'));
                },
                child: const Text(
                  'voir moins',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

 Widget _buildAssistanceRequestsSection(BuildContext context, HomeState state) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header section
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Demande d\'assistance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          if (state.assistanceRequestsCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${state.assistanceRequestsCount}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      // List of assistance requests
      AssistanceRequestsWidget(
        requests: state.getVisibleAssistanceRequests(),
        onComplete: (requestId) {
          // This properly triggers the event in the bloc
          context.read<HomeBloc>().add(CompleteAssistanceRequest(requestId: requestId));
        },
        showViewMore: state.shouldShowAssistanceRequestsViewMore(),
        onViewMorePressed: () {
          context.read<HomeBloc>().add(ToggleShowAllAssistanceRequests());
        },
      ),
    ],
  );
}

  void _showOrderDetailsModal(BuildContext context, Order order) {
    // Calculate total
    double total = 0;
    for (var item in order.items) {
      total += item.price * item.quantity;
    }

    // Determine status and colors
    String statusText = 'Inconnu';
    Color statusColor = Colors.grey;
    String tableNumber = order.getActualTableNumber();

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

    // Check available actions
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
              // Header with user and table info
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.accentColor,
                    radius: 20,
                    child: Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.userId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          order.tableId,
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

              // Date and time
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

              // List headers
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

              // Items list
              Expanded(
                child: ListView.builder(
                  itemCount: order.items.length,
                  itemBuilder: (context, index) {
                    OrderItem item = order.items[index];
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
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      total.toStringAsFixed(2),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),

              // Conditionally show buttons
              if (!isServed && !isCancelled) ...[
                // Cancel button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Show confirmation for cancel
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirmation'),
                          content: const Text(
                              'Voulez-vous annuler cette commande ?'),
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
                // Serve button (only for ready orders)
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
        // Already on home screen
        break;
      case 1:
        // Navigate to orders screen
        Navigator.of(context).pushReplacementNamed('/orders');
        break;
      case 2:
        // Navigate to tables screen
        Navigator.of(context).pushReplacementNamed('/tables');
        break;
      case 3:
        // Navigate to profile screen
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }
}