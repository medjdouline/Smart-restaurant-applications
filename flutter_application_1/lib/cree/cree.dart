import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConfirmationPage extends StatelessWidget {
  const ConfirmationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFB976),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDFB976),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D552C)),
          onPressed: () {
            // Option 1 : Retour simple (si la page précédente est bien preferences.dart)
            Navigator.pop(context); 

            // Option 2 : Retour forcé vers '/preferences' (si la navigation est complexe)
            // Navigator.pushReplacementNamed(context, '/preferences');
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Préférences enregistrées!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFB24516),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.check_circle, size: 80, color: Color(0xFF2D552C)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/menu');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D552C),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Découvrir nos recommandations',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Retour vers preferences.dart
                Navigator.pop(context); // Option 1
                // Navigator.pushReplacementNamed(context, '/preferences'); // Option 2
              },
              child: Text(
                'Retour aux préférences',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF2D552C),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}