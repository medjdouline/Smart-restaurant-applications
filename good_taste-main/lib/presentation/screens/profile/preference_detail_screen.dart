import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/profile/profile_bloc.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/data/repositories/profile_repository.dart';
import 'package:good_taste/data/repositories/allergies_repository.dart';
import 'package:good_taste/data/repositories/regime_repository.dart';
import 'package:good_taste/di/di.dart';
import 'package:formz/formz.dart';

class PreferenceDetailScreen extends StatefulWidget {
  const PreferenceDetailScreen({super.key});

  @override
  State<PreferenceDetailScreen> createState() => _PreferenceDetailScreenState();
}

class _PreferenceDetailScreenState extends State<PreferenceDetailScreen> {
  final TextEditingController _customAllergyController = TextEditingController();
  final TextEditingController _customRestrictionController = TextEditingController();
  bool _isAllergiesExpanded = false;
  bool _isRestrictionsExpanded = false;
  bool _isSaving = false; // Flag to track saving state

  final List<String> _commonAllergies = [
    'Gluten', 'Arachides', 'Noix', 'Lupin', 'Champignons', 'Fraise',
    'Soja', 'Crustacés', 'Poisson', 'Lactose', 'Œufs', 'Moutarde',
    'Fruits exotiques'
  ];

  final List<String> _commonRestrictions = [
    'Végétarien', 'Végétalien', 'Keto', 'Sans lactose', 'Sans gluten'
  ];

  late ProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();
    
    // Initialize ProfileBloc with dependencies
    _profileBloc = ProfileBloc(
      authRepository: DependencyInjection.getAuthRepository(),
      profileRepository: DependencyInjection.getProfileRepository(),
      allergiesRepository: DependencyInjection.getAllergiesRepository(),
      regimeRepository: DependencyInjection.getRegimeRepository(), // Add this
    );
    
    // Load profile data, allergies, and restrictions
    _profileBloc.add(ProfileLoaded());
    _profileBloc.add(ProfileAllergiesLoaded());
    _profileBloc.add(ProfileRestrictionsLoaded()); // Load restrictions via ProfileBloc
  }

  @override
  void dispose() {
    _customAllergyController.dispose();
    _customRestrictionController.dispose();
    _profileBloc.close();
    super.dispose();
  }

  void _addCustomAllergy(BuildContext context) {
    final text = _customAllergyController.text.trim();
    if (text.isNotEmpty) {
      _profileBloc.add(ProfileAllergyToggled(text));
      _customAllergyController.clear();
    }
  }

  void _addCustomRestriction(BuildContext context) {
    final text = _customRestrictionController.text.trim();
    if (text.isNotEmpty) {
      _profileBloc.add(ProfileRestrictionToggled(text));
      _customRestrictionController.clear();
    }
  }

  void _savePreferences() {
    setState(() {
      _isSaving = true; // Set saving flag
    });
    
    // Save both allergies and restrictions via ProfileBloc
    _profileBloc.add(ProfileAllergiesSubmitted());
    _profileBloc.add(ProfileRestrictionsSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>.value(
      value: _profileBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFE9B975),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFBA3400)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Mes préférences', style: TextStyle(color: Color(0xFFBA3400))),
        ),
        body: SafeArea(
          child: BlocListener<ProfileBloc, ProfileState>(
            listenWhen: (previous, current) => 
              previous.allergiesStatus != current.allergiesStatus ||
              previous.restrictionsStatus != current.restrictionsStatus,
            listener: (context, state) {
              // Only handle status changes when we're actually saving
              if (!_isSaving) return;
              
              // Handle allergies status changes
              if (state.allergiesStatus == AllergiesLoadingStatus.failure) {
                setState(() {
                  _isSaving = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.allergiesErrorMessage ?? 'Erreur lors de la sauvegarde des allergies'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              
              // Handle restrictions status changes
              if (state.restrictionsStatus == RestrictionsLoadingStatus.failure) {
                setState(() {
                  _isSaving = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.restrictionsErrorMessage ?? 'Erreur lors de la sauvegarde des régimes'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              
              // Check if both saved successfully (only when saving)
              if (state.allergiesStatus == AllergiesLoadingStatus.success && 
                  state.restrictionsStatus == RestrictionsLoadingStatus.success) {
                setState(() {
                  _isSaving = false;
                });
                
                // Both saved successfully
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Préférences enregistrées avec succès !'),
                    backgroundColor: Color(0xFF245536),
                  ),
                );
                
                // Navigate back after a short delay
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                });
              }
            },
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
               
                    _buildSectionTitle('Mes allergies'),
                    const SizedBox(height: 10),
                    _buildAllergiesSection(),
                    const SizedBox(height: 30),

                    _buildSectionTitle('Mes régimes alimentaires'),
                    const SizedBox(height: 10),
                    _buildRestrictionsSection(), // Updated method name
                    const SizedBox(height: 30),
            
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: BlocBuilder<ProfileBloc, ProfileState>(
                        buildWhen: (previous, current) => 
                          previous.allergiesStatus != current.allergiesStatus ||
                          previous.restrictionsStatus != current.restrictionsStatus ||
                          previous.hasAllergiesChanged != current.hasAllergiesChanged ||
                          previous.hasRestrictionsChanged != current.hasRestrictionsChanged,
                        builder: (context, profileState) {
                          final isLoading = _isSaving && (
                            profileState.allergiesStatus == AllergiesLoadingStatus.loading ||
                            profileState.restrictionsStatus == RestrictionsLoadingStatus.loading
                          );
                          
                          final hasChanges = profileState.hasAllergiesChanged || profileState.hasRestrictionsChanged;
                          
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasChanges ? const Color(0xFF245536) : Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            onPressed: (isLoading || !hasChanges) ? null : _savePreferences,
                            child: isLoading 
                              ? const SizedBox(
                                  height: 20, 
                                  width: 20, 
                                  child: CircularProgressIndicator(color: Colors.white)
                                )
                              : const Text('Enregistrer', style: TextStyle(fontSize: 16)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFBA3400),
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildAllergiesSection() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) => 
        previous.selectedAllergies != current.selectedAllergies ||
        previous.allergiesStatus != current.allergiesStatus,
      builder: (context, state) {
        if (state.allergiesStatus == AllergiesLoadingStatus.loading && !_isSaving) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Column(
          children: [
            // Main allergies display container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    offset: const Offset(0, 2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isAllergiesExpanded = !_isAllergiesExpanded;
                            
                            if (_isAllergiesExpanded) {
                              _isRestrictionsExpanded = false;
                            }
                          });
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF245536),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isAllergiesExpanded ? Icons.remove : Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (state.selectedAllergies.isEmpty)
                    const Text(
                      'Aucune préférence sélectionnée',
                      style: TextStyle(
                        color: Color.fromARGB(255, 85, 161, 81),
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.selectedAllergies
                          .map((item) => _buildDeletableChip(
                                item,
                                onDelete: () {
                                  _profileBloc.add(ProfileAllergyToggled(item));
                                },
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          
            // Expanded allergies selection
            if (_isAllergiesExpanded)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13), 
                      offset: const Offset(0, 2),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Si vous avez d'autres allergies mentionnez les ici !",
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Custom allergy input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDB9051).withAlpha(179),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customAllergyController,
                              decoration: const InputDecoration(
                                hintText: 'Entrez une allergie',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                              ),
                              onSubmitted: (_) => _addCustomAllergy(context),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFBA3400),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add, color: Colors.white, size: 20),
                              onPressed: () => _addCustomAllergy(context),
                              padding: const EdgeInsets.all(0),
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                  
                    // Common allergies selection
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _commonAllergies.map((allergy) {
                        final isSelected = state.selectedAllergies.contains(allergy);
                        return InkWell(
                          onTap: () {
                            _profileBloc.add(ProfileAllergyToggled(allergy));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFBA3400) : Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              allergy,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRestrictionsSection() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) => 
        previous.selectedRestrictions != current.selectedRestrictions ||
        previous.restrictionsStatus != current.restrictionsStatus,
      builder: (context, state) {
        if (state.restrictionsStatus == RestrictionsLoadingStatus.loading && !_isSaving) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Column(
          children: [
            // Main restrictions display container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    offset: const Offset(0, 2),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isRestrictionsExpanded = !_isRestrictionsExpanded;
                            
                            if (_isRestrictionsExpanded) {
                              _isAllergiesExpanded = false;
                            }
                          });
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF245536),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isRestrictionsExpanded ? Icons.remove : Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (state.selectedRestrictions.isEmpty)
                    const Text(
                      'Aucune préférence sélectionnée',
                      style: TextStyle(
                        color: Color.fromARGB(255, 85, 161, 81),
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.selectedRestrictions
                          .map((item) => _buildDeletableChip(
                                item,
                                onDelete: () {
                                  _profileBloc.add(ProfileRestrictionToggled(item));
                                },
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
            
            // Expanded restrictions selection
            if (_isRestrictionsExpanded)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13), 
                      offset: const Offset(0, 2),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Si vous avez d'autres régimes alimentaires mentionnez les ici !",
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Custom restriction input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDB9051).withAlpha(179),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customRestrictionController,
                              decoration: const InputDecoration(
                                hintText: 'Entrez un régime alimentaire',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                              ),
                              onSubmitted: (_) => _addCustomRestriction(context),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFBA3400),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add, color: Colors.white, size: 20),
                              onPressed: () => _addCustomRestriction(context),
                              padding: const EdgeInsets.all(0),
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Common restrictions selection
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _commonRestrictions.map((restriction) {
                        final isSelected = state.selectedRestrictions.contains(restriction);
                        return InkWell(
                          onTap: () {
                            _profileBloc.add(ProfileRestrictionToggled(restriction));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFBA3400) : Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              restriction,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDeletableChip(String label, {required VoidCallback onDelete}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFBA3400),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}