import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importez tous vos écrans et services ici
import 'connexion/connexion.dart';
import 'home/home.dart';
import 'inscription/inscription.dart';
import 'info_perso/info_perso.dart';
import 'allergie/allergie.dart';
import 'regime.dart';
import 'preference/preference.dart';
import 'cree/cree.dart';
import 'menu/menu_acceuil.dart';
import 'menu/acceuil_invite.dart';
import 'menu/menu_favoris.dart';
import 'menu/menu_historique.dart';
import 'menu/menu_entree.dart';
import 'menu/menu_plats.dart';
import 'menu/menu_dessert.dart';
import 'menu/menu_boissons.dart';
import 'menu/menu_cart.dart';
import 'menu/menu_profil.dart';
import 'menu/menu_assistance.dart';
import 'favoris_service.dart';
import 'user_service.dart';
import 'cart_service.dart';
import 'order_history_service.dart';
import 'rating_service.dart';
import 'points_fidelite_widget.dart';
import '../services/menu_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAh_qXAMGvuayCYU0Dany2RIgC5Z4NQg1M",
      authDomain: "pferestau25.firebaseapp.com",
      projectId: "pferestau25",
      storageBucket: "pferestau25.firebasestorage.app",
      messagingSenderId: "180090883215",
      appId: "1:180090883215:web:bd3de81a39aed6f04e34fa",
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavorisService()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => OrderHistoryService()),
        ChangeNotifierProvider(create: (_) => RatingService()),
        ChangeNotifierProvider(create: (_) => MenuService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Good Taste Restaurant',
          theme: ThemeData(
            primarySwatch: Colors.brown,
            fontFamily: 'Roboto',
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.brown,
              accentColor: const Color(0xFF4CAF50),
            ),
          ),
          home: _getHomeScreen(userService),
          routes: _getAppRoutes(),
          onGenerateRoute: (settings) => _onGenerateRoute(settings, context),
        );
      },
    );
  }

  Widget _getHomeScreen(UserService userService) {
    if (userService.isLoggedIn) {
      return const MenuAcceuil();
    } else if (userService.isGuest) {
      return const AcceuilInvite();
    }
    return const RestaurantHomePage();
  }

  Map<String, WidgetBuilder> _getAppRoutes() {
    return {
      '/connexion': (context) => const LoginScreen(),
      '/inscription': (context) => const RegistrationScreen(),
      '/info_perso': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
        return InfoPersoPage(userInfo: args);
      },
      '/allergie': (context) => const AllergiesPage(),
      '/regime': (context) => const DietPage(),
      '/preference': (context) => const FoodPreferencesScreen(),
      '/cree': (context) => const ConfirmationPage(),
      '/menu': (context) => const MenuAcceuil(),
      '/invite': (context) => const AcceuilInvite(),
      '/favoris': (context) => const FavorisPage(),
      '/historique': (context) => const Historique(),
      '/entrees': (context) => const MenuEntreePage(),
      '/plats': (context) => const MenuPlatsPage(),
      '/desserts': (context) => const MenuDessertPage(),
      '/boissons': (context) => const MenuBoissonPage(),
      '/panier': (context) => const CartPage(),
      '/profil': (context) => const ProfileScreen(),
      '/assistance': (context) => const AssistancePage(),
    };
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings, BuildContext context) {
    switch (settings.name) {
      case '/acceuil_invite':
        return MaterialPageRoute(builder: (_) => const AcceuilInvite());
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('Page non trouvée'),
              backgroundColor: Colors.brown[700],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.brown,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Page non trouvée: ${settings.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[700],
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/'),
                    child: const Text(
                      'Retour à l\'accueil',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}