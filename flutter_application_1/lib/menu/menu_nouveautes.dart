import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/menu_service.dart';
import '../cart_service.dart';
import '../favoris_service.dart';
import '../rating_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenuNouveautesPage extends StatefulWidget {
  const MenuNouveautesPage({Key? key}) : super(key: key);

  @override
  State<MenuNouveautesPage> createState() => _MenuNouveautesPageState();
}

class _MenuNouveautesPageState extends State<MenuNouveautesPage> {
  Map<String, dynamic>? _selectedPlat;
  double _currentRating = 0;
  List<Map<String, dynamic>> _nouveautes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNouveautes();
    _loadFavoris();
  }

  Future<void> _loadFavoris() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final favorisService = Provider.of<FavorisService>(context, listen: false);
      // Use the API method instead of Firebase method
      await favorisService.chargerFavorisAPI();
    }
  }

  Future<void> _loadNouveautes() async {
    try {
      final menuService = Provider.of<MenuService>(context, listen: false);
      final nouveautes = await menuService.getNouveautes();
      setState(() {
        _nouveautes = nouveautes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: $e')),
      );
    }
  }

  void _showPlatDetails(Map<String, dynamic> plat, RatingService ratingService) {
    setState(() {
      _selectedPlat = plat;
      _currentRating = ratingService.getUserRating(plat['id']);
    });
  }

  void _closeDetails() => setState(() => _selectedPlat = null);

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final favorisService = Provider.of<FavorisService>(context);
    final ratingService = Provider.of<RatingService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFDFB976),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              _buildTitle(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _nouveautes.isEmpty
                        ? _buildEmptyState()
                        : _buildNouveautesList(favorisService, ratingService),
              ),
            ],
          ),
          if (_selectedPlat != null)
            _buildPlatDetailCard(_selectedPlat!, favorisService, cartService, ratingService),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFB24516), size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fiber_new, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 15),
          Text(
            'Nouveautés',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D552C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: const Color(0xFFB24516).withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune nouveauté pour le moment',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFB24516),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNouveautesList(FavorisService favorisService, RatingService ratingService) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFB24516),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Consumer<FavorisService>(
        builder: (context, favorisService, child) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _nouveautes.length,
                itemBuilder: (context, index) {
                  final plat = _nouveautes[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => _showPlatDetails(plat, ratingService),
                      child: _buildPlatCard(plat, favorisService),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlatCard(Map<String, dynamic> plat, FavorisService favorisService) {
    final isFavorite = favorisService.estFavori(plat['id']);
    
    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: plat['image_url'] != null && plat['image_url'].isNotEmpty
                ? Image.network(
                    plat['image_url'],
                    height: double.infinity,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          ),
          // "NOUVEAU" badge
          Positioned(
            top: 5,
            left: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'NOUVEAU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Favorite button - FIXED
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () async {
  try {
    if (favorisService.estFavori(plat['id'])) {
      await favorisService.supprimerFavoriAPI(plat['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${plat['nom']} retiré des favoris'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      await favorisService.ajouterFavoriAPI(plat['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${plat['nom']} ajouté aux favoris'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e')),
    );
  }
},
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.white,
                size: 24,
              ),
            ),
          ),
          // Text at bottom
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plat['nom'] ?? 'Nom inconnu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${plat['prix']?.toStringAsFixed(2) ?? '0.00'} DA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFDFB976),
            const Color(0xFFB24516),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant,
            size: 30,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(height: 4),
          Text(
            'Image non disponible',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlatDetailCard(
    Map<String, dynamic> plat,
    FavorisService favorisService,
    CartService cartService,
    RatingService ratingService,
  ) {
    final averageRating = ratingService.getAverageRating(plat['id']);
    final ratingCount = ratingService.getRatingCount(plat['id']);
    final isFavorite = favorisService.estFavori(plat['id']);

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
                color: const Color(0xFFE6C89D),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: plat['image_url'] != null && plat['image_url'].isNotEmpty
                            ? Image.network(
                                plat['image_url'],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                              )
                            : _buildPlaceholderImage(),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NOUVEAU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
  // Use local favorites method instead of API
  if (favorisService.estFavori(plat['id'])) {
    favorisService.supprimerFavori(plat['id']);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${plat['nom']} retiré des favoris'),
        duration: const Duration(seconds: 1),
      ),
    );
  } else {
    favorisService.ajouterFavori(plat);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${plat['nom']} ajouté aux favoris'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _closeDetails,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    plat['nom'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${plat['prix']?.toStringAsFixed(2) ?? '0.00'} DA',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 24),
                      const SizedBox(width: 5),
                      Text(
                        averageRating.toStringAsFixed(1),
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      plat['description'] ?? 'Pas de description disponible',
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
                          index < _currentRating ? Icons.star : Icons.star_border,
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
                        ratingService.addRating(plat['id'], _currentRating);
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
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      cartService.addItem(
                        id: plat['id'],
                        nom: plat['nom'],
                        prix: plat['prix']?.toDouble() ?? 0.0,
                        imageUrl: plat['image_url'] ?? '',

                      );
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${plat['nom']} ajouté à votre commande'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      _closeDetails();
                    },
                    child: const Text(
                      'COMMANDER',
                      style: TextStyle(fontSize: 18),
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
}