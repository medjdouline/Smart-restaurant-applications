// lib/screens/tables/tables_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/tables/tables_bloc.dart';
import '../../blocs/tables/tables_event.dart';
import '../../blocs/tables/tables_state.dart';
import '../../utils/theme.dart';
import '../../widgets/bottom_navigation.dart';
import '../../data/models/table.dart';
import '../../data/models/order.dart';
import '../../widgets/tables/table_list_item.dart';
import '../../widgets/tables/order_detail_modal.dart';


class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  int _currentIndex = 2; // La position dans la barre de navigation

  @override
  void initState() {
    super.initState();
    context.read<TablesBloc>().add(LoadTables());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<TablesBloc>().add(LoadTables());
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 25),
                    child: _buildTablesList(),
                  ),
                ),
              ],
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

  Widget _buildTablesList() {
    return BlocBuilder<TablesBloc, TablesState>(
      builder: (context, state) {
        if (state.status == TablesStatus.loading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 100),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state.status == TablesStatus.failure) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Erreur de chargement des tables',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TablesBloc>().add(LoadTables());
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.tables.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 100),
              child: Text(
                'Aucune table disponible',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.tables.length,
          itemBuilder: (context, index) {
            final table = state.tables[index];
            return TableListItem(
              table: table,
              onTap: () => _showTableDetailsModal(context, table),
            );
          },
        );
      },
    );
  }

Widget _buildReservationInfo(String title, String value, IconData icon, [Color? iconColor]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor ?? const Color(0xFFAA2C10), size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: value == 'Confirmée' ? Colors.green : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showTableDetailsModal(BuildContext context, RestaurantTable table) {
    // Load table orders if not already loaded
    context.read<TablesBloc>().add(LoadTableOrders(tableId: table.id));
    
    // Format de date et heure pour les réservations
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: table.isReserved ? 0.6 : 0.4,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withAlpha((0.3 * 255).toInt()),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            table.isReserved && !table.isOccupied ? Icons.event_available : Icons.restaurant,
                            size: 30,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                table.id,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                table.isOccupied 
                                    ? 'Occupée' 
                                    : (table.isReserved ? 'Réservée' : 'Libre'),
                                style: TextStyle(
                                  color: table.isOccupied 
                                      ? Colors.red 
                                      : (table.isReserved ? const Color(0xFFAA2C10) : Colors.green),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoItem('Capacité', '${table.capacity} places', Icons.chair),
                        ],
                      ),
                    ),
                    
                    // Afficher les détails de réservation si la table est réservée
                    if (table.isReserved) ...[
                      const SizedBox(height: 25),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFAA2C10).withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Détails de la réservation',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildReservationInfo(
                                    'Client', 
                                    table.clientName ?? 'Non spécifié', 
                                    Icons.person
                                  ),
                                ),
                                Expanded(
                                  child: _buildReservationInfo(
                                    'Personnes', 
                                    '${table.reservationPersonCount ?? 0}', 
                                    Icons.group
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildReservationInfo(
                                    'Début', 
                                    table.reservationStart != null 
                                        ? '${timeFormat.format(table.reservationStart!)}' 
                                        : 'Non spécifié', 
                                    Icons.access_time
                                  ),
                                ),
                                Expanded(
                                  child: _buildReservationInfo(
                                    'Fin', 
                                    table.reservationEnd != null 
                                        ? '${timeFormat.format(table.reservationEnd!)}' 
                                        : 'Non spécifié', 
                                    Icons.access_time_filled
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            _buildReservationInfo(
                              'Statut', 
                              table.reservationStatus ?? 'Non spécifié', 
                              Icons.info_outline,
                              table.reservationStatus == 'Confirmée' ? Colors.green : const Color(0xFFAA2C10) ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 25),
                    
                    // Afficher le bouton "Commencer la réservation" pour les tables réservées non occupées
                    if (table.isReserved && !table.isOccupied)
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                title: const Text('Confirmer la réservation'),
                                content: const Text('Les clients sont arrivés et souhaitent prendre leur table réservée ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      context.read<TablesBloc>().add(
                                        StartReservation(tableId: table.id),
                                      );
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Confirmer'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAA2C10),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          'Confirmer la réservation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    
                    // Bouton pour libérer/occuper la table (pour les tables non réservées ou déjà occupées)
                    if (!table.isReserved || table.isOccupied)
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                title: Text(table.isOccupied 
                                  ? 'Libérer la table' 
                                  : 'Occuper la table'),
                                content: Text(table.isOccupied 
                                  ? 'Voulez-vous marquer cette table comme libre ?' 
                                  : 'Voulez-vous marquer cette table comme occupée ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      context.read<TablesBloc>().add(
                                        ToggleTableStatus(tableId: table.id),
                                      );
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Confirmer'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: table.isOccupied ? Colors.red : AppTheme.secondaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          table.isOccupied ? 'Libérer la table' : 'Occuper la table',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderDetailModal(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.5,
          maxChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: OrderDetailModal(order: order),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentColor),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
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
        Navigator.of(context).pushReplacementNamed('/orders');
        break;
      case 2:
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }

}