import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../user_service.dart';
import 'package:flutter/services.dart';

class InfoPersoPage extends StatefulWidget {
  final Map<String, dynamic>? userInfo;

  const InfoPersoPage({
    Key? key,
    this.userInfo,
  }) : super(key: key);

  @override
  State<InfoPersoPage> createState() => _InfoPersoPageState();
}

class _InfoPersoPageState extends State<InfoPersoPage> {
  File? _profileImage;
  String? _selectedGender;
  DateTime? _selectedDate;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Masquer la barre de statut (heure, batterie, etc.)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _loadUserData();
  }
  void _loadUserData() {
    final userService = Provider.of<UserService>(context, listen: false);
    
    // Set initial values if they exist
    if (userService.gender != null) {
      _selectedGender = userService.gender;
    }
    
    if (userService.birthdate != null) {
      _selectedDate = userService.birthdate;
      _dateController.text = "${userService.birthdate!.day}/${userService.birthdate!.month}/${userService.birthdate!.year}";
    }
    
    setState(() {});
  }
  @override
  void dispose() {
    _dateController.dispose();
    // Réactiver la barre de statut lors de la sortie de l'écran
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final nomUtilisateur = userService.nomUtilisateur ?? 'Utilisateur';
        final email = userService.email ?? 'email@exemple.com';
        final phone = userService.phone ?? 'Non spécifié';

        return Scaffold(
          body: Container(
            color: const Color(0xFFA93D0E),
            child: SafeArea(
              top: false, // Ne pas tenir compte de la status bar masquée
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Text(
                          'Good taste !',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Itim',
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                            onPressed: () => Navigator.pushReplacementNamed(context, '/inscription'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) => Container(
                      width: 20,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      color: index == 0 ? Colors.white : Colors.white54,
                    )),
                  ),
                  const SizedBox(height: 20),
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
                          backgroundColor: Colors.white,
                          child: Text(
                            nomUtilisateur[0].toUpperCase(),
                            style: const TextStyle(color: Color(0xFFA93D0E)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
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
                              nomUtilisateur,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDDB77C),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Informations personnelles',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF730406),
                              ),
                            ),
                            const SizedBox(height: 30),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF325434),
                                        width: 2,
                                      ),
                                    ),
                                    child: _profileImage != null
                                        ? ClipOval(
                                            child: Image.file(
                                              _profileImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Color(0xFF730406),
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 5,
                                    right: 5,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF325434),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Photo de profil (optionnelle)',
                              style: TextStyle(
                                color: Color(0xFF730406),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedGender,
                                hint: const Text('Genre *'),
                                items: ['Homme', 'Femme'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedGender = newValue;
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.person_outline, color: Color(0xFF730406)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _dateController,
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'Date de naissance *',
                                prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF730406)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () => Navigator.pushReplacementNamed(context, '/inscription'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF730406),
                                    minimumSize: const Size(130, 45),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: const Text(
                                    'Retour',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
ElevatedButton(
  onPressed: _isLoading ? null : () async {
    if (_selectedGender != null && _selectedDate != null) {
      setState(() => _isLoading = true);

      try {
        final success = await Provider.of<UserService>(context, listen: false)
            .savePersonalInfoStep2(
              gender: _selectedGender!,
              birthdate: _selectedDate!,
            );

        if (success) {
          Navigator.pushNamed(context, '/allergie');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save personal information'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir les champs obligatoires (*)'),
          backgroundColor: Color(0xFF730406),
        ),
      );
    }
  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF325434),
                                    minimumSize: const Size(130, 45),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: _isLoading 
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Suivant',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFDDB77C),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
