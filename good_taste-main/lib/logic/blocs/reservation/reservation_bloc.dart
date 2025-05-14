import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // Add this import for debugPrint
import 'package:good_taste/data/models/reservation.dart';
import 'package:good_taste/data/repositories/reservation_repository.dart';
import 'package:good_taste/logic/blocs/auth/auth_bloc.dart';

part 'reservation_event.dart';
part 'reservation_state.dart';

class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  final ReservationRepository reservationRepository;
  final AuthBloc authBloc; // Ajouter le AuthBloc pour accéder à l'utilisateur courant

  ReservationBloc({
    required this.reservationRepository,
    required this.authBloc // Injecter le AuthBloc
  }) : super(
        ReservationInitial(
          date: DateTime.now(),
          timeSlot: '',
          numberOfPeople: 1,
          tableType: '',
          availableTimeSlots: [],
        ),
      ) {
    on<InitializeReservation>(_onInitializeReservation);
    on<DateChanged>(_onDateChanged);
    on<TimeSlotSelected>(_onTimeSlotSelected);
    on<NumberOfPeopleChanged>(_onNumberOfPeopleChanged);
    on<TableTypeSelected>(_onTableTypeSelected);
    on<SubmitReservation>(_onSubmitReservation);
    on<ShowCustomTimeSlotDialog>(_onShowCustomTimeSlotDialog);
    on<AddCustomTimeSlot>(_onAddCustomTimeSlot);
  }

  void _onShowCustomTimeSlotDialog(
    ShowCustomTimeSlotDialog event,
    Emitter<ReservationState> emit,
  ) {
    // Pas besoin de modifier l'état, l'événement sera traité dans la vue
    if (state is ReservationInitial) {
      final currentState = state as ReservationInitial;
      emit(currentState.copyWith(showingCustomDialog: true));
    }
  }

void _onAddCustomTimeSlot(
    AddCustomTimeSlot event,
    Emitter<ReservationState> emit,
  ) {
    if (state is ReservationInitial) {
      final currentState = state as ReservationInitial;

      // Debug de la liste d'horaires avant ajout
      debugPrint('Horaires disponibles avant ajout: ${currentState.availableTimeSlots}');
      
      // Ajouter le nouvel horaire s'il n'existe pas déjà
      if (!currentState.availableTimeSlots.contains(event.customTimeSlot)) {
        // Créer une nouvelle liste avec l'horaire ajouté
        final List<String> updatedTimeSlots = List<String>.from(currentState.availableTimeSlots);
        updatedTimeSlots.add(event.customTimeSlot);
        
        // Trier les horaires pour maintenir l'ordre chronologique
        updatedTimeSlots.sort((a, b) {
          // Extraire les heures de début pour le tri
          int startHourA = int.parse(a.split('h')[0]);
          int startHourB = int.parse(b.split('h')[0]);
          return startHourA.compareTo(startHourB);
        });
        
        debugPrint('Horaires disponibles après ajout: $updatedTimeSlots');
        debugPrint('Nouvel horaire sélectionné: ${event.customTimeSlot}');

        // Émettre un nouvel état avec la liste mise à jour et le nouvel horaire sélectionné
        emit(
          currentState.copyWith(
            availableTimeSlots: updatedTimeSlots,
            timeSlot: event.customTimeSlot, // Sélectionner automatiquement le nouvel horaire
            showingCustomDialog: false,
          ),
        );
      } else {
        // Si l'horaire existe déjà, juste le sélectionner
        debugPrint('Horaire déjà existant, sélection: ${event.customTimeSlot}');
        emit(
          currentState.copyWith(
            timeSlot: event.customTimeSlot,
            showingCustomDialog: false,
          ),
        );
      }
    }
  }

void _onInitializeReservation(
  InitializeReservation event,
  Emitter<ReservationState> emit,
) {
  final DateTime now = DateTime.now();
  final availableTimeSlots = reservationRepository.getAvailableTimeSlots(selectedDate: now);
  
 
  String initialTimeSlot = '';
  if (availableTimeSlots.isNotEmpty) {
    initialTimeSlot = availableTimeSlots.first;
  }
  
  emit(
    ReservationInitial(
      date: now,
      timeSlot: initialTimeSlot,
      numberOfPeople: 1,
      tableType: '',
      availableTimeSlots: availableTimeSlots,
    ),
  );
}

 void _onDateChanged(DateChanged event, Emitter<ReservationState> emit) {
  if (state is ReservationInitial) {
    final currentState = state as ReservationInitial;
    
    // Mettre à jour la liste des horaires disponibles en fonction de la nouvelle date
    final availableTimeSlots = reservationRepository.getAvailableTimeSlots(selectedDate: event.date);
    
    // Réinitialiser l'horaire sélectionné si nécessaire
    String timeSlot = currentState.timeSlot;
    
    // Si l'horaire actuel n'est pas disponible, en sélectionner un nouveau s'il y en a
    if (!availableTimeSlots.contains(timeSlot) && availableTimeSlots.isNotEmpty) {
      timeSlot = availableTimeSlots.first;
    } else if (availableTimeSlots.isEmpty) {
      timeSlot = '';
    }
    
    emit(currentState.copyWith(
      date: event.date,
      timeSlot: timeSlot,
      availableTimeSlots: availableTimeSlots
    ));
  }
}

  void _onTimeSlotSelected(
    TimeSlotSelected event,
    Emitter<ReservationState> emit,
  ) {
    if (state is ReservationInitial) {
      final currentState = state as ReservationInitial;
      emit(currentState.copyWith(timeSlot: event.timeSlot));
    }
  }

  void _onNumberOfPeopleChanged(
    NumberOfPeopleChanged event,
    Emitter<ReservationState> emit,
  ) {
    if (state is ReservationInitial) {
      final currentState = state as ReservationInitial;

      final numberOfPeople = event.numberOfPeople.clamp(1, 8);
      emit(currentState.copyWith(numberOfPeople: numberOfPeople));
    }
  }

  void _onTableTypeSelected(
    TableTypeSelected event,
    Emitter<ReservationState> emit,
  ) {
    if (state is ReservationInitial) {
      final currentState = state as ReservationInitial;
      emit(currentState.copyWith(tableType: event.tableType));
    }
  }

    void _onSubmitReservation(
    SubmitReservation event,
    Emitter<ReservationState> emit,
  ) async {
    if (state is ReservationInitial) {
      final currentState = state as ReservationInitial;

      // Vérifier si un horaire est sélectionné
      if (currentState.timeSlot.isEmpty) {
        emit(
          ReservationError(
            message: "Veuillez sélectionner un horaire",
            previousState: currentState,
          ),
        );
        return;
      }

      // Vérifier si une table est sélectionnée
      if (currentState.tableType.isEmpty) {
        emit(
          ReservationError(
            message: "Veuillez sélectionner une table",
            previousState: currentState,
          ),
        );
        return;
      }

      emit(ReservationLoading(previousState: currentState));

      try {
        // Récupérer l'utilisateur courant
        final currentUser = authBloc.state.user;
        
        // Vérifier si l'utilisateur a déjà une réservation active
        final hasActive = await reservationRepository.hasActiveReservation(currentUser.id);
        
        if (hasActive) {
          emit(
            ReservationError(
              message: "Vous avez déjà une réservation active. Annulez-la avant d'en faire une nouvelle.",
              previousState: currentState,
            ),
          );
          return;
        }

        final reservation = await reservationRepository.makeReservation(
          userId: currentUser.id,
          date: currentState.date,
          timeSlot: currentState.timeSlot,
          numberOfPeople: currentState.numberOfPeople,
          tableType: currentState.tableType,
        );

        emit(ReservationSuccess(reservation: reservation));
      } catch (e) {
        emit(
          ReservationError(
            message: "Une erreur s'est produite: ${e.toString()}",
            previousState: currentState,
          ),
        );
      }
    }
  }
}

