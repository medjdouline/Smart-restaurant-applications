import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/profile/profile_bloc.dart';
import 'package:good_taste/data/models/phone_number.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:formz/formz.dart';



class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  PhoneNumber _phoneNumber = const PhoneNumber.pure();
  final _logger = Logger('EditProfileScreen');

  @override
  void initState() {
    super.initState();
    _logger.info('EditProfileScreen: initState called, requesting profile data');
   
    context.read<ProfileBloc>().add(ProfileLoaded());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  
    final state = context.read<ProfileBloc>().state;
    _loadProfileData(state);
  }

  void _loadProfileData(ProfileState state) {
    _logger.info('Loading profile data: ${state.username.value}, ${state.email.value}');
    
    if (mounted) {
      setState(() {
        _usernameController.text = state.username.value;
        _emailController.text = state.email.value;
        
        if (state.phoneNumber.value.isNotEmpty) {
          _phoneNumberController.text = state.phoneNumber.value;
          _phoneNumber = state.phoneNumber;
        }
      });
    }
  }
    
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    
    if (image != null && mounted) {
      
      context.read<ProfileBloc>().add(ProfileImageChanged(File(image.path)));
      _logger.info('Image de profil temporaire sélectionnée: ${image.path}');
    }
  }
void _validatePhoneNumber(String value) {
  final phoneNumber = PhoneNumber.dirty(value);
  setState(() {
    _phoneNumber = phoneNumber;
  });
  // Pas besoin d'émettre d'événement ici, on le fera seulement à la soumission
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9B975),
      appBar: AppBar(
        title: const Text('Mon profil', style: TextStyle(color: Color(0xFFBA3400))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFBA3400)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          _logger.info('DEBUG - Etat du ProfileBloc dans EditProfileScreen:');
          _logger.info('Nom: ${state.username.value}');
          _logger.info('Email: ${state.email.value}');
          
         
          if (state.status == FormzSubmissionStatus.initial) {
            _loadProfileData(state);
          }
          
          if (state.status == FormzSubmissionStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profil mis à jour avec succès')),
            );
            Navigator.of(context).pop();
          } else if (state.status == FormzSubmissionStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: ${state.errorMessage ?? "Échec de la mise à jour"}')),
            );
          }
        },
        builder: (context, state) {
          if (state.status == FormzSubmissionStatus.inProgress) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Photo de profil
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFDB9051),
                        backgroundImage: _getProfileImageProvider(state),
                        child: !_hasProfileImage(state)
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                      ),
                      TextButton(
                        onPressed: _selectImage,
                        child: const Text(
                          'Modifier la photo',
                          style: TextStyle(
                            color: Color(0xFF245536),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Nom d'utilisateur (lecture seule)
                const Text(
                  'Nom d\'utilisateur',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFBA3400),
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8C8B3).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _usernameController,
                    enabled: false,
                    decoration: const InputDecoration(
                      hintText: 'Nom d\'utilisateur',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                    ),
                    style: const TextStyle(color: Color(0xFF757575)),
                  ),
                ),
                const SizedBox(height: 15),
                
                // Adresse e-mail (lecture seule)
                const Text(
                  'Adresse e-mail',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFBA3400),
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8C8B3).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _emailController,
                    enabled: false,
                    decoration: const InputDecoration(
                      hintText: 'Adresse e-mail',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                    ),
                    style: const TextStyle(color: Color(0xFF757575)),
                  ),
                ),
                const SizedBox(height: 15),
                
                // Numéro de téléphone (modifiable)
                const Text(
                  'Numéro de téléphone',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFBA3400),
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8C8B3),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.phone,
                    onChanged: _validatePhoneNumber,
                    decoration: InputDecoration(
                      hintText: 'Numéro de téléphone',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      errorText: _phoneNumber.isNotValid ? 'Format invalide (ex: 0123456789)' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
               
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF245536),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(vertical: 15),
    ),
    onPressed: _phoneNumber.isValid ? () {
      // Vérifie si le numéro a vraiment changé
      final currentPhone = context.read<ProfileBloc>().state.phoneNumber.value;
      final newPhone = _phoneNumberController.text;
      
      if (newPhone != currentPhone) {
        context.read<ProfileBloc>().add(
          PhoneNumberSubmitted(newPhone),
        );
      } else {
        // Si aucun changement, on ferme simplement
        Navigator.of(context).pop();
      }
    } : null,
    child: const Text('Enregistrer', style: TextStyle(fontSize: 16)),
  ),
),
                
               
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  bool _hasProfileImage(ProfileState state) {
    return state.tempProfileImage != null || 
           (state.profileImage != null && state.profileImage!.isNotEmpty);
  }
  
  
  ImageProvider? _getProfileImageProvider(ProfileState state) {
    
    if (state.tempProfileImage != null) {
      return FileImage(File(state.tempProfileImage!));
    } 
    
    else if (state.profileImage != null && state.profileImage!.isNotEmpty) {
      if (state.profileImage!.startsWith('assets/')) {
        return AssetImage(state.profileImage!) as ImageProvider;
      } else {
        return FileImage(File(state.profileImage!));
      }
    }
    
    return null;
  }
}