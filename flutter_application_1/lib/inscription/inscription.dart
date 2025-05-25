import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../user_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

Future<void> _registerUser() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final success = await Provider.of<UserService>(context, listen: false)
        .registerStep1(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _usernameController.text.trim(),
          _phoneController.text.trim(),
        );

    if (success && mounted) {
      Navigator.pushNamed(context, '/info_perso');
    }
  } on FirebaseAuthException catch (e) {
    if (mounted) {
      _showErrorToast(_getFirebaseErrorMessage(e));
    }
  } catch (e) {
    if (mounted) {
      // Show the backend error message directly
      _showErrorToast(e.toString().replaceAll('Exception: ', ''));
    }
    debugPrint('Registration error: $e');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Email invalide';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères minimum)';
      case 'operation-not-allowed':
        return 'Opération non autorisée';
      default:
        return 'Erreur Firebase: ${e.message}';
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA93D0E),
      body: Column(
        children: [
          // En-tête avec logo
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            width: double.infinity,
            color: const Color(0xFFA93D0E),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.storefront_outlined,
                  size: 70,
                  color: Color(0xFFDFBE89),
                ),
                SizedBox(height: 15),
                Text(
                  'Good taste !',
                  style: TextStyle(
                    color: Color(0xFFDFBE89),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Formulaire
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFDFBE89),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(200),
                  topRight: Radius.circular(200),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        'Inscrivez-vous',
                        style: TextStyle(
                          color: Color(0xFF730406),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Champ Nom d'utilisateur
                      _buildTextField(
                        controller: _usernameController,
                        hintText: 'Nom d\'utilisateur',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ce champ est obligatoire';
                          }
                          if (value.length < 3) {
                            return '3 caractères minimum';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      
                      // Champ Email
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'Adresse Mail',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ce champ est obligatoire';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      
                      // Champ Téléphone
                      _buildTextField(
                        controller: _phoneController,
                        hintText: 'Numéro de téléphone',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ce champ est obligatoire';
                          }
                          if (!RegExp(r'^[0-9]{8,15}$').hasMatch(value)) {
                            return 'Numéro invalide (8-15 chiffres)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      
                      // Champ Mot de passe
                      _buildTextField(
                        controller: _passwordController,
                        hintText: 'Mot de passe',
                        icon: Icons.lock,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ce champ est obligatoire';
                          }
                          if (value.length < 6) {
                            return '6 caractères minimum';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      
                      // Champ Confirmation mot de passe
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirmer mot de passe',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ce champ est obligatoire';
                          }
                          if (value != _passwordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Bouton d'inscription
                      SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E6E41),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'S\'inscrire',
                                  style: TextStyle(fontSize: 20),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Lien vers la page de connexion
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text(
                          'Déjà un compte ? Se connecter',
                          style: TextStyle(
                            color: Color(0xFFA93D0E),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: 350,
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFA93D0E),
              fontSize: 16,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFFA93D0E)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red),
            ),
            errorStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}