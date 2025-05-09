import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/auth/auth_status.dart';

class AppBlocListener extends StatelessWidget {
  final Widget child;

  const AppBlocListener({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // Add a safer check for the navigator context
            if (!context.mounted) {
              return; // Skip if context is no longer valid
            }
            
            // Safer check for modal route
            final route = ModalRoute.of(context);
            if (Navigator.canPop(context) == false && route != null && !route.isFirst) {
              return; // Skip navigation if no navigator is available
            }
            
            if (state.status == AuthStatus.unauthenticated) {
              // Use WidgetsBinding to ensure we're not during a build phase
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              });
            } else if (state.status == AuthStatus.authenticated) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home',
                    (route) => false,
                  );
                }
              });
            }
          },
        ),
      ],
      child: child,
    );
  }
}