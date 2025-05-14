import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';  // Importer GoRouter pour la navigation

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home Screen")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Bienvenue sur la page d'accueil !"),
            ElevatedButton(
              onPressed: () {
                // Naviguer vers le profil
                context.go('/profile');
              },
              child: Text("Aller au Profil"),
            ),
          ],
        ),
      ),
    );
  }
}