import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:good_taste/data/repositories/reservation_repository.dart';

class TableScreen extends StatefulWidget {
  final DateTime reservationDate;
  final String reservationTimeSlot;
  final int numberOfPeople;

  const TableScreen({
    super.key, 
    required this.reservationDate,
    required this.reservationTimeSlot,
    required this.numberOfPeople,
  });

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  int? selectedTableId;
  bool isLoading = true;
  List<String> availableTables = [];
  String? suggestedTable;

  @override
  void initState() {
    super.initState();
    _loadAvailableTables();
  }

 Future<void> _loadAvailableTables() async {
  setState(() {
    isLoading = true;
  });

  // Récupérer le repository de réservation
  final reservationRepository = ReservationRepository();
  
  // Charger les tables disponibles pour le créneau horaire sélectionné
  final tables = await reservationRepository.getAvailableTables(
    widget.reservationDate,
    widget.reservationTimeSlot,
    widget.numberOfPeople
  );
  
  // Suggérer une table si aucune n'est disponible
  String? suggested;
  if (tables.isEmpty) {
    suggested = await reservationRepository.suggestAlternativeTable(
      widget.reservationDate,
      widget.reservationTimeSlot,
      widget.numberOfPeople
    );
  }
  
  setState(() {
    availableTables = tables;
    suggestedTable = suggested;
    isLoading = false;
    
    // Réinitialiser la table sélectionnée si elle n'est plus disponible
    if (selectedTableId != null && !availableTables.contains(selectedTableId.toString())) {
      selectedTableId = null;
    }
  });
  
  // Si une suggestion est disponible, afficher une alerte
  if (suggestedTable != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSuggestionDialog();
    });
  }
}
  void _showSuggestionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggestion de table'),
        content: Text('Aucune table n\'est disponible pour votre réservation. Nous vous suggérons la table $suggestedTable qui est disponible à l\'horaire demandé.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedTableId = int.parse(suggestedTable!);
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF245536),
            ),
            child: const Text(
              'Accepter',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

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
          iconSize: 24,
        ),
        title: const Text(
          'Table',
          style: TextStyle(
            color: Color(0xFFBA3400),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFBA3400),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Ajouter un message si aucune table n'est disponible
                  if (availableTables.isEmpty && suggestedTable == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'Aucune table disponible pour cette réservation.',
                        style: TextStyle(
                          color: Color(0xFFBA3400),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Tables 1-3
                          _buildSquareTableRow([1, 2, 3]),
                          const SizedBox(height: 30),

                          // Tables 4-6
                          _buildSquareTableRow([4, 5, 6]),
                          const SizedBox(height: 30),

                          // Tables 7-9
                          _buildRectangularTableRow([7, 8, 9]),
                          const SizedBox(height: 30),

                          // Tables 10-11
                          _buildLargeTableRow([10, 11]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildConfirmButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  bool _isTableAvailable(int tableId) {
    return availableTables.contains(tableId.toString());
  }
  
  // Méthode pour construire une rangée de tables carrées
  Widget _buildSquareTableRow(List<int> tableIds) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: tableIds.map((tableId) => _buildSquareTable(tableId)).toList(),
    );
  }
  
  // Méthode pour construire une rangée de tables rectangulaires
  Widget _buildRectangularTableRow(List<int> tableIds) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: tableIds.map((tableId) => _buildSideChairTable(tableId)).toList(),
    );
  }
  
  // Méthode pour construire une rangée de grandes tables
  Widget _buildLargeTableRow(List<int> tableIds) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: tableIds.map((tableId) => _buildLargeTable(tableId)).toList(),
    );
  }

  Widget _buildSquareTable(int tableId) {
    final bool isSelected = selectedTableId == tableId;
    final bool isAvailable = _isTableAvailable(tableId);
    const double tableSize = 60.0;

    return GestureDetector(
      onTap: isAvailable
          ? () {
              setState(() {
                selectedTableId = tableId;
              });
            }
          : null, // Désactiver le tap si la table n'est pas disponible
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.5, // Grisé si non disponible
        child: Column(
          children: [
            // Chaises du haut
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChair(width: 20, height: 6),
                const SizedBox(width: 6),
                _buildChair(width: 20, height: 6),
              ],
            ),
            const SizedBox(height: 4),

            // Table
            Container(
              width: tableSize,
              height: tableSize,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFDB9051)
                    : isAvailable 
                        ? const Color(0xFFF9D5A7)
                        : Colors.grey[400], // Grisé si non disponible
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFFBA3400) 
                      : isAvailable 
                          ? Colors.black26 
                          : Colors.grey[600]!, // Bordure grisée si non disponible
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  tableId.toString(),
                  style: TextStyle(
                    color: isSelected 
                        ? const Color(0xFFBA3400) 
                        : isAvailable 
                            ? Colors.black54 
                            : Colors.grey[600], // Texte grisé si non disponible
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Chaises du bas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChair(width: 20, height: 6),
                const SizedBox(width: 6),
                _buildChair(width: 20, height: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChair({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
    );
  }

  Widget _buildSideChairTable(int tableId) {
    final bool isSelected = selectedTableId == tableId;
    final bool isAvailable = _isTableAvailable(tableId);
    const double tableWidth = 50.0;
    const double tableHeight = 70.0;

    return GestureDetector(
      onTap: isAvailable
          ? () {
              setState(() {
                selectedTableId = tableId;
              });
            }
          : null, // Désactiver le tap si la table n'est pas disponible
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.5, // Grisé si non disponible
        child: SizedBox(
          width: 80,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Table
              Container(
                width: tableWidth,
                height: tableHeight,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFDB9051)
                      : isAvailable 
                          ? const Color(0xFFF9D5A7)
                          : Colors.grey[400], // Grisé si non disponible
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFFBA3400) 
                        : isAvailable 
                            ? Colors.black26 
                            : Colors.grey[600]!, // Bordure grisée si non disponible
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    tableId.toString(),
                    style: TextStyle(
                      color: isSelected 
                          ? const Color(0xFFBA3400) 
                          : isAvailable 
                              ? Colors.black54 
                              : Colors.grey[600], // Texte grisé si non disponible
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              // Chaises à gauche
              Positioned(
                left: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildChair(width: 6, height: 20),
                    const SizedBox(height: 6),
                    _buildChair(width: 6, height: 20),
                    const SizedBox(height: 6),
                    _buildChair(width: 6, height: 20),
                  ],
                ),
              ),

              // Chaises à droite
              Positioned(
                right: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildChair(width: 6, height: 20),
                    const SizedBox(height: 6),
                    _buildChair(width: 6, height: 20),
                    const SizedBox(height: 6),
                    _buildChair(width: 6, height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeTable(int tableId) {
    final bool isSelected = selectedTableId == tableId;
    final bool isAvailable = _isTableAvailable(tableId);
    const double width = 140.0;
    const double height = 40.0;

    return GestureDetector(
      onTap: isAvailable
          ? () {
              setState(() {
                selectedTableId = tableId;
              });
            }
          : null, // Désactiver le tap si la table n'est pas disponible
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.5, // Grisé si non disponible
        child: Column(
          children: [
            // Chaises du haut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildChair(width: 20, height: 6),
                _buildChair(width: 20, height: 6),
                _buildChair(width: 20, height: 6),
                _buildChair(width: 20, height: 6),
              ],
            ),
            const SizedBox(height: 4),

            // Table
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFDB9051)
                    : isAvailable 
                        ? const Color(0xFFF9D5A7)
                        : Colors.grey[400], // Grisé si non disponible
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFFBA3400) 
                      : isAvailable 
                          ? Colors.black26 
                          : Colors.grey[600]!, // Bordure grisée si non disponible
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  tableId.toString(),
                  style: TextStyle(
                    color: isSelected 
                        ? const Color(0xFFBA3400) 
                        : isAvailable 
                            ? Colors.black54 
                            : Colors.grey[600], // Texte grisé si non disponible
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Chaises du bas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildChair(width: 20, height: 6),
                _buildChair(width: 20, height: 6),
                _buildChair(width: 20, height: 6),
                _buildChair(width: 20, height: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final bool isEnabled = selectedTableId != null && _isTableAvailable(selectedTableId!);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        height: 45,
        decoration: BoxDecoration(
          color: isEnabled 
              ? const Color(0xFF245536) 
              : const Color(0xFF245536).withAlpha(128), 
          borderRadius: BorderRadius.circular(20),
          boxShadow: isEnabled ? [
            BoxShadow(
              color: const Color(0xFF245536).withAlpha(100),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ] : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: isEnabled
                ? () {
                    HapticFeedback.mediumImpact();
                    
                    if (selectedTableId != null) {
                      debugPrint('Table $selectedTableId sélectionnée, retour à l\'écran précédent');
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Table $selectedTableId sélectionnée'),
                          backgroundColor: const Color(0xFF245536),
                          duration: const Duration(milliseconds: 500),
                        ),
                      );
                      
                      Navigator.pop(context, selectedTableId.toString());
                    }
                  }
                : null,
            child: Center(
              child: Text(
                'Confirmer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}