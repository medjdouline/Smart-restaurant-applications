import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/allergies/allergies_bloc.dart';
import 'package:good_taste/logic/blocs/allergies/allergies_event.dart';
import 'package:good_taste/logic/blocs/allergies/allergies_state.dart';
import 'package:good_taste/logic/blocs/regime/regime_bloc.dart';
import 'package:good_taste/logic/blocs/regime/regime_event.dart';
import 'package:good_taste/logic/blocs/regime/regime_state.dart';
import 'package:good_taste/di/di.dart';

class PreferenceDetailScreen extends StatefulWidget {
  const PreferenceDetailScreen({super.key});

  @override
  State<PreferenceDetailScreen> createState() => _PreferenceDetailScreenState();
}

class _PreferenceDetailScreenState extends State<PreferenceDetailScreen> {
  final TextEditingController _customAllergyController = TextEditingController();
  final TextEditingController _customRegimeController = TextEditingController();
  bool _isAllergiesExpanded = false;
  bool _isRegimesExpanded = false;

  final List<String> _commonAllergies = [
    'Gluten', 'Arachides', 'Noix', 'Lupin', 'Champignons', 'Fraise',
    'Soja', 'Crustacés', 'Poisson', 'Lactose', 'Œufs', 'Moutarde',
    'Fruits exotiques'
  ];

  final List<String> _commonRegimes = [
    'Végétarien', 'Végétalien', 'Keto', 'Sans lactose', 'Sans gluten'
  ];

  @override
  void dispose() {
    _customAllergyController.dispose();
    _customRegimeController.dispose();
    super.dispose();
  }

  void _addCustomAllergy(BuildContext context) {
    final text = _customAllergyController.text.trim();
    if (text.isNotEmpty) {
      context.read<AllergiesBloc>().add(AllergyToggled(text));
      _customAllergyController.clear();
    }
  }

  void _addCustomRegime(BuildContext context) {
    final text = _customRegimeController.text.trim();
    if (text.isNotEmpty) {
      context.read<RegimeBloc>().add(RegimeToggled(text));
      _customRegimeController.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<AllergiesBloc>().add(const AllergiesLoaded());
    context.read<RegimeBloc>().add(const RegimesLoaded());
  }

  @override
  Widget build(BuildContext context) {
return MultiBlocProvider(
providers: [
  BlocProvider(
    create: (context) => AllergiesBloc(
      allergiesRepository: DependencyInjection.getAllergiesRepository(),
      authRepository: DependencyInjection.getAuthRepository(),
    ),
  ),
  BlocProvider(
    create: (context) => RegimeBloc(
      regimeRepository: DependencyInjection.getRegimeRepository(),
      authRepository: DependencyInjection.getAuthRepository(),
    ),
  ),
  ],
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
          child: MultiBlocListener(
            listeners: [
              BlocListener<AllergiesBloc, AllergiesState>(
                listenWhen: (previous, current) => 
                  previous.status != current.status && current.status == AllergiesStatus.success,
                listener: (context, state) {
                  if (state.status == AllergiesStatus.success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Préférences enregistrées avec succès !'),
                        backgroundColor: Color(0xFF245536),
                      ),
                    );
                  }
                },
              ),
              BlocListener<RegimeBloc, RegimeState>(
                listenWhen: (previous, current) => 
                  previous.status != current.status && current.status == RegimeStatus.failure,
                listener: (context, state) {
                  if (state.status == RegimeStatus.failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage ?? 'Une erreur est survenue'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
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
                    _buildSectionTitle('Mes régimes alimentaire'),
                    const SizedBox(height: 10),
                    _buildRegimesSection(),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: BlocBuilder<AllergiesBloc, AllergiesState>(
                        buildWhen: (previous, current) => previous.status != current.status,
                        builder: (context, allergiesState) {
                          return BlocBuilder<RegimeBloc, RegimeState>(
                            buildWhen: (previous, current) => previous.status != current.status,
                            builder: (context, regimeState) {
                              final isLoading = allergiesState.status == AllergiesStatus.loading || 
                                               regimeState.status == RegimeStatus.loading;
                              
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF245536),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                ),
                                onPressed: isLoading 
                                  ? null 
                                  : () {
                                      context.read<AllergiesBloc>().add(const AllergiesSubmitted());
                                      context.read<RegimeBloc>().add(const RegimeSubmitted());
                                      Future.delayed(const Duration(seconds: 1), () {
                                        if (mounted) {
                                          Navigator.of(context).pop();
                                        }
                                      });
                                    },
                                child: isLoading 
                                  ? const SizedBox(
                                      height: 20, 
                                      width: 20, 
                                      child: CircularProgressIndicator(color: Colors.white))
                                  : const Text('Enregistrer', style: TextStyle(fontSize: 16)),
                              );
                            },
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
    return BlocBuilder<AllergiesBloc, AllergiesState>(
      builder: (context, state) {
        return Column(
          children: [
         
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
                              _isRegimesExpanded = false;
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
                                  context.read<AllergiesBloc>().add(AllergyToggled(item));
                                },
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          
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
                      "Si vous avez d'autre allergies mentionnez les ici !",
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                   
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
                  
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _commonAllergies.map((allergy) {
                        final isSelected = state.selectedAllergies.contains(allergy);
                        return InkWell(
                          onTap: () {
                            context.read<AllergiesBloc>().add(AllergyToggled(allergy));
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

  Widget _buildRegimesSection() {
    return BlocBuilder<RegimeBloc, RegimeState>(
      builder: (context, state) {
        return Column(
          children: [
           
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
                            _isRegimesExpanded = !_isRegimesExpanded;
                            
                            if (_isRegimesExpanded) {
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
                            _isRegimesExpanded ? Icons.remove : Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (state.selectedRegimes.isEmpty)
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
                      children: state.selectedRegimes
                          .map((item) => _buildDeletableChip(
                                item,
                                onDelete: () {
                                  context.read<RegimeBloc>().add(RegimeToggled(item));
                                },
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
            
           
            if (_isRegimesExpanded)
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
                      "Si vous avez d'autre régime alimentaire mentionnez les ici !",
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Custom regime input
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
                              controller: _customRegimeController,
                              decoration: const InputDecoration(
                                hintText: 'Entrez un régime alimentaire',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                              ),
                              onSubmitted: (_) => _addCustomRegime(context),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFBA3400),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add, color: Colors.white, size: 20),
                              onPressed: () => _addCustomRegime(context),
                              padding: const EdgeInsets.all(0),
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Common regimes
                    ...List.generate(_commonRegimes.length, (index) {
                      final regime = _commonRegimes[index];
                      final isSelected = state.selectedRegimes.contains(regime);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          onTap: () {
                            context.read<RegimeBloc>().add(RegimeToggled(regime));
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFBA3400) : Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              regime,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    
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