import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/preference/preference_bloc.dart';
import 'package:good_taste/logic/blocs/preference/preference_event.dart';
import 'package:good_taste/logic/blocs/preference/preference_state.dart';
import 'package:good_taste/data/repositories/preferences_repository.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';

class PreferenceScreen extends StatelessWidget {
  const PreferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PreferenceBloc(
        preferencesRepository: RepositoryProvider.of<PreferencesRepository>(context),
        authRepository: RepositoryProvider.of<AuthRepository>(context),
      ),
      child: BlocConsumer<PreferenceBloc, PreferenceState>(
        listener: (context, state) {
          if (state.status == PreferenceStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Une erreur est survenue')),
            );
          } else if (state.status == PreferenceStatus.success) {
            
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/felicitation', 
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          
          final List<String> preferences = [
            'Soupes et Potages',
            'Salades et Crudités',
            'Poissons et Fruit de mers',
            'Cuisine traditionnelle',
            'Viandes',
            'Sandwichs et burgers',
            'Végétariens',
            'Crémes et Mousses',
            'Pâtisseries',
            'Fruits et Sorbets',
          ];

          
          final bool hasSelectedPreferences = state.selectedPreferences.isNotEmpty;

          return Scaffold(
            backgroundColor: const Color(0xFFE9B975), 
            appBar: AppBar(
              backgroundColor: Colors.transparent,
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
                          color: Color.fromARGB(255, 80, 9, 4),
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
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
                                color: const Color(0xFF245536),
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
                        'Dites-nous ce que vous aimez !',
                        style: TextStyle(
                          color:  Color(0xFFBA3400), 
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    Center(
                      child: Text(
                        'Sélectionnez au moins une préférence',
                        style: TextStyle(
                          color: hasSelectedPreferences ? Colors.transparent : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.5,
                        children: preferences.map((preference) {
                          final isSelected = state.selectedPreferences.contains(preference);
                          return _buildPreferenceButton(context, preference, isSelected);
                        }).toList(),
                      ),
                    ),
                    
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF245536), 
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF245536), 
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 0,
                        ),
                        onPressed: (state.status == PreferenceStatus.loading || !hasSelectedPreferences)
                            ? null 
                            : () {
                                context.read<PreferenceBloc>().add(const PreferenceSubmitted());
                              },
                        child: state.status == PreferenceStatus.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Terminer',
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.w500,
                                  color: hasSelectedPreferences ? Colors.white : Colors.grey.shade200,
                                ),
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

  Widget _buildPreferenceButton(BuildContext context, String preference, bool isSelected) {
    return InkWell(
      onTap: () {
        context.read<PreferenceBloc>().add(PreferenceToggled(preference));
      },
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBA3400) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFC17D50),
            width: 1,
          ),
        ),
        child: Text(
          preference,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}