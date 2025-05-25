import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/home.dart';
import '../user_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    const Color bgColor = Color(0xFFDFB976);
    const Color buttonColor = Color(0xFF800000);
    const Color whiteColor = Colors.white;
    const Color darkGreenColor = Color(0xFF3A5311);
    

    void _showLogoutDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  userService.logout();
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const RestaurantHomePage()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Confirmer', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    }

    void _showEditDialog(String field, String currentValue) {
      final controller = TextEditingController(text: currentValue);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Modifier $field'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'Nouveau $field'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    if (field == 'Téléphone') {
                      userService.updatePhoneNumber(controller.text);
                    }
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      );
    }

    void _showEditPreferencesDialog(String type, List<String> currentItems) {
      final List<String> allOptions;
      final String title;

      switch (type) {
        case 'allergies':
          allOptions = [
            'Fraise', 'Fruit exotique', 'Gluten', 'Arachides', 'Noix', 
            'Lupin', 'Champignons', 'Moutarde', 'Soja', 'Crustacés', 
            'Poissons', 'Lactose', 'Oeuf'
          ];
          title = 'Modifier vos allergies';
          break;
        case 'preferences':
          allOptions = [
            'Végétarien', 'Végan', 'Sans gluten', 'Pesco-végétarien', 
            'Flexitarien', 'Paléo', 'Cétogène'
          ];
          title = 'Modifier vos préférences';
          break;
        case 'diets':
          allOptions = [
            'Halal', 'Cacher', 'Sans lactose', 'Sans sucre', 
            'Faible en sel', 'Sans œuf'
          ];
          title = 'Modifier vos régimes';
          break;
        default:
          allOptions = [];
          title = 'Modifier';
      }

      final Map<String, bool> selectedItems = {};
      for (var option in allOptions) {
        selectedItems[option] = currentItems.contains(option);
      }

      final TextEditingController _autreController = TextEditingController();
      if (type == 'allergies') {
        final autres = currentItems.where((item) => !allOptions.contains(item)).toList();
        if (autres.isNotEmpty) {
          selectedItems['Autre'] = true;
          _autreController.text = autres.join(', ');
        }
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: const Color(0xFFF5E6CC),
                title: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF730406),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...allOptions.map((option) => CheckboxListTile(
                            title: Text(option),
                            value: selectedItems[option] ?? false,
                            onChanged: (bool? value) {
                              setState(() {
                                selectedItems[option] = value ?? false;
                              });
                            },
                          )),
                      if (type == 'allergies') ...[
                        const Divider(),
                        CheckboxListTile(
                          title: const Text('Autre'),
                          value: selectedItems['Autre'] ?? false,
                          onChanged: (bool? value) {
                            setState(() {
                              selectedItems['Autre'] = value ?? false;
                            });
                          },
                        ),
                        if (selectedItems['Autre'] ?? false)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _autreController,
                              decoration: const InputDecoration(
                                hintText: 'Précisez vos autres allergies',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () {
                      final selected = selectedItems.entries
                          .where((entry) => entry.value)
                          .map((entry) => entry.key == 'Autre' 
                              ? _autreController.text 
                              : entry.key)
                          .where((item) => item.isNotEmpty)
                          .toList();

                      switch (type) {
                        case 'allergies':
                          userService.updateAllergies(selected);
                          break;
                        case 'preferences':
                          userService.updatePreferences(selected);
                          break;
                        case 'diets':
                          userService.updateDiets(selected);
                          break;
                      }

                      Navigator.pop(context);
                    },
                    child: const Text('Enregistrer'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    Widget _buildEditableSection(String title, List<String> items, VoidCallback onEdit) {
      return GestureDetector(
        onTap: onEdit,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF3A5311).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF3A5311),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Color(0xFF3A5311)),
                    onPressed: onEdit,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                const Text(
                  'Aucun élément sélectionné',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFB976).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF3A5311).withOpacity(0.5)),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Color(0xFF3A5311),
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      );
    }

    Widget _buildUserInfoField(String label, String? value, String fieldName) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label :',
                style: const TextStyle(
                  color: Color(0xFF3A5311),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value ?? 'Non spécifié',
                style: const TextStyle(
                  color: Color(0xFF3A5311),
                  fontSize: 16,
                ),
              ),
            ),
            if (fieldName == 'Téléphone')
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Color(0xFF3A5311)),
                onPressed: () => _showEditDialog(fieldName, value ?? ''),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFB24516),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: bgColor,
                      backgroundImage: userService.photoUrl != null
                          ? NetworkImage(userService.photoUrl!)
                          : null,
                      child: userService.photoUrl == null
                          ? const Icon(Icons.person, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Salut!',
                          style: TextStyle(
                            color: whiteColor,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          userService.nomUtilisateur ?? 'utilisateur',
                          style: const TextStyle(
                            color: whiteColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.notifications_none,
                      color: whiteColor,
                      size: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 600,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: bgColor.withOpacity(0.5),
                          child: userService.photoUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    userService.photoUrl!,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: darkGreenColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: whiteColor,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Modifier la photo',
                      style: TextStyle(
                        color: darkGreenColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Section Informations utilisateur
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFF3A5311).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations personnelles',
                            style: TextStyle(
                              color: Color(0xFF3A5311),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildUserInfoField('Username', userService.nomUtilisateur, 'Nom'),
                          _buildUserInfoField('Email', userService.email, 'Email'),
                          _buildUserInfoField('Téléphone', userService.phone, 'Téléphone'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section Préférences alimentaires
                    
                    // Section Régimes alimentaires
                    _buildEditableSection(
                      'Régimes alimentaires',
                      userService.diets,
                      () => _showEditPreferencesDialog('diets', userService.diets),
                    ),
                    const SizedBox(height: 20),
                    
                    // Section Allergies
                    _buildEditableSection(
                      'Allergies',
                      userService.allergies,
                      () => _showEditPreferencesDialog('allergies', userService.allergies),
                    ),
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: 200,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _showLogoutDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Déconnexion',
                          style: TextStyle(
                            color: whiteColor,
                            fontSize: 16,
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
    );
  }
}