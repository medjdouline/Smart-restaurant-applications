import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/data/repositories/reservation_repository.dart';
import 'package:good_taste/logic/blocs/auth/auth_bloc.dart';
import 'package:good_taste/logic/blocs/reservation/reservation_bloc.dart';
import 'package:good_taste/presentation/screens/reservation/reservation_view.dart';

class ReservationScreen extends StatelessWidget {
  const ReservationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReservationBloc(
        reservationRepository: ReservationRepository(),
        authBloc: BlocProvider.of<AuthBloc>(context), // Injecter l'AuthBloc
      )..add(InitializeReservation()),
      child: const ReservationView(),
    );
  }
}