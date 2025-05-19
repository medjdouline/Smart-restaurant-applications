// lib/presentation/screens/reservation_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/data/repositories/reservation_history_repository.dart';
import 'package:good_taste/logic/blocs/auth/auth_bloc.dart';
import 'package:good_taste/logic/blocs/reservation_history/reservation_history_bloc.dart';
import 'package:good_taste/data/models/reservation.dart';
import 'package:intl/intl.dart';

class ReservationHistoryScreen extends StatelessWidget {
  const ReservationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReservationHistoryBloc(
        repository: ReservationHistoryRepository(),
        authBloc: context.read<AuthBloc>(),
      )..add(LoadReservationHistory()),
      child: const ReservationHistoryView(),
    );
  }
}

class ReservationHistoryView extends StatelessWidget {
  const ReservationHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationHistoryBloc>().add(const CheckLateReservations());
    });
    return Scaffold(
      backgroundColor: const Color(0xFFE9B975), 
      appBar: AppBar(
        title: Text('Historique des réservations', style: TextStyle(color: const Color(0xFFBA3400))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: const Color(0xFFBA3400)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<ReservationHistoryBloc, ReservationHistoryState>(
        builder: (context, state) {
          if (state is ReservationHistoryLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFBA3400),
              ),
            );
          } else if (state is ReservationHistoryLoaded) {
            return state.reservations.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune réservation trouvée',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.reservations.length,
                    itemBuilder: (context, index) {
                      final reservation = state.reservations[index];
                      return ReservationCard(reservation: reservation);
                    },
                  );
          } else if (state is ReservationHistoryError) {
            return Center(
              child: Text(
                'Erreur: ${state.message}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            );
          }
          return const Center(
            child: Text('Chargement des réservations...'),
          );
        },
      ),
    );
  }
}

class ReservationCard extends StatelessWidget {
  final Reservation reservation;

  const ReservationCard({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd/MM/yy');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          ListTile(
            leading: SizedBox(
              width: 40,
              height: 40,
              child: Image.asset(
                'assets/images/table_icon.png',
                color: const Color(0xFF245536),
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.table_restaurant,
                    color: Color(0xFF245536),
                    size: 30,
                  );
                },
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date: ${dateFormat.format(reservation.date)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Heure: ${reservation.timeSlot}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Personne: ${reservation.numberOfPeople}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Table: ${reservation.tableNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                if (value == 'view') {
                  _showDetailsDialog(context, reservation);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, reservation);
                } else if (value == 'cancel') {
                  _showCancelConfirmation(context, reservation);
                } 
              },
              itemBuilder: (context) {
                List<PopupMenuItem<String>> items = [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, color: Color(0xFF245536)),
                        SizedBox(width: 8),
                        Text('Voir les détails'),
                      ],
                    ),
                  ),
                ];
                
               
                if (reservation.status == ReservationStatus.confirmed || 
                    reservation.status == ReservationStatus.pending) {
                  items.add(
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Annuler la réservation'),
                        ],
                      ),
                    ),
                  );
                }
                
                items.add(
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer de l\'historique'),
                      ],
                    ),
                  ),
                );
                
                return items;
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(reservation.status),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Text(
              reservation.statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return const Color(0xFF245536); // Vert
      case ReservationStatus.pending:
        return const Color(0xFFDB9051); // Orange clair
      case ReservationStatus.canceled:
        return const Color(0xFFBA3400); // Rouge
      case ReservationStatus.completed:
        return Colors.grey; // Gris
        case ReservationStatus.late:
        return const Color(0xFFFFA500);
    }
  }

  void _showDetailsDialog(BuildContext context, Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Détails de la réservation'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date: ${DateFormat('dd/MM/yyyy').format(reservation.date)}'),
              const SizedBox(height: 8),
              Text('Heure: ${reservation.timeSlot}'),
              const SizedBox(height: 8),
              Text('Nombre de personnes: ${reservation.numberOfPeople}'),
              const SizedBox(height: 8),
              Text('Table: ${reservation.tableNumber}'),
              const SizedBox(height: 8),
              Text('Statut: ${reservation.statusText}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  void _showCancelConfirmation(BuildContext context, Reservation reservation) {
    // Capturer le BLoC avant d'ouvrir le dialogue
    final reservationHistoryBloc = context.read<ReservationHistoryBloc>();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmation d\'annulation'),
          content: const Text('Voulez-vous vraiment annuler cette réservation ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () {
                
                reservationHistoryBloc.add(CancelReservation(reservation.id));
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Oui, annuler',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Reservation reservation) {
   
    final reservationHistoryBloc = context.read<ReservationHistoryBloc>();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Voulez-vous vraiment supprimer cette réservation de l\'historique?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                
                reservationHistoryBloc.add(DeleteReservation(reservation.id));
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}