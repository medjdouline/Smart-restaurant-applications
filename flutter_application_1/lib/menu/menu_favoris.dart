import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../favoris_service.dart';
import '../cart_service.dart';
import '../rating_service.dart';

class FavorisPage extends StatefulWidget {
  const FavorisPage({Key? key}) : super(key: key);

  @override
  State<FavorisPage> createState() => _FavorisPageState();
}

class _FavorisPageState extends State<FavorisPage> {
  Map<String, dynamic>? _selectedPlat;
  double _currentRating = 0;

  void _showPlatDetails(Map<String, dynamic> plat, RatingService ratingService) {
    setState(() {
      _selectedPlat = plat;
      _currentRating = ratingService.getUserRating(plat['id']);
    });
  }

  void _closeDetails() {
    setState(() => _selectedPlat = null);
  }

  @override
  Widget build(BuildContext context) {
    final favorisService = Provider.of<FavorisService>(context);
    final cartService = Provider.of<CartService>(context);
    final ratingService = Provider.of<RatingService>(context);
    final platsFavoris = favorisService.platsFavoris;

    return Container(
      color: const Color(0xFFDFB976),
      child: Stack(
        children: [
          Column(
            children: [
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
                              'Mes favoris',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFB24516),
                              ),
                            ),
                            Text(
                              '${platsFavoris.length} ${platsFavoris.length <= 1 ? 'plat favori' : 'plats favoris'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFFB24516).withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (platsFavoris.isNotEmpty)
                        _buildFavorisSection(favorisService, ratingService)
                      else
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.favorite_border,
                                  size: 60,
                                  color: Color(0xFFB24516),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Vous n\'avez pas encore de favoris',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFB24516),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Explorez notre menu et ajoutez des plats à vos favoris',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFFB24516).withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_selectedPlat != null)
            _buildPlatDetailCard(_selectedPlat!, favorisService, cartService, ratingService),
        ],
      ),
    );
  }

  Widget _buildFavorisSection(FavorisService favorisService, RatingService ratingService) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFB24516),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Consumer<FavorisService>(
          builder: (context, favorisService, child) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Changed from 2 to 3 for smaller cards
                  childAspectRatio: 0.75, // Adjusted aspect ratio
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: favorisService.platsFavoris.length,
                itemBuilder: (context, index) {
                  final plat = favorisService.platsFavoris[index];
                  return GestureDetector(
                    onTap: () => _showPlatDetails(plat, ratingService),
                    child: _buildPlatCard(plat, favorisService),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlatCard(Map<String, dynamic> plat, FavorisService favorisService) {
    return Container(
      width: 170, // Fixed width similar to accueil cards
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
              child: Image.asset(
                plat['image'] ?? 'assets/placeholder.jpg',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.fastfood,
                      color: Colors.white,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Gradient overlay similar to accueil
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
          
          // Content overlay
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Favorite button at top right
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        try {
                          await favorisService.supprimerFavoriAPI(plat['id']);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e')),
                          );
                        }
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Text at bottom similar to accueil
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
                const SizedBox(height: 4),
                Text(
                  '${plat['prix']?.toStringAsFixed(0) ?? '0'} DA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Star rating similar to accueil
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
                color: const Color(0xFFDFB976), // Changed to match accueil
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
                            plat['image'] ?? 'assets/placeholder.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.fastfood,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () async {
                                try {
                                  await favorisService.supprimerFavoriAPI(plat['id']);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erreur: $e')),
                                  );
                                }
                              },
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
                    plat['nom'] ?? 'Nom inconnu',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB24516), // Changed to match accueil
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${plat['prix']?.toStringAsFixed(0) ?? '0'} DA',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3A5311), // Changed to match accueil
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 24),
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
                      plat['description'] ?? 'Aucune description disponible',
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      plat['ingredients'] ?? 'Ingrédients non spécifiés',
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
                      backgroundColor: const Color(0xFF3A5311), // Changed to match accueil
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
                        imageUrl: plat['image'],
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
}