import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/auth/auth_service.dart';
import 'package:mobile/theme/app_localizations.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // sign up button pressed
  void signUp() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    // prepare data
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // check that passwords match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context, 'passwords_mismatch', listen: false)),
        backgroundColor: context.info,
      ));
      return;
    }

    // attempt sign up..
    try {
      await authService.signUpWithEmailPassword(email, password);

      // pop this register page
      if (!mounted) return; // guard the use with a 'mounted' check
      context.pop();
    }
    // catch any errors..
    catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
        content: Text("${AppLocalizations.of(context, 'error', listen: false)}: $e"),
        backgroundColor: context.info,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // icon
              Icon(
                Icons.person_add_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // title
              Text(
                AppLocalizations.of(context, 'signup_button'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),

              // email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context, 'email'),
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // password
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context, 'password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // confirm password
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context, 'confirm_password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),

              const SizedBox(height: 32),
              // button
              ElevatedButton(
                onPressed: signUp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context, 'signup_button'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              
              const SizedBox(height: 24),

              // go to login page to log in
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      text: AppLocalizations.of(context, 'have_account'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
