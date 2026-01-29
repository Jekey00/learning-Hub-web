import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _localAuth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();
  bool _hasBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      setState(() {
        _hasBiometrics = canCheck && isDeviceSupported;
      });
      
      if (_hasBiometrics) {
        final hasCredentials = await _storage.read(key: 'user_email') != null;
        if (hasCredentials) {
          // Automatisch Biometrie anbieten
          await _authenticateWithBiometrics();
        }
      }
    } catch (e) {
      debugPrint('Biometrie-Check fehlgeschlagen: $e');
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Bitte authentifizieren Sie sich',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        final email = await _storage.read(key: 'user_email');
        final password = await _storage.read(key: 'user_password');
        
        if (email != null && password != null && mounted) {
          _emailController.text = email;
          _passwordController.text = password;
          await _handleLogin();
        }
      }
    } catch (e) {
      debugPrint('Biometrie-Authentifizierung fehlgeschlagen: $e');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (error == null) {
      // Credentials speichern für Biometrie
      if (_hasBiometrics) {
        await _storage.write(key: 'user_email', value: _emailController.text.trim());
        await _storage.write(key: 'user_password', value: _passwordController.text);
      }
      
      if (mounted) {
        context.go('/feed');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.school,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Learning Hub',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-Mail',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte E-Mail eingeben';
                    }
                    if (!value.contains('@')) {
                      return 'Ungültige E-Mail';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Passwort',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte Passwort eingeben';
                    }
                    if (value.length < 6) {
                      return 'Passwort muss mindestens 6 Zeichen haben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleLogin,
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Anmelden'),
                  ),
                ),
                if (_hasBiometrics) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _authenticateWithBiometrics,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Mit Fingerabdruck anmelden'),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Noch kein Konto? Registrieren'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
