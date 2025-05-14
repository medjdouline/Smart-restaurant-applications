import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/auth/auth_bloc.dart';
import 'package:good_taste/presentation/screens/profile/edit_profil_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userName = authState.user.name.isNotEmpty ? authState.user.name : 'Utilisateur';
    final userEmail = authState.user.email.isNotEmpty ? authState.user.email : 'user123@gmail.com';
    
    return BlocListener<AuthBloc, AuthState>(
    listenWhen: (previous, current) => 
      previous.status != current.status && current.status == AuthStatus.unauthenticated,
    listener: (context, state) {
      
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    },
    child : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFDB9051),
                  shape: BoxShape.circle,
                ),
                child: authState.user.profileImage != null && authState.user.profileImage!.isNotEmpty
                  ? ClipOval(
                      child: authState.user.profileImage!.startsWith('assets/')
                        ? Image.asset(
                            authState.user.profileImage!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              );
                            },
                          )
                        : Image.file(
                            File(authState.user.profileImage!),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              );
                            },
                          )
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
              ),
              const SizedBox(width: 15),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              _buildMenuItem(
                context, 
                Icons.person_outline, 
                'Mon profil', 
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                }
              ),
              const Divider(height: 2, indent: 18, endIndent: 18),
              _buildMenuItem(context, Icons.restaurant_menu, 'Mes préférences', 
                onTap: () {
                Navigator.of(context).pushNamed('/preferences');
                }
                ),
              const Divider(height: 2, indent: 18, endIndent: 18),
              _buildMenuItem(context, Icons.calendar_today, 'Historique des réservations',
                onTap: () {
                  Navigator.of(context).pushNamed('/reservation_history');
                }
              ),
              const Divider(height: 2, indent: 18, endIndent: 18),
              _buildMenuItem(context, Icons.receipt_long, 'Historique des commandes',
                onTap: () {
                 Navigator.of(context).pushNamed('/order_history');
              }
          ) ,
            ],
          ),
        ),
        const SizedBox(height: 30),
        
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              
              context.read<AuthBloc>().add(AuthLogoutRequested( ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Déconnexion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, 
    IconData icon, 
    String title, 
    {VoidCallback? onTap}
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF245536), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }
}