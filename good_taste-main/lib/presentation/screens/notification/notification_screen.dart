// lib/presentation/screens/notification/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/data/repositories/notification_repository.dart';
import 'package:good_taste/logic/blocs/notification/notification_bloc.dart';
import 'package:good_taste/presentation/screens/notification/notification_view.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationBloc(
        notificationRepository: NotificationRepository(),
      )..add(LoadNotifications()),
      child: const NotificationView(),
    );
  }
}