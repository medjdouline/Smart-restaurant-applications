import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RestaurantHomePage extends StatelessWidget {
  const RestaurantHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: screenSize.width,
          height: screenSize.height,
          child: Stack(
            children: [
              // Image de fond avec coins arrondis en bas
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(200),
                    bottomRight: Radius.circular(200),
                  ),
                  child: Image.asset(
                    'assets/restaurant_interior.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // Section contenu en bas
              Positioned(
                bottom: 0,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0BB76),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(200),
                    ),
                  ),
                  child: SizedBox(
                    width: screenSize.width,
                    height: screenSize.height * 0.65,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            color: Color(0xAA8B0000),
                            size: 64,
                          ),
                          const SizedBox(height: 24),
                          
                          Text(
                            'Feuille de L\'Aures ',
                            style: GoogleFonts.inknutAntiqua(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF8B0000),
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          ElevatedButton(
                            onPressed: () {
                              // Utilisez Navigator.pushNamed pour la navigation
                              Navigator.pushNamed(context, '/connexion');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA93D0E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 32,
                              ),
                              minimumSize: const Size(220, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'bienvenue',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}