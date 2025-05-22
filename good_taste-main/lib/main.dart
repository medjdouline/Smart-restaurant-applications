// lib/main.dart (with added logging configuration)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/repositories/allergies_repository.dart';
import 'package:good_taste/data/repositories/regime_repository.dart';
import 'package:good_taste/data/repositories/preferences_repository.dart'; 
import 'package:good_taste/logic/blocs/auth/auth_bloc.dart';
import 'package:good_taste/logic/blocs/favorites/favorites_bloc.dart';
import 'package:good_taste/logic/blocs/home/home_bloc.dart';
import 'package:good_taste/presentation/screens/login_screen.dart';
import 'package:good_taste/presentation/screens/register_screen.dart';
import 'package:good_taste/presentation/screens/personal_info.dart';
import 'package:good_taste/presentation/screens/allergies_screen.dart';
import 'package:good_taste/presentation/screens/regime_screen.dart';
import 'package:good_taste/presentation/screens/preference_screen.dart';
import 'package:good_taste/presentation/screens/felicitation_screen.dart';
import 'package:good_taste/presentation/screens/main_navigation_screen.dart';
import 'package:good_taste/presentation/screens/reservation/table_screen.dart';
import 'package:good_taste/presentation/screens/profile/preference_detail_screen.dart';
import 'package:good_taste/presentation/screens/reservation/reservation_history_screen.dart';
import 'package:good_taste/presentation/screens/order/order_history_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:good_taste/logic/blocs/user/user_bloc.dart';
import 'package:good_taste/logic/blocs/allergies/allergies_bloc.dart';
import 'package:good_taste/logic/blocs/regime/regime_bloc.dart';
import 'package:good_taste/logic/blocs/profile/profile_bloc.dart';
import 'package:good_taste/logic/blocs/menu/menu_bloc.dart';
import 'package:good_taste/data/repositories/dish_repository.dart';
import 'package:good_taste/presentation/screens/favorites/favorites_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:good_taste/di/di.dart'; // Import the dependency injection
import 'package:logging/logging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure logging
  Logger.root.level = Level.ALL; // Set to show all log levels
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('Stack trace: ${record.stackTrace}');
    }
  });
  
  // Log startup info and connection URL
  final logger = Logger('main');
  logger.info('Starting app...');
  logger.info('API base URL: ${DependencyInjection.apiBaseUrl}');
  await DependencyInjection.init();
  await Firebase.initializeApp();
  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // Use the dependency injection to provide the AuthRepository
        RepositoryProvider<AuthRepository>(
          create: (context) => DependencyInjection.getAuthRepository(),
        ),
        RepositoryProvider(create: (context) => AllergiesRepository()),
        RepositoryProvider(create: (context) => RegimeRepository()), 
        RepositoryProvider(create: (context) => PreferencesRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: RepositoryProvider.of<AuthRepository>(context),
            ),
          ),
          BlocProvider(
            create: (context) => UserBloc(
              authRepository: RepositoryProvider.of<AuthRepository>(context),
              allergiesRepository: RepositoryProvider.of<AllergiesRepository>(context),
              regimeRepository: RepositoryProvider.of<RegimeRepository>(context),
            ),
          ),
          BlocProvider(
            create: (context) => AllergiesBloc(
              allergiesRepository: RepositoryProvider.of<AllergiesRepository>(context),
              authRepository: RepositoryProvider.of<AuthRepository>(context),
            ),
          ),
          BlocProvider(
            create: (context) => ProfileBloc(
              authRepository: RepositoryProvider.of<AuthRepository>(context),
            ),
          ),
          BlocProvider(
            create: (context) => RegimeBloc(
              regimeRepository: RepositoryProvider.of<RegimeRepository>(context),
              authRepository: RepositoryProvider.of<AuthRepository>(context),
            ),
          ),
          BlocProvider(
            create: (context) => MenuBloc(
              dishRepository: DishRepository(),
            )
          ),
          BlocProvider(
            create: (context) => HomeBloc(
              dishRepository: DishRepository(),
            )..add(LoadRecommendations()),
          ),
          BlocProvider(
            create: (context) => FavoritesBloc(
              dishRepository: DishRepository(),
              userId: context.read<AuthBloc>().state.user.id,
            )..add(LoadFavorites()),
          ),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        } else if (state.status == AuthStatus.authenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
        }
      },
      child: MaterialApp(
        title: 'Good Taste',
        theme: ThemeData(
          primaryColor: const Color(0xFF245536), 
          scaffoldBackgroundColor: const Color(0xFFE9B975), 
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF245536), 
            primary: const Color(0xFF245536),
            secondary: const Color(0xFFBA3400),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color.fromARGB(0, 219, 143, 81),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF245536),
              foregroundColor: Colors.white, 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30), 
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        routes: {
          '/': (context) => BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state.status == AuthStatus.authenticated) {
                    return const MainNavigationScreen(); 
                  }
                  return const LoginScreen();
                },
              ),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/personal_info': (context) => const PersonalInfoScreen(),
          '/allergies': (context) => const AllergiesScreen(),
          '/regime': (context) => const RegimeScreen(),
          '/preference': (context) => const PreferenceScreen(),
          '/felicitation': (context) => const FelicitationScreen(),
          '/main': (context) => const MainNavigationScreen(),
          '/table': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return TableScreen(
              reservationDate: args['reservationDate'] as DateTime,
              reservationTimeSlot: args['reservationTimeSlot'] as String,
              numberOfPeople: args['numberOfPeople'] as int,
            );
          },
          '/preferences': (context) => const PreferenceDetailScreen(),
          '/reservation_history': (context) => const ReservationHistoryScreen(),
          '/order_history': (context) => const OrderHistoryScreen(),
          '/favorites': (context) => const FavoritesScreen(),
        },
        initialRoute: '/',
      ),
    );
  }
}