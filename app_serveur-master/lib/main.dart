import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'blocs/auth/auth_bloc.dart';
import 'package:app_serveur/data/repositories/tables_repository.dart';
import 'blocs/orders/order_bloc.dart';
import 'blocs/tables/tables_bloc.dart';
import 'blocs/notifications/notification_bloc.dart';
import 'blocs/profile/profile_bloc.dart';
import 'blocs/home/home_bloc.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/assistance_repository.dart';
import 'data/repositories/home_repository.dart';
import 'core/api/api_service.dart';
import 'core/routes.dart';
import 'core/api/api_client.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'core/services/firebase_auth_service.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'utils/theme.dart';
import 'utils/bloc_listener.dart';
import 'core/dependency_injection.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/tables/tables_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  
  // Initialize API Service with base URL from .env
  ApiService.initialize(baseUrl: dotenv.env['API_BASE_URL']);
  
  setupDependencies();
  
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000/api/',
    );
    final firebaseAuthService = FirebaseAuthService();
    
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepositoryImpl>(
          create: (context) => AuthRepositoryImpl(
            apiClient: apiClient,
            firebaseAuthService: firebaseAuthService,
          ),
        ),
        RepositoryProvider<OrderRepository>(
          create: (context) => OrderRepository(),
        ),
        // Add the AssistanceRepository provider before HomeRepository
        RepositoryProvider<AssistanceRepository>(
          create: (context) => AssistanceRepository(),
        ),
        RepositoryProvider<HomeRepository>(
          create: (context) => HomeRepository(
            orderRepository: context.read<OrderRepository>(),
            assistanceRepository: context.read<AssistanceRepository>(),
          ),
        ),
        RepositoryProvider<NotificationRepository>(
          create: (context) => NotificationRepository(),
        ),
        RepositoryProvider<ProfileRepository>( 
          create: (context) => ProfileRepository(
            apiClient: apiClient,
            firebaseAuthService: firebaseAuthService,
          ),
        ),
        RepositoryProvider<TablesRepository>(
          create: (context) => TablesRepository(),
        ),
        ...getGlobalRepositoryProviders(), // From dependency injection
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepositoryImpl>(),
            ),
          ),
          BlocProvider<OrderBloc>(
            create: (context) => OrderBloc(
              orderRepository: context.read<OrderRepository>(),
            ),
          ),
          BlocProvider<NotificationBloc>(
            create: (context) => NotificationBloc(
              notificationRepository: context.read<NotificationRepository>(),
            ),
          ),
          BlocProvider<HomeBloc>(
            create: (context) => HomeBloc(
              homeRepository: context.read<HomeRepository>(),
            ),
          ),
          BlocProvider<ProfileBloc>( 
            create: (context) => ProfileBloc(
              profileRepository: context.read<ProfileRepository>(),
            ),
          ),
          BlocProvider<TablesBloc>(
          create: (context) => TablesBloc(
            tablesRepository: context.read<TablesRepository>(),
          ),
        ),
          ...getGlobalBlocProviders(), // From dependency injection
        ],
        child: AppBlocListener(
          child: MaterialApp(
            title: 'Good serve!',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme.copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppTheme.primaryColor,
                secondary: AppTheme.secondaryColor,
              ),
              appBarTheme: const AppBarTheme(
                color: AppTheme.primaryColor,
                elevation: 0,
              ),
              scaffoldBackgroundColor: Colors.white,
              textTheme: Theme.of(context).textTheme.apply(
                fontFamily: 'Poppins',
              ),
            ),
            onGenerateRoute: AppRouter().onGenerateRoute,
            initialRoute: '/login',
            routes: {
              '/home': (context) => const HomeScreen(),
              '/orders': (context) => const OrdersScreen(),
              '/tables': (context) => const TablesScreen(),
              '/profile': (context) => const ProfileScreen(),
            },
          ),
        ),
      ),
    );
  }
}