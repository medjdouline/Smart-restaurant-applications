import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/allergies/allergies_bloc.dart';
import 'package:good_taste/logic/blocs/allergies/allergies_event.dart';
import 'package:good_taste/logic/blocs/allergies/allergies_state.dart';

class AllergiesScreen extends StatefulWidget {
  const AllergiesScreen({super.key});

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  final TextEditingController _customAllergyController = TextEditingController();
  final List<String> _customAllergies = [];

  
  final List<String> _commonAllergies = [
    'Fraise', 'Fruit exotique', 'Gluten', 'Arachides', 'Noix', 'Lupin', 
    'Champignons', 'Moutarde', 'Soja', 'Crustacés', 'Poisson', 'Lactose', 'Œufs'
  ];

  @override
  void initState() {
    super.initState();
  
    context.read<AllergiesBloc>().add(const AllergiesLoaded());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncCustomAllergies();
  }

  void _syncCustomAllergies() {
    final state = context.read<AllergiesBloc>().state;
    List<String> newCustomAllergies = [];
    
    for (var allergy in state.selectedAllergies) {
      if (!_commonAllergies.contains(allergy) && !_customAllergies.contains(allergy)) {
        newCustomAllergies.add(allergy);
      }
    }
    
    if (newCustomAllergies.isNotEmpty) {
      setState(() {
        _customAllergies.addAll(newCustomAllergies);
      });
    }
  }

  @override
  void dispose() {
    _customAllergyController.dispose();
    super.dispose();
  }

  void _addCustomAllergy(BuildContext context) {
    final text = _customAllergyController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _customAllergies.add(text);
        _customAllergyController.clear();
      });
      
      context.read<AllergiesBloc>().add(AllergyToggled(text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AllergiesBloc, AllergiesState>(
      listener: (context, state) {
        if (state.status == AllergiesStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Une erreur est survenue')),
          );
        } else if (state.status == AllergiesStatus.success) {
          Navigator.of(context).pushNamed('/regime');
        }
      },
      builder: (context, state) {
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
              child: ListView(
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
                              color: index <= 1
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
                      'Quelles allergies as-tu ?',
                      style: TextStyle(
                        color:  Color(0xFFBA3400), 
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                 
                  if (_customAllergies.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._customAllergies.map((allergy) => _buildCustomAllergyChip(context, allergy, state)),
                      ],
                    ),
                  
                  if (_customAllergies.isNotEmpty)
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
                            color:  Color(0xFF245536),
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
                  
                  const SizedBox(height: 20),
                  
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildAllergyChip(context, 'Fraise', state),
                      _buildAllergyChip(context, 'Fruit exotique', state),
                      _buildAllergyChip(context, 'Gluten', state),
                      _buildAllergyChip(context, 'Arachides', state),
                      _buildAllergyChip(context, 'Noix', state),
                      _buildAllergyChip(context, 'Lupin', state),
                      _buildAllergyChip(context, 'Champignons', state),
                      _buildAllergyChip(context, 'Moutarde', state),
                      _buildAllergyChip(context, 'Soja', state),
                      _buildAllergyChip(context, 'Crustacés', state),
                      _buildAllergyChip(context, 'Poisson', state),
                      _buildAllergyChip(context, 'Lactose', state),
                      _buildAllergyChip(context, 'Œufs', state),
                    ],
                  ),
                  
                 
                  const SizedBox(height: 100),
                  
                  // Bouton suivant
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
                      onPressed: state.status == AllergiesStatus.loading
                          ? null
                          : () {
                              context.read<AllergiesBloc>().add(const AllergiesSubmitted());
                            },
                      child: state.status == AllergiesStatus.loading
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
    );
  }

  Widget _buildAllergyChip(
    BuildContext context,
    String allergy,
    AllergiesState state,
  ) {
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
  }
  
  Widget _buildCustomAllergyChip(
    BuildContext context,
    String allergy,
    AllergiesState state,
  ) {
    final isSelected = state.selectedAllergies.contains(allergy);
    
    return InkWell(
      onTap: () {
        context.read<AllergiesBloc>().add(AllergyToggled(allergy));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBA3400) : const Color(0xFFDB9051),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              allergy,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 5),
            InkWell(
              onTap: () {
                setState(() {
                  _customAllergies.remove(allergy);
                });
                context.read<AllergiesBloc>().add(AllergyToggled(allergy));
              },
              child: Icon(
                Icons.close,
                size: 16,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}