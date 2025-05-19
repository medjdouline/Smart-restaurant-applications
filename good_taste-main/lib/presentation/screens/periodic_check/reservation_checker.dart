// lib/presentation/periodic_check/reservation_checker.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/reservation_history/reservation_history_bloc.dart';

class ReservationChecker {
  static Timer? _timer;
  
  /// Démarre une vérification périodique des réservations en retard
  /// Vérifie toutes les [intervalInMinutes] minutes
  static void startPeriodicCheck(BuildContext context, {int intervalInMinutes = 2}) {
    // Annuler tout timer existant
    stopPeriodicCheck();
    
    // Démarrer un nouveau timer
    _timer = Timer.periodic(
      Duration(minutes: intervalInMinutes),
      (_) => _checkLateReservations(context),
    );
    
    debugPrint('ReservationChecker: vérification périodique démarrée (intervalle: $intervalInMinutes min)');
  }
  
  /// Arrête la vérification périodique des réservations
  static void stopPeriodicCheck() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      _timer = null;
      debugPrint('ReservationChecker: vérification périodique arrêtée');
    }
  }
  
  /// Vérifie les réservations en retard et met à jour leur statut
  static void _checkLateReservations(BuildContext context) {
    try {
      // Vérifier si le bloc est disponible dans le contexte
      final reservationHistoryBloc = BlocProvider.of<ReservationHistoryBloc>(context);
      
      // Déclencher l'événement de vérification des réservations en retard
      reservationHistoryBloc.add(const CheckLateReservations());
      
      debugPrint('ReservationChecker: vérification des réservations en retard effectuée');
    } catch (e) {
      debugPrint('ReservationChecker: erreur lors de la vérification des réservations en retard: $e');
    }
  }
}