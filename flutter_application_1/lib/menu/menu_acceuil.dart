import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'menu_profil.dart';
import 'menu_choix.dart';
import 'menu_favoris.dart';
import 'menu_historique.dart';
import '../favoris_service.dart';
import '../user_service.dart';
import '../cart_service.dart';
import '../rating_service.dart';
import 'menu_cart.dart';
import '../services/menu_service.dart';
import '../models/item.dart';
import '../points_fidelite_widget.dart';

import '../order_history_service.dart';
import './notifications.dart';
import '../user_service.dart';
import './assistance_button.dart';

class MenuAcceuil extends StatefulWidget {
  const MenuAcceuil({Key? key}) : super(key: key);
  

  @override
  State<MenuAcceuil> createState() => _MenuAcceuilState();
}

class _MenuAcceuilState extends State<MenuAcceuil> {
  int _selectedNavIndex = 0;
  final ScrollController _scrollController = ScrollController();
  Item? _selectedPlat;
  double _currentRating = 0;
  List<String> _recommendedDishIds = [];
  bool _isLoadingRecommendations = false;
  List<String> notifications = [];
  List<NotificationModel> detailedNotifications = []; // New list for detailed notifications
  bool isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadMenuData();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
  final userService = Provider.of<UserService>(context, listen: false);
  
  // Don't load recommendations for guest users
  if (userService.isGuest || !userService.isLoggedIn) {
    debugPrint('Guest user or not logged in - skipping recommendations');
    return;
  }

  try {
    setState(() {
      _isLoadingRecommendations = true;
    });

    debugPrint('Loading recommendations...');
    _recommendedDishIds = await userService.getRecommendations();
    
    setState(() {
      _isLoadingRecommendations = false;
    });

    debugPrint('Recommendations loaded: ${_recommendedDishIds.length} items');
  } catch (e) {
    debugPrint('Error loading recommendations: $e');
    setState(() {
      _isLoadingRecommendations = false;
      _recommendedDishIds = [];
    });
  }
}

  Future<void> _loadUserFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final favorisService = Provider.of<FavorisService>(context, listen: false);
      await favorisService.chargerFavorisAPI();
    }
  }

  Future<void> _loadMenuData() async {
    final menuService = Provider.of<MenuService>(context, listen: false);
    await menuService.loadMenuData();
  }

Future<void> _loadNotifications() async {
    final userService = Provider.of<UserService>(context, listen: false);
    
    // Don't load notifications for guest users
    if (userService.isGuest || !userService.isLoggedIn) {
      debugPrint('Guest user or not logged in - skipping notifications');
      return;
    }

    try {
      setState(() {
        isLoadingNotifications = true;
      });

      debugPrint('Loading notifications...');
      final loadedNotifications = await userService.loadNotifications();
      
      setState(() {
        detailedNotifications = loadedNotifications;
        // Convert to simple string list for backward compatibility
        notifications = loadedNotifications
            .take(5) // Limit to 5 like before
            .map((n) => n.message)
            .toList();
        isLoadingNotifications = false;
      });

      debugPrint('Notifications loaded successfully: ${notifications.length}');
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      setState(() {
        isLoadingNotifications = false;
        notifications = ['Erreur de chargement des notifications'];
      });
    }
  }
   Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }
   Future<void> _markNotificationAsRead(NotificationModel notification) async {
    final userService = Provider.of<UserService>(context, listen: false);
    
    if (!notification.read) {
      await userService.markNotificationAsRead(notification.id);
      // Refresh the list to show updated read status
      await _loadNotifications();
    }
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showPlatDetails(Item plat) {
    setState(() {
      _selectedPlat = plat;
      _currentRating = 0;
    });
  }

  void _closeDetails() {
    setState(() => _selectedPlat = null);
  }

  bool _isFavorite(FavorisService favorisService, String id) {
    return favorisService.estFavori(id);
  }

void _toggleFavorite(FavorisService favorisService, Item plat) async {
  try {
    await favorisService.toggleFavoriAPI(plat.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(favorisService.estFavori(plat.id) 
          ? 'Added to favorites' 
          : 'Removed from favorites'),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _showNotifications() {
  // Navigation vers la nouvelle page de notifications au lieu d'une dialog
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const NotificationsPage(),
    ),
  );
}

  Future<void> _showAssistanceDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demander un serveur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search, size: 50, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Un serveur va venir à votre table dans quelques instants.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Confirmer',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await FirebaseFirestore.instance.collection('assistance_requests').add({
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre demande a été envoyée avec succès!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

Widget _buildNavButton(int index, IconData icon, String label) {
  bool isSelected = _selectedNavIndex == index;
  return InkWell(
    onTap: () {
      setState(() => _selectedNavIndex = index);
      
      // Specifically handle history tab click
      if (index == 2) { // Assuming 2 is your history tab index
        final orderHistory = Provider.of<OrderHistoryService>(context, listen: false);
        final userService = Provider.of<UserService>(context, listen: false);
        
        if (userService.isLoggedIn && !userService.isGuest) {
          orderHistory.loadOrderHistory();
        }
      }
    },
    child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDFB976) : null,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            bottomLeft: Radius.circular(10),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFB24516) : const Color(0xFFDFB976),
              size: 24,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFB24516) : const Color(0xFFDFB976),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatCard(Item plat, FavorisService favorisService) {
    final isFavori = favorisService.estFavori(plat.id);
    
    return GestureDetector(
      onTap: () => _showPlatDetails(plat),
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                color: Colors.grey.shade300,
                child: plat.image != null
                    ? Image.network(
                        plat.image,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.fastfood,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.fastfood,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
              ),
            ),
            
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          plat.sousCategorie,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _toggleFavorite(favorisService, plat),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              isFavori ? Icons.favorite : Icons.favorite_border,
                              color: isFavori ? Colors.red : Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    plat.nom,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plat.prix} DA',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 4),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatDetailCard(FavorisService favorisService, CartService cartService, RatingService ratingService) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFDFB976),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          child: _selectedPlat!.image != null
                              ? Image.network(
                                  _selectedPlat!.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.fastfood,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.fastfood,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isFavorite(favorisService, _selectedPlat!.id) 
                                  ? Icons.favorite 
                                  : Icons.favorite_border,
                                color: _isFavorite(favorisService, _selectedPlat!.id) 
                                  ? Colors.red 
                                  : Colors.white,
                              ),
                              onPressed: () => _toggleFavorite(favorisService, _selectedPlat!),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: _closeDetails,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _selectedPlat!.nom,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB24516),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_selectedPlat!.prix} DA',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A5311),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const SizedBox(height: 10),
                  StreamBuilder<DocumentSnapshot>(
                    stream: ratingService.getRatingStream(_selectedPlat!.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      
                      final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      final avgRating = data['averageRating'] ?? 0.0;
                      final ratingCount = data['ratingCount'] ?? 0;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 24),
                          const SizedBox(width: 5),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[800],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '($ratingCount avis)',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.brown[600],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _selectedPlat!.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'INGRÉDIENTS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _selectedPlat!.ingredients,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'NOTER CE PRODUIT',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _currentRating.round() ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 30,
                        ),
                        onPressed: () {
                          setState(() {
                            _currentRating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      if (_currentRating > 0) {
                        ratingService.addRating(
                          _selectedPlat!.id, 
                          _currentRating,
                          FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Merci pour votre note de $_currentRating étoiles!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        setState(() {
                          _currentRating = 0;
                        });
                      }
                    },
                    child: const Text(
                      'SOUMETTRE LA NOTE',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A5311),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      cartService.addItem(
                        id: _selectedPlat!.id,
                        nom: _selectedPlat!.nom,
                        prix: _selectedPlat!.prix.toDouble(),
                        imageUrl: _selectedPlat!.image,
                      );
                      

                      _closeDetails();
                    },
                    child: const Text(
                      'COMMANDER',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartButton(int itemCount) {
    final cartService = Provider.of<CartService>(context, listen: true);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => const CartPage(),
          ),
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFB24516),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.shopping_cart,
              color: Colors.white,
              size: 30,
            ),
            if (itemCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }

Widget _buildServeurButton() {
  return QuickAssistanceButton(
    tableId: Provider.of<UserService>(context, listen: false).tableId,
  );
}

Widget _buildContent(MenuService menuService, FavorisService favorisService) {
  if (menuService.isLoading) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.brown),
          SizedBox(height: 16),
          Text('Chargement des plats...', style: TextStyle(color: Colors.brown, fontSize: 16)),
        ],
      ),
    );
  }

  // Only use API recommendations (which include fallbacks)
  List<Item> platsAccueil = [];
  
  if (_recommendedDishIds.isNotEmpty) {
    platsAccueil = _recommendedDishIds
        .map((id) => menuService.findItemById(id))
        .where((item) => item != null)
        .cast<Item>()
        .toList();
  }

  if (platsAccueil.isEmpty && !_isLoadingRecommendations) {
    return const Center(
      child: Text('Aucun plat disponible', style: TextStyle(color: Colors.brown, fontSize: 18)),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_isLoadingRecommendations)
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: CircularProgressIndicator(color: Colors.brown),
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nos recommandations',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFB24516),
                ),
              ),
              Text(
                '${platsAccueil.length} plats disponibles',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFFB24516).withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        
      if (!_isLoadingRecommendations && platsAccueil.isNotEmpty)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFB24516),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 40, top: 10, bottom: 10),
                  child: ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: platsAccueil.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showPlatDetails(platsAccueil[index]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: _buildPlatCard(platsAccueil[index], favorisService),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 5,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        color: Colors.white,
                        onPressed: () {
                          if (_scrollController.hasClients) {
                            final currentPos = _scrollController.offset;
                            final scrollAmount = currentPos - 200.0;
                            _scrollController.animateTo(
                              scrollAmount < 0 ? 0 : scrollAmount,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 5,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        color: Colors.white,
                        onPressed: () {
                          if (_scrollController.hasClients) {
                            final currentPos = _scrollController.offset;
                            final maxExtent = _scrollController.position.maxScrollExtent;
                            final scrollAmount = currentPos + 200.0;
                            _scrollController.animateTo(
                              scrollAmount > maxExtent ? maxExtent : scrollAmount,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
      if (!_isLoadingRecommendations)
        Padding(
          padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
          child: Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MenuChoixPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A5311),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Afficher Menu Complet',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ),
    ],
  );
}
  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final favorisService = Provider.of<FavorisService>(context);
    final cartService = Provider.of<CartService>(context);
    final ratingService = Provider.of<RatingService>(context, listen: false);
    final menuService = Provider.of<MenuService>(context);
    

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                color: const Color(0xFFB24516),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.restaurant,
                            color: const Color(0xFFDFB976),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Feuille de l\'aures',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFDFB976),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildNavButton(0, Icons.home, 'Accueil'),
                    const SizedBox(height: 30),
                    _buildNavButton(1, Icons.favorite, 'Favoris'),
                    const SizedBox(height: 30),
                    _buildNavButton(2, Icons.history, 'Historique'),
                    const SizedBox(height: 30),
                    _buildNavButton(3, Icons.person, 'Profil'),
                  ],
                ),
              ),

              Expanded(
                child: IndexedStack(
                  index: _selectedNavIndex,
                  children: [
                    Container(
                      color: const Color(0xFFDFB976),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
                            child: Center(
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.7,
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB24516),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white,
                                      backgroundImage: userService.photoUrl != null 
                                          ? NetworkImage(userService.photoUrl!) 
                                          : null,
                                      child: userService.photoUrl == null 
                                          ? Icon(Icons.person, color: Colors.grey[400], size: 20) 
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Salut!',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            userService.nomUtilisateur ?? 'utilisateur',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PointsFideliteWidget(),
                                    IconButton(
                                      icon: Stack(
                                        children: [
                                          const Icon(
                                            Icons.notifications_none,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          if (notifications.isNotEmpty)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 12,
                                                  minHeight: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      onPressed: _showNotifications,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildContent(menuService, favorisService),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    ChangeNotifierProvider.value(
                      value: favorisService,
                      child: const FavorisPage(),
                    ),
                    const Historique(),
                    const ProfileScreen(),
                  ],
                ),
              ),
            ],
          ),
          
          if (_selectedPlat != null)
            _buildPlatDetailCard(favorisService, cartService, ratingService),
            
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildCartButton(cartService.items.length),
          ),
          
          Positioned(
            bottom: 90,
            right: 20,
            child: _buildServeurButton(),
          ),
        ],
      ),
    );
  }
   Widget _buildNotificationsSection(UserService userService) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (userService.unreadNotificationsCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${userService.unreadNotificationsCount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            
            if (isLoadingNotifications)
              Center(child: CircularProgressIndicator())
            else if (detailedNotifications.isEmpty)
              Text(
                userService.isGuest 
                  ? 'Connectez-vous pour voir vos notifications'
                  : 'Aucune notification',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...detailedNotifications.take(5).map((notification) => 
                _buildNotificationTile(notification)
              ).toList(),
            
            if (detailedNotifications.length > 5)
              TextButton(
                onPressed: () {
                  // Navigate to full notifications page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsPage(),
                    ),
                  );
                },
                child: Text('Voir toutes les notifications'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _markNotificationAsRead(notification),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notification.read ? Colors.grey[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: notification.read ? Colors.grey[200]! : Colors.blue[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getNotificationIcon(notification.type),
                color: notification.read ? Colors.grey : Colors.blue,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (notification.title.isNotEmpty)
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.createdAt.isNotEmpty)
                      Text(
                        _formatNotificationTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              if (!notification.read)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.shopping_cart;
      case 'promotion':
        return Icons.local_offer;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _formatNotificationTime(String createdAt) {
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inHours < 1) {
        return 'Il y a ${difference.inMinutes}min';
      } else if (difference.inDays < 1) {
        return 'Il y a ${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays}j';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
}