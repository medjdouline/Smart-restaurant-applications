part of 'reservation_bloc.dart';

abstract class ReservationEvent extends Equatable {
  const ReservationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeReservation extends ReservationEvent {}

class DateChanged extends ReservationEvent {
  final DateTime date;

  const DateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class TimeSlotSelected extends ReservationEvent {
  final String timeSlot;

  const TimeSlotSelected(this.timeSlot);

  @override
  List<Object?> get props => [timeSlot];
}

class NumberOfPeopleChanged extends ReservationEvent {
  final int numberOfPeople;

  const NumberOfPeopleChanged(this.numberOfPeople);

  @override
  List<Object?> get props => [numberOfPeople];
}

class TableTypeSelected extends ReservationEvent {
  final String tableType;

  const TableTypeSelected(this.tableType);

  @override
  List<Object?> get props => [tableType];
}

class SubmitReservation extends ReservationEvent {}

class ShowCustomTimeSlotDialog extends ReservationEvent {}

class AddCustomTimeSlot extends ReservationEvent {
  final String customTimeSlot;

  const AddCustomTimeSlot(this.customTimeSlot);

  @override
  List<Object?> get props => [customTimeSlot];
}