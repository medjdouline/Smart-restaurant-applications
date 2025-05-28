import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../user_service.dart';

class AssistancePage extends StatefulWidget {
  final String? tableId;
  
  const AssistancePage({Key? key, this.tableId}) : super(key: key);

  @override
  State<AssistancePage> createState() => _AssistancePageState();
}

class _AssistancePageState extends State<AssistancePage> {
  bool _isLoading = false;
  final TextEditingController _tableController = TextEditingController();
  String? _currentTableId;

  @override
  void initState() {
    super.initState();
    _currentTableId = widget.tableId;
    if (_currentTableId != null) {
      _tableController.text = _currentTableId!;
    }
  }

  @override
  void dispose() {
    _tableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistance'),
        backgroundColor: const Color(0xFFB24516),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F1E5),
              Color(0xFFDFB976),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.1),
            
            // Illustration
            Container(
              margin: const EdgeInsets.only(bottom: 40),
              child: const Icon(
                Icons.support_agent,
                size: 80,
                color: Color(0xFFB24516),
              ),
            ),

            // Welcome message
            Text(
              'Bonjour ${userService.nomUtilisateur ?? ''}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB24516),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nous sommes là pour vous aider',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: screenHeight * 0.08),

            // Table number input
            _buildTableNumberInput(),
            
            const SizedBox(height: 30),

            // Main service button - Request server
            _buildMainServiceButton(context, userService),
            
            const Spacer(),
            
            // Info text
            const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Text(
                'Un serveur sera notifié et viendra à votre table',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableNumberInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _tableController,
        keyboardType: TextInputType.number,
        onChanged: (value) {
          _currentTableId = value.trim();
        },
        decoration: InputDecoration(
          labelText: 'Numéro de table',
          hintText: 'Tapez votre numéro de table',
          prefixIcon: const Icon(Icons.table_restaurant, color: Color(0xFFB24516)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMainServiceButton(BuildContext context, UserService userService) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3A5311),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        onPressed: _isLoading ? null : () => _handleAssistanceRequest(context, userService),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search, size: 28),
                  SizedBox(width: 15),
                  Text(
                    "DEMANDER UN SERVEUR",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleAssistanceRequest(BuildContext context, UserService userService) async {
    // Check if user is logged in
    if (!userService.isLoggedIn) {
      _showErrorDialog(context, 'Vous devez être connecté pour demander de l\'assistance');
      return;
    }

    // Check if table number is provided
    if (_currentTableId == null || _currentTableId!.isEmpty) {
      _showErrorDialog(context, 'Veuillez saisir votre numéro de table');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await userService.createAssistanceRequest(_currentTableId!);
      
      if (success) {
        _showSuccessDialog(context);
      } else {
        _showErrorDialog(context, 'Échec de l\'envoi de la demande. Veuillez réessayer.');
      }
    } catch (e) {
      _showErrorDialog(context, 'Une erreur est survenue. Veuillez réessayer.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 60,
                color: Color(0xFF3A5311),
              ),
              const SizedBox(height: 20),
              const Text(
                'Demande envoyée !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Un serveur va venir à la table ${_currentTableId} dans quelques instants.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A5311),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to previous screen
                  },
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                'Erreur',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}