import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/auth/auth_bloc.dart';
import 'package:good_taste/logic/blocs/profile/profile_bloc.dart';
import 'package:good_taste/presentation/screens/profile/edit_profil_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load fidelity points when screen initializes
    context.read<ProfileBloc>().add(ProfileFidelityPointsLoaded());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => 
        previous.status != current.status && current.status == AuthStatus.unauthenticated,
      listener: (context, state) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final userName = authState.user.name.isNotEmpty ? authState.user.name : 'Utilisateur';
          final userEmail = authState.user.email.isNotEmpty ? authState.user.email : 'user123@gmail.com';
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              
              // User Profile Container
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
              
              const SizedBox(height: 15),
              
              // Fidelity Points Container
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, profileState) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF245536),
                          const Color(0xFF245536).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.stars,
                            color: Color(0xFFDB9051),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Points de fidélité',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (profileState.fidelityPointsStatus == FidelityPointsLoadingStatus.loading)
                                const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              else if (profileState.fidelityPointsStatus == FidelityPointsLoadingStatus.failure)
                                const Text(
                                  'Erreur de chargement',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    Text(
                                      '${profileState.fidelityPoints}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (profileState.fidelityPoints >= 10)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDB9051),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Récompense disponible!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.read<ProfileBloc>().add(ProfileFidelityPointsLoaded());
                          },
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Menu Items Container
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
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthLogoutRequested());
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
          );
        },
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