import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:good_taste/logic/blocs/personal_info/personal_info_bloc.dart';
import 'package:good_taste/logic/blocs/personal_info/personal_info_event.dart';
import 'package:good_taste/logic/blocs/personal_info/personal_info_state.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _selectImage(BuildContext context) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, 
      maxWidth: 800, 
      maxHeight: 800,   
    );
    
    if (image != null) {
      // ignore: use_build_context_synchronously
      context.read<PersonalInfoBloc>().add(ProfileImageChanged(File(image.path)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = RepositoryProvider.of<AuthRepository>(context);
    return BlocProvider(
      create: (_) => PersonalInfoBloc(authRepository: authRepository),
      child: BlocConsumer<PersonalInfoBloc, PersonalInfoState>(
        listener: (context, state) {
          if (state.status == PersonalInfoStatus.failure || 
              state.status == PersonalInfoStatus.invalid && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Une erreur est survenue')),
            );
          } else if (state.status == PersonalInfoStatus.success) {
           
            if (state.personalInfo.profileImage != null) {
              final authRepository = context.read<AuthRepository>();
              authRepository.updateUserProfile(
                profileImage: state.personalInfo.profileImage!.path,
                gender: state.personalInfo.gender,
                dateOfBirth: state.personalInfo.dateOfBirth,
              );
            }
           
            Navigator.of(context).pushNamed('/allergies');
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFE9B975),
            appBar: AppBar(
              backgroundColor: const Color.fromARGB(0, 167, 10, 10),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 5),
                    // Titre
                    const Center(
                      child: Text(
                        'Good taste !',
                        style: TextStyle(
                          color: Color.fromARGB(
                            255,
                            80,
                            9,
                            4,
                          ), 
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Indicateur de progression
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Row(
                        children: List.generate(
                          4,
                          (index) => Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color:
                                    index == 0
                                        ? const Color(0xFF245536)
                                        : const Color.fromARGB(255, 157, 199, 159),
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                   
                    const Center(
                      child: Text(
                        'Informations personnelles',
                        style: TextStyle(
                          color: Color(0xFFBA3400), 
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Photo de profil
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _selectImage(context),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  state.personalInfo.profileImage != null
                                      ? FileImage(state.personalInfo.profileImage!)
                                      : null,
                              child:
                                  state.personalInfo.profileImage == null
                                      ? const Icon(
                                        Icons.person_outline,
                                        size: 40,
                                        color: Colors.black54,
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextButton(
                            onPressed: () => _selectImage(context),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(40, 25),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Ajouter une photo de profil',
                              style: TextStyle(
                                color: Color(0xFF245536),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Date de naissance
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Date de naissance',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF245536),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          // ignore: use_build_context_synchronously
                          context.read<PersonalInfoBloc>().add(DateOfBirthChanged(picked));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDB9051), 
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              state.personalInfo.dateOfBirth != null
                                  ? DateFormat('dd/MM/yyyy').format(state.personalInfo.dateOfBirth!)
                                  : 'JJ/MM/AAAA',
                              style: TextStyle(
                                color:
                                    state.personalInfo.dateOfBirth != null
                                        ? Colors.black
                                        : Colors.black54,
                                fontSize: 15,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Genre
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Genre',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context.read<PersonalInfoBloc>().add(const GenderChanged('Homme'));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    state.personalInfo.gender == 'Homme'
                                        ? const Color(0xFF245536)
                                        : const Color(0xFFDB9051),
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(30),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (state.personalInfo.gender == 'Homme')
                                    const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Homme',
                                    style: TextStyle(
                                      color:
                                          state.personalInfo.gender == 'Homme'
                                              ? Colors.white
                                              : Colors.black,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context.read<PersonalInfoBloc>().add(const GenderChanged('Femme'));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    state.personalInfo.gender == 'Femme'
                                        ? const Color(0xFF245536)
                                        : const Color(0xFFDB9051),
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(30),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (state.personalInfo.gender == 'Femme')
                                    const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Femme',
                                    style: TextStyle(
                                      color:
                                          state.personalInfo.gender == 'Femme'
                                              ? Colors.white
                                              : Colors.black,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Bouton Suivant
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
                          elevation: 0,
                        ),
                        onPressed: state.status == PersonalInfoStatus.loading
                            ? null
                            : () {
                                context.read<PersonalInfoBloc>().add(const PersonalInfoSubmitted());
                              },
                        child: state.status == PersonalInfoStatus.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Suivant',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}