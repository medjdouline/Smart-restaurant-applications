// lib/presentation/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:good_taste/logic/blocs/register/register_bloc.dart';
import 'package:good_taste/data/repositories/auth_repository.dart';
import 'package:formz/formz.dart';
import 'package:good_taste/presentation/screens/personal_info.dart';


class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => const RegisterScreen());
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFE9B975),
    resizeToAvoidBottomInset: true, 
    body: BlocProvider<RegisterBloc>(
      create: (context) {
        return RegisterBloc(
          authRepository: RepositoryProvider.of<AuthRepository>(context),
        );
      },
      child: const RegisterForm(),
    ),
  );
}
}

class RegisterForm extends StatelessWidget {
  const RegisterForm({super.key});
@override
Widget build(BuildContext context) {
  return BlocListener<RegisterBloc, RegisterState>(
    listener: (context, state) {
      if (state.status.isSuccess) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Inscription réussie')),
          );
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PersonalInfoScreen(),
          ),
        );
      }
    },
    child: SafeArea(
      child: SingleChildScrollView(  
        child: Padding(
          padding: const EdgeInsets.all(20),
          
          child: Container(
            height: MediaQuery.of(context).size.height - 40,
            color: const Color(0xFFE9B975),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                
                Image.asset(
                  'assets/images/logo/logo.png',
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Good taste !',
                  style: TextStyle(
                    color: Color.fromARGB(255, 80, 9, 4),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Créez votre compte',
                  style: TextStyle(color: Color(0xFFBA3400), fontSize: 16),
                ),
                const SizedBox(height: 30),
                _UsernameInput(),
                const SizedBox(height: 12),
                _EmailInput(),
                const SizedBox(height: 12),
                _PhoneNumberInput(), 
                const SizedBox(height: 12),
                _PasswordInput(),
                const SizedBox(height: 12),
                _ConfirmPasswordInput(),
                const SizedBox(height: 30),
                _SignUpButton(),
                const SizedBox(height: 12),
                _LoginButton(),
                const Spacer(), 
              ],
            ), 
          ),
        ),
      ),
    ),
  );
}
}


class _UsernameInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      buildWhen:
          (previous, current) =>
              previous.username != current.username ||
              previous.isSubmitted != current.isSubmitted,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFDB9051),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            key: const Key('registerForm_usernameInput_textField'),
            onChanged:
                (username) => context.read<RegisterBloc>().add(
                  RegisterUsernameChanged(username),
                ),
            decoration: InputDecoration(
              hintText: 'Nom d\'utilisateur',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              errorText:
                  state.isSubmitted && state.username.isNotValid
                      ? 'Nom d\'utilisateur invalide'
                      : null,
            ),
          ),
        );
      },
    );
  }
}


class _EmailInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      buildWhen:
          (previous, current) =>
              previous.email != current.email ||
              previous.isSubmitted != current.isSubmitted,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFDB9051),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            key: const Key('registerForm_emailInput_textField'),
            onChanged:
                (email) => context.read<RegisterBloc>().add(
                  RegisterEmailChanged(email),
                ),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Adresse e-mail',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              errorText:
                  state.isSubmitted && state.email.isNotValid
                      ? 'Email invalide'
                      : null,
            ),
          ),
        );
      },
    );
  }
}



class _PhoneNumberInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      buildWhen:
          (previous, current) =>
              previous.phoneNumber != current.phoneNumber ||
              previous.isSubmitted != current.isSubmitted,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFDB9051),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            key: const Key('registerForm_phoneNumberInput_textField'),
            onChanged:
                (phoneNumber) => context.read<RegisterBloc>().add(
                  RegisterPhoneNumberChanged(phoneNumber),
                ),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Numéro de téléphone',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              errorText:
                  state.isSubmitted && state.phoneNumber.isNotValid
                      ? 'Numéro invalide ou déjà utilisé'
                      : null,
            ),
          ),
        );
      },
    );
  }
}


class _PasswordInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      buildWhen:
          (previous, current) =>
              previous.password != current.password ||
              previous.isSubmitted != current.isSubmitted,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFDB9051),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            key: const Key('registerForm_passwordInput_textField'),
            onChanged:
                (password) => context.read<RegisterBloc>().add(
                  RegisterPasswordChanged(password),
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


class _ConfirmPasswordInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      buildWhen:
          (previous, current) =>
              previous.password != current.password ||
              previous.confirmedPassword != current.confirmedPassword ||
              previous.isSubmitted != current.isSubmitted,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFDB9051),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            key: const Key('registerForm_confirmedPasswordInput_textField'),
            onChanged:
                (confirmPassword) => context.read<RegisterBloc>().add(
                  RegisterConfirmPasswordChanged(confirmPassword),
                ),
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Confirmer mot de passe',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              errorText:
                  state.isSubmitted && state.confirmedPassword.isNotValid
                      ? 'Les mots de passe ne correspondent pas'
                      : null,
            ),
          ),
        );
      },
    );
  }
}


class _SignUpButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      buildWhen: (previous, current) => 
          previous.status != current.status || 
          previous.isValid != current.isValid ||
          previous.isSubmitted != current.isSubmitted,
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('registerForm_continue_raisedButton'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF245536),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: state.status.isInProgress
                ? null
                : () {
                    context.read<RegisterBloc>().add(RegisterSubmitted());
                   
                  },
            child: state.status.isInProgress
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('S\'inscrire'),
          ),
        );
      },
    );
  }
}
class _LoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          key: const Key('registerForm_login_flatButton'),
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Se connecter',
            style: TextStyle(color:  Color(0xFF245536)),
          ),
        ),
        const Icon(Icons.arrow_forward, size: 18, color:  Color(0xFF245536)),
      ],
    );
  }
}
