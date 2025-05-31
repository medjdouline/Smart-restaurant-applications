import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/menu/menu_choix.dart';
import 'package:flutter_application_1/menu/menu_cart.dart';
import 'package:flutter_application_1/menu/menu_assistance.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/cart_service.dart';
import 'package:flutter_application_1/services/menu_service.dart';
import 'package:flutter_application_1/models/item.dart';
import 'package:flutter_application_1/user_service.dart';
import 'package:flutter_application_1/points_fidelite_widget.dart';

class AcceuilInvite extends StatefulWidget {
  const AcceuilInvite({Key? key}) : super(key: key);

  @override
  State<AcceuilInvite> createState() => _AcceuilInviteState();
}

class _AcceuilInviteState extends State<AcceuilInvite> {
  final ScrollController _scrollController = ScrollController();
  Item? _selectedPlat;
  List<Item> _recommendedPlats = [];

  @override
  void initState() {
    super.initState();
    _loadRecommendedPlats();
  }

  Future<void> _loadRecommendedPlats() async {
    final menuService = Provider.of<MenuService>(context, listen: false);
    await menuService.refresh();

    if (mounted) {
      setState(() {
        final groupedEntrees = menuService.groupedEntrees;
        final entrees = groupedEntrees.values
            .expand((plats) => plats.take(3))
            .toList();

        _recommendedPlats = entrees.take(12).toList();
      });
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
    });
  }

  void _closeDetails() {
    setState(() => _selectedPlat = null);
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final menuService = Provider.of<MenuService>(context);
    final userService = Provider.of<UserService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Invité'),
        backgroundColor: const Color(0xFFB24516),
        automaticallyImplyLeading: false,
        actions: [
          // Show loyalty points widget only for logged-in users
          if (!userService.isGuest)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: PointsFideliteWidget(),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Container(
            color: const Color(0xFFDFB976),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant,
                          color: const Color(0xFFB24516),
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Feuille de l\'Aures',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB24516),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userService.isGuest ? 'Mode Invité' : 'Bienvenue ${userService.nomUtilisateur}',
                          style: const TextStyle(
                            color: Color(0xFFB24516),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Recommendations content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                '${_recommendedPlats.length} plats disponibles',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color(0xFFB24516).withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Horizontal list of dishes
                        Expanded(
                          child: menuService.isLoading
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFFB24516)))
                              : _recommendedPlats.isEmpty
                                  ? const Center(child: Text('Aucune recommandation disponible'))
                                  : Container(
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
                                            itemCount: _recommendedPlats.length,
                                            itemBuilder: (context, index) {
                                              return GestureDetector(
                                                onTap: () => _showPlatDetails(_recommendedPlats[index]),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                  child: _buildPlatCard(_recommendedPlats[index]),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        // Scroll buttons
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
                        
                        // Full menu button
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
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Selected dish details
          if (_selectedPlat != null)
            _buildPlatDetailCard(cartService, userService),
            
          // Floating cart button
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildCartButton(cartService.items.length),
          ),
          
          // Floating "Ask server" button
          Positioned(
            bottom: 90,
            right: 20,
            child: _buildAssistanceButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatCard(Item plat) {
    return Container(
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
          // Dish image
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              color: Colors.grey.shade300,
              child: Image.asset(
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
              ),
            ),
          ),
          
          // Gradient for text
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
          
          // Text content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatDetailCard(CartService cartService, UserService userService) {
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
                          child: Image.asset(
                            _selectedPlat!.image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.fastfood,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _closeDetails,
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
                  ElevatedButton(
                    onPressed: () {
                      cartService.addItem(
                        id: _selectedPlat!.id,
                        nom: _selectedPlat!.nom,
                        prix: _selectedPlat!.prix.toDouble(),
                        imageUrl: _selectedPlat!.image,
                      );
                      
                      if (userService.isGuest) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connectez-vous pour finaliser votre commande'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Plat ajouté au panier'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                      _closeDetails();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A5311),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'AJOUTER AU PANIER',
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

  Widget _buildAssistanceButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AssistancePage(),
          ),
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.blue[800],
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.person_search,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}