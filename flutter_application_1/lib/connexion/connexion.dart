import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../user_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(); // Changed from email to identifier
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final userService = Provider.of<UserService>(context, listen: false);
        final success = await userService.login(
          _identifierController.text.trim(), // Can be email or username
          _passwordController.text.trim(),
        );

        if (success) {
          Navigator.pushReplacementNamed(context, '/menu');
        } else {
          Fluttertoast.showToast(
            msg: "Email/nom d'utilisateur ou mot de passe incorrect",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } catch (e) {
        // Handle any other errors
        String errorMessage = "Erreur de connexion";
        
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'user-not-found':
              errorMessage = "Utilisateur non trouvé";
              break;
            case 'wrong-password':
              errorMessage = "Mot de passe incorrect";
              break;
            case 'invalid-email':
              errorMessage = "Email invalide";
              break;
            case 'user-disabled':
              errorMessage = "Compte désactivé";
              break;
            default:
              errorMessage = e.message ?? "Erreur de connexion";
          }
        } else {
          errorMessage = e.toString();
        }
        
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

Future<void> _enterAsGuest() async {
  setState(() => _isLoading = true);
  
  try {
    final userService = Provider.of<UserService>(context, listen: false);
    
    // Try to login as guest via API
    final success = await userService.loginAsGuest();
    
    if (success) {
      Navigator.pushReplacementNamed(context, '/invite');
    } else {
      // Fallback to local guest mode
      userService.enterAsGuest();
      Navigator.pushReplacementNamed(context, '/invite');
    }
  } catch (e) {
    debugPrint('Error during guest login: $e');
    
    // Fallback to local guest mode
    Provider.of<UserService>(context, listen: false).enterAsGuest();
    Navigator.pushReplacementNamed(context, '/invite');
    
    Fluttertoast.showToast(
      msg: "Mode invité activé (hors ligne)",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFA93D0E),
      body: Column(
        children: [
          Container(
            height: screenHeight * 0.3,
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
                        'Connectez-vous',
                        style: TextStyle(
                          color: Color(0xFF730406),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildTextField(
                        controller: _identifierController,
                        hintText: 'Email ou nom d\'utilisateur', // Updated hint text
                        icon: Icons.person, // Changed icon to be more generic
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre email ou nom d\'utilisateur';
                          }
                          // More flexible validation - allow both email and username
                          if (value.length < 3) {
                            return 'Identifiant trop court (minimum 3 caractères)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: 'Mot de passe',
                        icon: Icons.lock,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          if (value.length < 6) {
                            return '6 caractères minimum';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _loginUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E6E41),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                'Se connecter',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/inscription');
                        },
                        child: const Text(
                          'Pas de compte ? S\'inscrire',
                          style: TextStyle(
                            color: Color(0xFFA93D0E),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
 const SizedBox(height: 30),
                      _isLoading
                          ? const SizedBox(
                              height: 56,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : ElevatedButton.icon(
                              onPressed: _enterAsGuest,
                              icon: const Icon(Icons.person_outline),
                              label: const Text(
                                'Continuer en tant qu\'invité',
                                style: TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF325434),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 3,
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
    required String? Function(String?) validator,
  }) {
    return SizedBox(
      width: 350,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }
}