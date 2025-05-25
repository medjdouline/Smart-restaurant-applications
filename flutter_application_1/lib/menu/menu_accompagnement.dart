import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../favoris_service.dart';
import '../cart_service.dart';
import '../rating_service.dart';
import '../services/menu_service.dart';
import '../models/item.dart';

class MenuAccompagnementPage extends StatefulWidget {
  const MenuAccompagnementPage({Key? key}) : super(key: key);

  @override
  State<MenuAccompagnementPage> createState() => _MenuAccompagnementPageState();
}

class _MenuAccompagnementPageState extends State<MenuAccompagnementPage> {
  Item? _selectedAccompagnement;
  double _currentRating = 0;

  void _showAccompagnementDetails(Item accompagnement) {
    setState(() {
      _selectedAccompagnement = accompagnement;
      _currentRating = 0;
    });
  }

  void _closeDetails() {
    setState(() => _selectedAccompagnement = null);
  }

  bool _isFavorite(FavorisService favorisService, String id) {
    return favorisService.estFavori(id);
  }

  void _toggleFavorite(FavorisService favorisService, Item accompagnement) {
    setState(() {
      if (_isFavorite(favorisService, accompagnement.id)) {
        favorisService.supprimerFavori(accompagnement.id);
      } else {
        favorisService.ajouterFavori(accompagnement.toMap());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuService = Provider.of<MenuService>(context);
    final favorisService = Provider.of<FavorisService>(context);
    final cartService = Provider.of<CartService>(context);
    final ratingService = Provider.of<RatingService>(context);

    return Scaffold(
      body: Container(
        color: const Color(0xFFE0BB76),
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40, left: 10, right: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.brown[700], size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB35F32),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.amber[300],
                              radius: 14,
                              child: Icon(Icons.person, color: Colors.brown[800], size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Utilisateur',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ACCOMPAGNEMENTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildContent(menuService, favorisService),
                ),
              ],
            ),
            if (_selectedAccompagnement != null) 
              _buildAccompagnementDetailCard(favorisService, cartService, ratingService),
          ],
        ),
      ),
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
            Text('Chargement des accompagnements...', style: TextStyle(color: Colors.brown, fontSize: 16)),
          ],
        ),
      );
    }

    if (menuService.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[700]),
            const SizedBox(height: 16),
            Text('Erreur de chargement', style: TextStyle(color: Colors.red[700], fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(menuService.errorMessage!, style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => menuService.refresh(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final groupedAccompagnements = menuService.groupedAccompagnements;

    if (groupedAccompagnements.isEmpty) {
      return const Center(
        child: Text('Aucun accompagnement disponible', style: TextStyle(color: Colors.brown, fontSize: 18)),
      );
    }

    return RefreshIndicator(
      onRefresh: menuService.refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 10),
        children: [
          for (var subCategory in groupedAccompagnements.keys)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 8),
                  child: Text(
                    subCategory,
                    style: TextStyle(color: Colors.brown[700], fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: SizedBox(
                    height: 170,
                    child: ListView(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      children: [
                        SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                        for (var accompagnement in groupedAccompagnements[subCategory]!)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _buildAccompagnementCard(accompagnement, favorisService),
                          ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAccompagnementCard(Item accompagnement, FavorisService favorisService) {
    return GestureDetector(
      onTap: () => _showAccompagnementDetails(accompagnement),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: AssetImage(accompagnement.image),
            fit: BoxFit.cover,
          ),
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: IconButton(
                icon: Icon(
                  _isFavorite(favorisService, accompagnement.id) ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite(favorisService, accompagnement.id) ? Colors.red : Colors.white,
                  size: 24,
                ),
                onPressed: () => _toggleFavorite(favorisService, accompagnement),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(accompagnement.nom,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Text('${accompagnement.prix} DA', style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 4),
                      Text('${accompagnement.pointsFidelite} pts', style: const TextStyle(color: Colors.white, fontSize: 10)),
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

  Widget _buildAccompagnementDetailCard(FavorisService favorisService, CartService cartService, RatingService ratingService) {
    final averageRating = ratingService.getAverageRating(_selectedAccompagnement!.id);
    final ratingCount = ratingService.getRatingCount(_selectedAccompagnement!.id);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE0BB76),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.asset(
                          _selectedAccompagnement!.image,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isFavorite(favorisService, _selectedAccompagnement!.id)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite(favorisService, _selectedAccompagnement!.id) ? Colors.red : Colors.white,
                              ),
                              onPressed: () => _toggleFavorite(favorisService, _selectedAccompagnement!),
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
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(_selectedAccompagnement!.nom,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                        const SizedBox(height: 10),
                        Text('${_selectedAccompagnement!.prix} DA',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
                        const SizedBox(height: 10),
                        Text('Points fidélité: ${_selectedAccompagnement!.pointsFidelite}',
                            style: const TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 24),
                            const SizedBox(width: 5),
                            Text(averageRating.toStringAsFixed(1),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[800])),
                            const SizedBox(width: 5),
                            Text('($ratingCount avis)', style: TextStyle(fontSize: 16, color: Colors.brown[600])),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text('DESCRIPTION',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(_selectedAccompagnement!.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 20),
                        const Text('INGRÉDIENTS',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(_selectedAccompagnement!.ingredients, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 20),
                        const Text('NOTER CE PRODUIT',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            if (_currentRating > 0) {
                              ratingService.addRating(_selectedAccompagnement!.id, _currentRating);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Merci pour votre note de $_currentRating étoiles!'),
                                duration: const Duration(seconds: 2),
                              ));
                              setState(() {
                                _currentRating = 0;
                              });
                            }
                          },
                          child: const Text('SOUMETTRE LA NOTE', style: TextStyle(fontSize: 14)),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: () {
                            cartService.addItem(
                              id: _selectedAccompagnement!.id,
                              nom: _selectedAccompagnement!.nom,
                              prix: _selectedAccompagnement!.prix.toDouble(),
                              imageUrl: _selectedAccompagnement!.image,
                              pointsFidelite: _selectedAccompagnement!.pointsFidelite,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  '${_selectedAccompagnement!.nom} ajouté à votre commande (+${_selectedAccompagnement!.pointsFidelite} pts)'),
                              duration: const Duration(seconds: 1),
                            ));
                            _closeDetails();
                          },
                          child: const Text('COMMANDER', style: TextStyle(fontSize: 18)),
                        ),
                      ],
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