part of 'reservation_bloc.dart';

abstract class ReservationState extends Equatable {
  const ReservationState();
  
  @override
  List<Object> get props => [];
}

class ReservationInitial extends ReservationState {
  final DateTime date;
  final String timeSlot;
  final int numberOfPeople;
  final String tableType;
  final List<String> availableTimeSlots;
  final bool showingCustomDialog;

  const ReservationInitial({
    required this.date,
    required this.timeSlot,
    required this.numberOfPeople,
    required this.tableType,
    required this.availableTimeSlots,
    this.showingCustomDialog = false,
  });

  ReservationInitial copyWith({
    DateTime? date,
    String? timeSlot,
    int? numberOfPeople,
    String? tableType,
    List<String>? availableTimeSlots,
    bool? showingCustomDialog,
  }) {
    return ReservationInitial(
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      tableType: tableType ?? this.tableType,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      showingCustomDialog: showingCustomDialog ?? this.showingCustomDialog,
    );
  }

  @override
  List<Object> get props => [
    date, 
    timeSlot, 
    numberOfPeople, 
    tableType, 
    availableTimeSlots,
    showingCustomDialog,
  ];
}

class ReservationLoading extends ReservationState {
  final ReservationInitial previousState;

  const ReservationLoading({required this.previousState});

  @override
  List<Object> get props => [previousState];
}

class ReservationSuccess extends ReservationState {
  final Reservation? reservation;
  
  const ReservationSuccess({this.reservation});
  
  @override
  List<Object> get props => [reservation ?? ''];
}

class ReservationError extends ReservationState {
  final String message;
  final ReservationInitial previousState;

  const ReservationError({
    required this.message,
    required this.previousState,
  });

  @override
  List<Object> get props => [message, previousState];
}