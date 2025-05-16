import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/data/models/email.dart';
import 'package:good_taste/logic/blocs/login/login_bloc.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:good_taste/presentation/screens/main_navigation_screen.dart';
import 'package:good_taste/presentation/screens/register_screen.dart';
import 'package:formz/formz.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE9B975), 
      resizeToAvoidBottomInset: true,
      body: BlocProvider(
        create: (context) {
          return LoginBloc(
            authRepository: RepositoryProvider.of<AuthRepository>(context),
          );
        },
        child: const LoginForm(),
      ),
    );
  }
}

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state.status == FormzSubmissionStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Erreur de connexion')),
            );
        }
        if (state.status == FormzSubmissionStatus.success) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MainNavigationScreen()),);
        }

      },

      child: SafeArea(
       child: SingleChildScrollView( 
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Logo
              Image.asset(
                'assets/images/logo/logo.png', 
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 16),
              const Text(
                'Good taste !',
                style: TextStyle(
                  color: Color.fromARGB(255, 80, 9, 4),
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              const Text(
                'Connectez-vous',
                style: TextStyle(color: Color(0xFFBA3400), fontSize: 18),
              ),
              const SizedBox(height: 30),
              _EmailInput(),
              const SizedBox(height: 12),
              _PasswordInput(),
              const SizedBox(height: 30),
              _LoginButton(),
              const SizedBox(height: 12),
              _SignUpButton(),
            ],
          ),
        ),
      ),
    ),
    );
  }
}


class _EmailInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen:
          (previous, current) =>
              previous.email != current.email ||
              previous.isSubmitted != current.isSubmitted,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFFDB9051),
            borderRadius: BorderRadius.circular(
              20,
            ), 
          ),
          child: TextField(
            key: const Key('loginForm_emailInput_textField'),
            onChanged:
                (email) => context.read<LoginBloc>().add(
                  LoginEmailChanged(email),
                ),
            keyboardType: TextInputType.emailAddress, 
decoration: InputDecoration(
  hintText: 'Email ou nom d\'utilisateur',
  contentPadding: const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  ),
  border: InputBorder.none,
  errorText:
      state.isSubmitted && state.email.isNotValid
          ? _getEmailErrorText(state)
          : null,
),
          ),
        
        );
      },
    );
  }
 
  String _getEmailErrorText(LoginState state) {
    if (state.email.error == EmailValidationError.empty) {
      return 'L\'email ne peut pas être vide';
    } else if (state.email.error == EmailValidationError.invalid) {
      return 'Format d\'email invalide';
    }
    return 'Email invalide';
  }
}

class _PasswordInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen:
          (previous, current) =>
              previous.password != current.password ||
              previous.isSubmitted != current.isSubmitted,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFFDB9051),
            borderRadius: BorderRadius.circular(
              20,
            ), 
          ),
          child: TextField(
            key: const Key('loginForm_passwordInput_textField'),
            onChanged:
                (password) => context.read<LoginBloc>().add(
                  LoginPasswordChanged(password),
                ),
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Mot de passe',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              errorText:
                  state.isSubmitted && state.password.isNotValid
                      ? 'Mot de passe invalide'
                      : null,
            ),
          ),
        );
      },
    );
  }
}

class _LoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('loginForm_continue_raisedButton'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF245536),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed:
                state.status == FormzSubmissionStatus.inProgress
                    ? null 
                    : () {
                      context.read<LoginBloc>().add(LoginSubmitted());
                    },
            child:
                state.status == FormzSubmissionStatus.inProgress
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Se connecter'),
          ),
        );
      },
    );
  }
}

class _SignUpButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          key: const Key('loginForm_createAccount_flatButton'),
          onPressed: () {
            
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RegisterScreen(),
              ),
            );
          },
          child: const Text(
            'S\'inscrire',
            style: TextStyle(color:  Color(0xFF245536)),
          ),
        ),
        const Icon(Icons.arrow_forward, size: 18, color:  Color(0xFF245536)),
      ],
    );
  }
}