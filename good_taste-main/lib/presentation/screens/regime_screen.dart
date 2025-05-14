import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/regime/regime_bloc.dart';
import 'package:good_taste/logic/blocs/regime/regime_event.dart';
import 'package:good_taste/logic/blocs/regime/regime_state.dart';

class RegimeScreen extends StatefulWidget {
  const RegimeScreen({super.key});

  @override
  State<RegimeScreen> createState() => _RegimeScreenState();
}

class _RegimeScreenState extends State<RegimeScreen> {
  final TextEditingController _customRegimeController = TextEditingController();
  
  final List<String> _predefinedRegimes = [
    'Végétarien', 'Végétalien', 'Keto', 'Sans lactose', 'Sans gluten'
  ];

  @override
  void dispose() {
    _customRegimeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
   
    context.read<RegimeBloc>().add(const RegimesLoaded());
  }

  void _addCustomRegime(BuildContext context) {
    final text = _customRegimeController.text.trim();
    if (text.isNotEmpty) {
      context.read<RegimeBloc>().add(RegimeToggled(text));
      _customRegimeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
   
    return BlocConsumer<RegimeBloc, RegimeState>(
      listener: (context, state) {
        if (state.status == RegimeStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Une erreur est survenue')),
          );
        } else if (state.status == RegimeStatus.success) {
          Navigator.of(context).pushNamed('/preference');
        }
      },
      builder: (context, state) {
        List<String> customRegimes = state.selectedRegimes
            .where((regime) => !_predefinedRegimes.contains(regime))
            .toList();
     
        List<String> allRegimes = [..._predefinedRegimes, ...customRegimes];

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
                              color: index <= 2
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
                      'Quel est ton régime alimentaire ?',
                      style: TextStyle(
                        color: Color(0xFFBA3400), 
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                 
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
                              hintText: 'Précisez votre régime',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10),
                            ),
                            onSubmitted: (_) => _addCustomRegime(context),
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF245536),
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
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ...allRegimes.map((regime) {
                            
                            if (!_predefinedRegimes.contains(regime)) {
                              return Column(
                                children: [
                                  _buildCustomRegimeOption(context, regime, state),
                                  const SizedBox(height: 10),
                                ]
                              );
                            } else {
                              return Column(
                                children: [
                                  _buildRegimeOption(context, regime, state),
                                  const SizedBox(height: 10),
                                ]
                              );
                            }
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  
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
                      onPressed: state.status == RegimeStatus.loading
                          ? null
                          : () {
                              context.read<RegimeBloc>().add(const RegimeSubmitted());
                            },
                      child: state.status == RegimeStatus.loading
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

  Widget _buildRegimeOption(
    BuildContext context,
    String regime,
    RegimeState state,
  ) {
    final isSelected = state.selectedRegimes.contains(regime);
    
    return InkWell(
      onTap: () {
        context.read<RegimeBloc>().add(RegimeToggled(regime));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBA3400) : Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          regime,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCustomRegimeOption(
    BuildContext context,
    String regime,
    RegimeState state,
  ) {
    final isSelected = state.selectedRegimes.contains(regime);
    
    return InkWell(
      onTap: () {
        context.read<RegimeBloc>().add(RegimeToggled(regime));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBA3400) : Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              regime,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            // Icône de suppression
            InkWell(
              onTap: () {
                
                if (isSelected) {
                  context.read<RegimeBloc>().add(RegimeToggled(regime));
                }
               
                context.read<RegimeBloc>().add(RegimeToggled(regime));
              },
              child: Icon(
                Icons.close,
                size: 18,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}