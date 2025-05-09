// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
// Ensure this is the correct file where LoginRequested is defined
import '../../blocs/auth/auth_state.dart';
import '../../blocs/auth/auth_status.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_input_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _emailError;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fonction de validation d'email
  bool _validateEmail(String email) {
    // Expression régulière pour la validation d'email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    if (email.isEmpty) {
      setState(() {
        _emailError = 'L\'email ne peut pas être vide';
      });
      return false;
    } else if (!emailRegex.hasMatch(email)) {
      setState(() {
        _emailError = 'Format d\'email invalide';
      });
      return false;
    }
    
    setState(() {
      _emailError = null;
    });
    return true;
  }

  // Fonction pour tenter de se connecter
  void _tryLogin() {
    final email = _emailController.text;
    final password = _passwordController.text;
    
    if (_validateEmail(email)) {
      context.read<AuthBloc>().add(
        LoginRequested(
          email: email,
          password: password,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9B975),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Erreur de connexion')),
            );
          } else if (state.status == AuthStatus.authenticated) {
            // Navigation vers l'écran principal après connexion
            Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  Image.asset(
                    AppConstants.logoPath,
                    width: 120,
                    height: 120,
                    color: const Color(0xFFAA2C10),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: Color(0xFFAA2C10),
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    AppConstants.loginTitle,
                    style: TextStyle(
                      color: Color(0xFFAA2C10),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Champ email
                  CustomInputField(
                    controller: _emailController,
                    hintText: AppConstants.emailHint,
                    errorText: _emailError,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {
                      // Si l'utilisateur modifie le champ, on efface l'erreur
                      if (_emailError != null) {
                        setState(() {
                          _emailError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  // Champ mot de passe
                  CustomInputField(
                    controller: _passwordController,
                    hintText: AppConstants.passwordHint,
                    obscureText: true,
                  ),
                  const SizedBox(height: 40),
                  // Bouton de connexion
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state.status == AuthStatus.loading
                              ? null
                              : _tryLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF245536),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: state.status == AuthStatus.loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  AppConstants.loginButton,
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}