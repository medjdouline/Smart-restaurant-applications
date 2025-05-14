import 'package:flutter/material.dart';
class FelicitationScreen extends StatelessWidget {
  const FelicitationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9B975), 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              
              const Spacer(flex: 2),
              
              
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF245536), 
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              
              
              const Text(
                'Félicitations !',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color:   Color(0xFF245536),
                ),
              ),
              const SizedBox(height: 15),
              
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Votre profil est maintenant complet. Découvrez des recettes adaptées à vos préférences et contraintes alimentaires.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color:  Color(0xFF245536),
                  ),
                ),
              ),
              
              
              const Spacer(flex: 3),
              
              
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
                  onPressed: () {
                    
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/main', 
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Commencer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              
              
              const SizedBox(height: 40),
             
            ],
          ),
        ),
      ),
    );
  }
}