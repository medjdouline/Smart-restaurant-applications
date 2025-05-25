import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../user_service.dart';

class AllergiesPage extends StatefulWidget {
  const AllergiesPage({Key? key}) : super(key: key);

  @override
  State<AllergiesPage> createState() => _AllergiesPageState();
}

class _AllergiesPageState extends State<AllergiesPage> {
  final List<String> allergies = [
    'Fraise',
    'Fruit exotique',
    'Gluten',
    'Arachides',
    'Noix',
    'Lupin',
    'Champignons',
    'Moutarde',
    'Soja',
    'Crustacés',
    'Poissons',
    'Lactose',
    'Oeuf',
    'Autre'
  ];

  final Map<String, bool> selectedAllergies = {};
  final TextEditingController _autreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialiser toutes les allergies comme non sélectionnées
    for (var allergy in allergies) {
      selectedAllergies[allergy] = false;
    }
    
    // Charger les allergies existantes depuis UserService
    final userService = Provider.of<UserService>(context, listen: false);
    for (var allergy in userService.allergies) {
      if (allergies.contains(allergy)) {
        selectedAllergies[allergy] = true;
      } else {
        // Si c'est une allergie personnalisée ("Autre")
        selectedAllergies['Autre'] = true;
        _autreController.text = allergy;
      }
    }
  }

  @override
  void dispose() {
    _autreController.dispose();
    super.dispose();
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
                        color: i == 1 ? Colors.white : Colors.white54,
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
                        'Avez-vous des allergies ?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF730406),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      // Liste des allergies
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          child: Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 20,
                              runSpacing: 20,
                              children: allergies.map((allergy) {
                                return _buildAllergyItem(allergy);
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
  final selected = selectedAllergies.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key == 'Autre' 
          ? _autreController.text 
          : entry.key)
      .where((allergy) => allergy.isNotEmpty)
      .toList();
  
  if (selected.isEmpty) {
    // Permettre de continuer sans allergies
    Navigator.pushNamed(context, '/regime');
    return;
  }

  Provider.of<UserService>(context, listen: false)
      .saveAllergiesStep3(selected)
      .then((success) {
    if (success) {
      Navigator.pushNamed(context, '/regime');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la sauvegarde des allergies'),
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

  Widget _buildAllergyItem(String allergy) {
    if (allergy == 'Autre') {
      return GestureDetector(
        onTap: () {
          _showAutreDialog();
        },
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selectedAllergies[allergy]! 
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
                            color: const Color(0xFFF5E6CC),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                           ) ],
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 50,
                            color: Color(0xFF730406),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 25,
                          alignment: Alignment.center,
                          child: const FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              'Autre',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF730406),
                              ),
                            ),
                          ),
                        ),
                        if (selectedAllergies[allergy]! && _autreController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '"${_autreController.text}"',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF325434),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (selectedAllergies[allergy]!)
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
    } else {
      return GestureDetector(
        onTap: () {
          setState(() {
            selectedAllergies[allergy] = !selectedAllergies[allergy]!;
          });
        },
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selectedAllergies[allergy]! 
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
                           ) ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/${allergy.toLowerCase()}.jpg',
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                Container(
                                  color: const Color(0xFFE6D0AE),
                                  child: Icon(
                                    Icons.warning,
                                    size: 40,
                                    color: const Color(0xFFA93D0E),
                                  ),
                                ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 25,
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              allergy,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF730406),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (selectedAllergies[allergy]!)
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

  void _showAutreDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF5E6CC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Autre allergie ou restriction',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF730406),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: _autreController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Précisez',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Annuler',
                style: TextStyle(color: Color(0xFF325434)),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_autreController.text.isNotEmpty) {
                    selectedAllergies['Autre'] = true;
                  } else {
                    selectedAllergies['Autre'] = false;
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text(
                'Confirmer',
                style: TextStyle(color: Color(0xFF325434), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}