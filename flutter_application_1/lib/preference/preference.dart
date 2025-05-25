import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../user_service.dart';

class FoodPreferencesScreen extends StatefulWidget {
  const FoodPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<FoodPreferencesScreen> createState() => _FoodPreferencesScreenState();
}

class _FoodPreferencesScreenState extends State<FoodPreferencesScreen> {
  final Map<String, bool> _selectedPreferences = {};
  final List<String> _preferences = [
    'Soupes et Potages',
    'Salades et Crudités',
    'Poissons et Fruits de mer',
    'Cuisine traditionnelle',
    'Viandes',
    'Sandwichs et burgers',
    'Végétariens',
    'Crémes et Mousses',
    'Pâtisseries',
    'Fruits et Sorbets',
  ];

  final Map<String, String> _preferenceImages = {
    'Soupes et Potages': 'assets/images/soupes.jpg',
    'Salades et Crudités': 'assets/images/salades.jpg',
    'Poissons et Fruits de mer': 'assets/images/poissons.jpg',
    'Cuisine traditionnelle': 'assets/images/traditionnelle.jpg',
    'Viandes': 'assets/images/viandes.jpg',
    'Sandwichs et burgers': 'assets/images/burgers.jpg',
    'Végétariens': 'assets/images/vegetariens.jpg',
    'Crémes et Mousses': 'assets/images/mousses.jpg',
    'Pâtisseries': 'assets/images/patisseries.jpg',
    'Fruits et Sorbets': 'assets/images/fruits.jpg',
  };

  // Display names to shorten long category names
  final Map<String, String> _displayNames = {
    'Poissons et Fruits de mer': 'Poissons',
    'Cuisine traditionnelle': 'Tradition',
    'Sandwichs et burgers': 'Sandwichs',
    'Crémes et Mousses': 'Desserts',
    'Soupes et Potages': 'Soupes',
    'Salades et Crudités': 'Salades',
  };

  @override
  void initState() {
    super.initState();
    final userService = Provider.of<UserService>(context, listen: false);
    for (var pref in _preferences) {
      _selectedPreferences[pref] = userService.preferences.contains(pref);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFA93D0E),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 30),
              // Logo et titre
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.restaurant,
                      size: 50,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Good taste !',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Itim',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              // Indicateur d'étape
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 4; i++)
                    Container(
                      width: 30,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: i == 2 ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Contenu principal
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDDB77C),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      const Text(
                        'Vos préférences alimentaires',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF730406),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      // Liste des préférences
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          child: Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 20,
                              runSpacing: 20,
                              children: _preferences.map((pref) {
                                return _buildPreferenceItem(pref);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      // Boutons de navigation
                      Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 150,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF730406),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 3,
                                ),
                                child: const Text(
                                  'Retour',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 150,
                              height: 50,
                              child: ElevatedButton(
onPressed: () {
  final selected = _selectedPreferences.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList();

  if (selected.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sélectionnez au moins une préférence'),
        backgroundColor: Color(0xFF730406),
      ),
    );
    return;
  }

  Provider.of<UserService>(context, listen: false)
      .completeRegistrationStep5(selected)
      .then((success) {
        if (success) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/menu',
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur finalisation inscription'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      });
},
                                child: const Text(
                                  'Suivant',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFDDB77C),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceItem(String pref) {
    // Get shorter display name if available, otherwise use original
    final displayName = _displayNames[pref] ?? pref;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPreferences[pref] = !_selectedPreferences[pref]!;
        });
      },
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedPreferences[pref]! 
                ? const Color(0xFF325434) 
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            _preferenceImages[pref]!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              Container(
                                color: const Color(0xFFE6D0AE),
                                child: const Icon(
                                  Icons.fastfood,
                                  size: 40,
                                  color: Color(0xFFA93D0E),
                                ),
                              ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Improved text container with fixed height
                      Container(
                        height: 25, // Fixed height for consistent layout
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF730406),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_selectedPreferences[pref]!)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF325434),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}