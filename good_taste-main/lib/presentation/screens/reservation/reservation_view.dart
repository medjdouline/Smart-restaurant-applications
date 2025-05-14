import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/reservation/reservation_bloc.dart';
import 'package:intl/intl.dart';

class ReservationView extends StatelessWidget {
  const ReservationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9B975),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFBA3400)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Réservation',
          style: TextStyle(
            color: Color(0xFFBA3400),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ReservationBloc, ReservationState>(
        listener: (context, state) {
          if (state is ReservationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Réservation effectuée avec succès!'),
                backgroundColor: Color(0xFF245536),
              ),
            );
            
         
            Future.delayed(const Duration(seconds: 2), () {
              if (context.mounted) {
                Navigator.pop(context);
              }
            });
          } else if (state is ReservationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ReservationLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFBA3400),
              ),
            );
          }

          if (state is ReservationInitial || state is ReservationError) {
            final ReservationInitial currentState = state is ReservationInitial
                ? state
                : (state as ReservationError).previousState;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Date'),
                    _buildDateSelectorNew(context, currentState),
                    const SizedBox(height: 20),
                    
                    _buildSectionTitle('Heure'),
                    _buildTimeSelector(context, currentState),
                    const SizedBox(height: 20),
                    
                    _buildSectionTitle('Personne'),
                    _buildPeopleCounter(context, currentState),
                    const SizedBox(height: 20),
                    
                    _buildSectionTitle('Table'),
                    _buildTableSelector(context),
                    const SizedBox(height: 40),
                    
                    _buildSubmitButton(context),
                  ],
                ),
              ),
            );
          }
          
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFBA3400),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFFBA3400),
        ),
      ),
    );
  }

  Widget _buildDateSelectorNew(BuildContext context, ReservationInitial state) {
    final String day = DateFormat('dd').format(state.date);
    final String month = DateFormat('MM').format(state.date);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDateField(context, 'J', day[0], true),
          const SizedBox(width: 8),
          _buildDateField(context, 'J', day[1], true),
          
          const SizedBox(width: 16),
          
          _buildDateField(context, 'M', month[0], false),
          const SizedBox(width: 8),
          _buildDateField(context, 'M', month[1], false),
          
          const SizedBox(width: 16),
          
          _buildDateField(context, 'A', '2', false),
          const SizedBox(width: 8),
          _buildDateField(context, 'A', '5', false),
        ],
      ),
    );
  }
  
  Widget _buildDateField(BuildContext context, String label, String value, bool isDay) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _showDatePicker(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: const Color(0xFFDB9051),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.brown,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFBA3400),
              onPrimary: Colors.white,
              surface: Color(0xFFF9D5A7),
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null && context.mounted) {
      context.read<ReservationBloc>().add(DateChanged(pickedDate));
    }
  }

Widget _buildTimeSelector(BuildContext context, ReservationInitial state) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Column(
      children: [
        Row(
          children: [
            
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF245536),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
              onPressed: () {
                context.read<ReservationBloc>().add(ShowCustomTimeSlotDialog());
                _showCustomTimeSlotDialog(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: state.availableTimeSlots.map((timeSlot) {
            final isSelected = timeSlot == state.timeSlot;
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 64) / 3.3,
              child: GestureDetector(
                onTap: () => context.read<ReservationBloc>()
                  .add(TimeSlotSelected(timeSlot)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFBA3400) : const Color(0xFFDB9051),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    timeSlot,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

void _showCustomTimeSlotDialog(BuildContext context) {
  final List<String> validHours = [
    '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '00'
  ];
  
  // Déterminer l'heure actuelle pour filtrer les heures passées si la date est aujourd'hui
  final DateTime now = DateTime.now();
  final ReservationBloc bloc = context.read<ReservationBloc>();
  final bool isToday = bloc.state is ReservationInitial && 
    (bloc.state as ReservationInitial).date.year == now.year && 
    (bloc.state as ReservationInitial).date.month == now.month && 
    (bloc.state as ReservationInitial).date.day == now.day;
  
  // Filtrer les heures valides si c'est aujourd'hui
  List<String> availableHours = validHours;
  if (isToday) {
    availableHours = validHours.where((hour) {
      int hourValue = int.parse(hour == '00' ? '24' : hour);
      return hourValue > now.hour;
    }).toList();
  }
  
  // S'il n'y a plus d'heures disponibles aujourd'hui
  if (availableHours.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Il n\'y a plus d\'horaires disponibles aujourd\'hui. Veuillez sélectionner une autre date.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  // Sélectionner la première heure disponible
  String selectedStartHour = availableHours.first;
  // Calculer l'heure de fin (par défaut +1h)
  int startHourValue = int.parse(selectedStartHour == '00' ? '24' : selectedStartHour);
  int endHourValue = startHourValue + 1;
  String selectedEndHour = endHourValue >= 24 ? '00' : endHourValue.toString();
  
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFF9D5A7),
            title: const Text(
              'Personnaliser l\'horaire',
              style: TextStyle(color: Color(0xFFBA3400)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choisissez votre plage horaire (min 1h, max 2h)',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Début',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        value: selectedStartHour,
                        items: availableHours.map((hour) {
                          return DropdownMenuItem<String>(
                            value: hour,
                            child: Text('${hour}h'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStartHour = value ?? availableHours.first;
                            
                            int start = int.parse(selectedStartHour == '00' ? '24' : selectedStartHour);
                            int end = int.parse(selectedEndHour == '00' ? '24' : selectedEndHour);
                            
                            if (end - start > 2) {
                              int newEnd = start + 2;
                              if (newEnd >= 24) {
                                selectedEndHour = '00';
                              } else {
                                selectedEndHour = newEnd.toString();
                              }
                            } else if (end <= start) {
                              int newEnd = start + 1;
                              if (newEnd >= 24) {
                                selectedEndHour = '00';
                              } else {
                                selectedEndHour = newEnd.toString();
                              }
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('à', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Fin',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        value: selectedEndHour,
                        items: validHours.map((hour) {
                          return DropdownMenuItem<String>(
                            value: hour,
                            child: Text('${hour}h'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedEndHour = value ?? '11';

                            int start = int.parse(selectedStartHour == '00' ? '24' : selectedStartHour);
                            int end = int.parse(selectedEndHour == '00' ? '24' : selectedEndHour);
                            
                            if (end - start > 2) {
                              int newStart = end - 2;
                              if (newStart >= 24) {
                                newStart = 23;
                              }
                              selectedStartHour = newStart.toString();
                            } else if (end <= start) {
                              int newStart = end - 1;
                              // S'assurer que l'heure de début est disponible
                              if (isToday && newStart <= now.hour) {
                                // Trouver la prochaine heure disponible
                                for (String hour in availableHours) {
                                  int hourValue = int.parse(hour == '00' ? '24' : hour);
                                  if (hourValue < end) {
                                    selectedStartHour = hour;
                                    break;
                                  }
                                }
                              } else {
                                selectedStartHour = newStart.toString();
                              }
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Annuler', 
                  style: TextStyle(color: Color(0xFFBA3400)),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF245536),
                ),
                child: const Text('Ajouter'),
                onPressed: () {
                  final String customTimeSlot = '${selectedStartHour}h-${selectedEndHour}h';
                  bloc.add(AddCustomTimeSlot(customTimeSlot));
                  
                  Navigator.of(dialogContext).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Horaire $customTimeSlot ajouté'),
                      backgroundColor: const Color(0xFF245536),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildPeopleCounter(BuildContext context, ReservationInitial state) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF245536),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.remove, color: Colors.white, size: 18),
          ),
          onPressed: state.numberOfPeople > 1
              ? () {
                  context
                      .read<ReservationBloc>()
                      .add(NumberOfPeopleChanged(state.numberOfPeople - 1));
                }
              : null,
        ),
        Text(
          state.numberOfPeople.toString().padLeft(2, '0'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF245536),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 18),
          ),
          onPressed: state.numberOfPeople < 8
              ? () {
                  context
                      .read<ReservationBloc>()
                      .add(NumberOfPeopleChanged(state.numberOfPeople + 1));
                }
              : null,
        ),
      ],
    ),
  );
}

Widget _buildTableSelector(BuildContext context) {
  final ReservationInitial currentState = 
      context.read<ReservationBloc>().state is ReservationInitial
          ? context.read<ReservationBloc>().state as ReservationInitial
          : (context.read<ReservationBloc>().state as ReservationError).previousState;
          
  final String tableDisplay = currentState.tableType.isEmpty 
      ? 'Choisir une table' 
      : 'Table ${currentState.tableType}';
      
  final Color textColor = currentState.tableType.isEmpty 
      ? Colors.black87 
      : const Color(0xFF245536);
  
  final IconData trailingIcon = currentState.tableType.isEmpty 
      ? Icons.arrow_forward_ios 
      : Icons.check_circle;
      
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: currentState.tableType.isNotEmpty ? [
        BoxShadow(
          color: const Color(0xFFBA3400).withAlpha(26), 
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ] : [],
    ),
    child: ListTile(
      title: Text(
        tableDisplay,
        style: TextStyle(
          color: textColor,
          fontWeight: currentState.tableType.isNotEmpty ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Icon(
        trailingIcon,
        color: currentState.tableType.isEmpty ? const Color(0xFFBA3400) : const Color(0xFF245536),
        size: 16,
      ),
      onTap: () async {
        debugPrint('Navigation vers l\'écran de sélection de table');
        debugPrint('État actuel tableType: ${currentState.tableType}');
        
        // Naviguer vers table screen avec les arguments requis
        final result = await Navigator.pushNamed(
          context,
          '/table',
          arguments: {
            'reservationDate': currentState.date,
            'reservationTimeSlot': currentState.timeSlot.isNotEmpty 
                ? currentState.timeSlot 
                : '12h-13h', 
            'numberOfPeople': currentState.numberOfPeople,
          },
        );
        
        debugPrint('Résultat reçu de l\'écran de table: $result');
        
        if (result != null && result is String && context.mounted) {
          debugPrint('Mise à jour du type de table: $result');
          context.read<ReservationBloc>().add(TableTypeSelected(result));
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Table $result sélectionnée'),
              backgroundColor: const Color(0xFF245536),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
    ),
  );
}

Widget _buildSubmitButton(BuildContext context) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFF245536),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF245536).withAlpha(100), 
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          final currentState = context.read<ReservationBloc>().state;
          if (currentState is ReservationInitial) {
            if (currentState.timeSlot.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veuillez sélectionner un horaire'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            if (currentState.tableType.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veuillez sélectionner une table'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            context.read<ReservationBloc>().add(SubmitReservation());
          }
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Enregistrer',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}
}