import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'menu_entree.dart';
import 'menu_plats.dart';
import 'menu_dessert.dart';
import 'menu_nouveautes.dart';
import 'menu_boissons.dart';
import 'menu_accompagnement.dart';
import 'menu_cart.dart';
import '../cart_service.dart';
import '../services/menu_service.dart'; // ADD THIS IMPORT


class MenuChoixPage extends StatelessWidget {
  final String? nomUtilisateur;
  final String? photoUrl;

  const MenuChoixPage({
    Key? key,
    this.nomUtilisateur,
    this.photoUrl,
  }) : super(key: key);

  final List<Map<String, dynamic>> _categories = const [
    {
    'nom': 'Nouveautés',
    'couleur': Color(0xFFFF6B6B),
    'image': 'assets/images/nouveaute.png',
    'page': MenuNouveautesPage(),
  },
    {
      'nom': 'Entrées',
      'couleur': Color(0xFF5CB85C),
      'image': 'assets/images/entree.png',
      'page': MenuEntreePage(),
    },
    {
      'nom': 'Plats',
      'couleur': Color(0xFFB24516),
      'image': 'assets/images/plat.png',
      'page': MenuPlatsPage(),
    },
    {
      'nom': 'Accompagnement',
      'couleur': Color(0xFF8D6E63),
      'image': 'assets/images/accompagnement.jpg',
      'page': MenuAccompagnementPage(),
    },
    {
      'nom': 'Dessert',
      'couleur': Color(0xFFFF9999),
      'image': 'assets/images/dessert.png',
      'page': MenuDessertPage(),
    },
    {
      'nom': 'Boisson',
      'couleur': Color(0xFFBF8A49),
      'image': 'assets/images/boisson.png',
      'page': MenuBoissonPage(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final itemCount = cartService.items.length;

    return Scaffold(
      body: Container(
        color: const Color(0xFFDFB976),
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30.0),
                  child: Text(
                    'Choisissez ce que vous voulez !',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D552C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20,
                        runSpacing: 20,
                        children: _categories.map((categorie) => _buildCategoryButton(context, categorie)).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: _buildCartButton(context, itemCount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFB24516)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFB24516),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 12,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                    child: photoUrl == null ? Icon(Icons.person, color: Colors.grey[400], size: 16) : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salut!',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        nomUtilisateur ?? 'utilisateur',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(BuildContext context, Map<String, dynamic> categorie) {
    return GestureDetector(
      onTap: () async {
        final menuService = Provider.of<MenuService>(context, listen: false);
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        await menuService.refresh();
        
        Navigator.of(context).pop();
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => categorie['page'],
          ),
        );
      },
      child: Container(
        width: 160,
        height: 160,
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
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              categorie['image'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                        const SizedBox(height: 8),
                        Text('Image non trouvée', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                color: categorie['couleur'],
                child: Text(
                  categorie['nom'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButton(BuildContext context, int itemCount) {
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
}