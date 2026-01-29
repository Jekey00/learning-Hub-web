import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _privacyPolicyAccepted = false;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_privacyPolicyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte akzeptiere die Datenschutzerklärung'),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final error = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _usernameController.text.trim(),
      fullName: _fullNameController.text.trim(),
    );

    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrierung erfolgreich! Bitte anmelden.'),
          ),
        );
        context.go('/login');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Datenschutzerklärung'),
        content: const SingleChildScrollView(
          child: Text(
            'In dieser Datenschutzerklärung informieren wir Sie über die Verarbeitung personenbezogener Daten bei der Nutzung unserer App "Tech Hub".\n\n'
            '1. Verantwortlicher\n'
            'Der Verantwortliche für die Datenverarbeitung in dieser App ist: [NAME] [ADRESSE] [E-MAIL]\n\n'
            '2. Erhebung und Speicherung personenbezogener Daten\n'
            'a) Bei Nutzung der App (Backend: Supabase)\n'
            'Unsere App nutzt für die Datenbankverwaltung, Authentifizierung und Speicherung von Inhalten den Dienst Supabase (Supabase Inc.). Alle von Ihnen eingegebenen Daten werden direkt an die Server von Supabase übertragen und dort gespeichert. Dazu gehören:\n'
            '• Profil-Daten: E-Mail-Adresse, Benutzername, Profilbilder.\n'
            '• Inhalte: Posts, Bilder und Reels, die Sie hochladen.\n'
            '• Statistiken: Anzahl der Follower und Beiträge.\n'
            '• Sicherheit: Ihre Passwörter werden niemals im Klartext gespeichert. Durch kryptografisches Hashing (bcrypt) im Supabase Auth-System sind Ihre Zugangsdaten geschützt.\n'
            '• Datenspeicherung: Mediendateien (Videos/Bilder) werden physisch im Supabase Storage (Objektspeicher) abgelegt, während die Verweise darauf (URLs) in der PostgreSQL-Datenbank verwaltet werden.\n'
            '• Datenminimierung: Wir setzen technische Verfahren zur Datenminimierung ein, indem wir Videodateien vor dem Upload komprimieren und skalieren. Dies dient der effizienten Übertragung und schont das Datenvolumen der Nutzer.\n'
            '• Automatische Moderation: Um die Qualität der Inhalte zu gewährleisten, verfügt das System über eine automatische Moderationslogik. Beiträge, die eine Anzahl von 10 negativen Bewertungen (Dislikes) erreichen, führen zu einer Verwarnung des Nutzers. Bei Erreichen von 15 negativen Bewertungen wird der entsprechende Inhalt automatisch und unwiderruflich gelöscht.\n\n'
            'b) Nutzerverantwortung und Verhaltensregeln\n'
            'Jeder Nutzer ist für die von ihm erstellten und geteilten Inhalte (Texte, Bilder, Reels) vollumfänglich selbst verantwortlich. Wir legen Wert auf ein respektvolles Miteinander.\n'
            '• Verbotene Inhalte: Es ist streng untersagt, jugendfreie (pornografische), kriminelle, rassistische, diskriminierende, gewaltverherrlichende oder rechtswidrige Inhalte zu veröffentlichen.\n'
            '• Sanktionen: Verstöße gegen diese Regeln werden konsequent geahndet. Wir behalten uns das Recht vor, entsprechende Inhalte ohne Vorankündigung zu löschen und das betroffene Benutzerprofil dauerhaft zu sperren.\n\n'
            'c) Erstellung von Reels (KI-Generierung via n8n Webhook)\n'
            'Unsere App ermöglicht die Erstellung von KI-generierten Lernvideos (Reels). Hierbei werden die von Ihnen gewählten Kategorien und Themen per Webhook an einen Automatisierungsdienst (n8n) gesendet.\n'
            '• Zweck: Diese Daten dienen ausschließlich der automatisierten Videoerstellung durch Künstliche Intelligenz.\n'
            '• KI-Videogenerierung: Zur Erstellung der Reels werden Thema und Kategorie an OpenAI (Sora) übermittelt. Eine Verknüpfung mit Ihrer persönlichen Identität findet dabei nicht statt.\n'
            '• Verarbeitung: Nach der Generierung wird das Video in der Supabase-Datenbank gespeichert.\n\n'
            '3. Weitergabe von Daten\n'
            'Eine Weitergabe Ihrer persönlichen Daten an Dritte erfolgt nicht, außer:\n'
            '• An unsere Dienstleister (Supabase als Datenbank-Provider), die technisch notwendig für den Betrieb der App sind.\n'
            '• Wenn eine gesetzliche Verpflichtung dazu besteht.\n\n'
            '4. Speicherdauer\n'
            'Wir speichern Ihre Daten so lange, wie es für die Bereitstellung der Funktionen der App erforderlich ist oder bis Sie Ihr Benutzerkonto löschen. Nach der Löschung Ihres Kontos werden Ihre Daten aus den aktiven Datenbanken entfernt, sofern keine gesetzlichen Aufbewahrungspflichten bestehen.\n\n'
            '5. Ihre Rechte\n'
            'Sie haben das Recht:\n'
            '• Auskunft über Ihre bei uns gespeicherten Daten zu erhalten.\n'
            '• Die Berichtigung unrichtiger Daten zu verlangen.\n'
            '• Die Löschung Ihrer Daten zu fordern (Recht auf Vergessenwerden).\n'
            '• Der Verarbeitung Ihrer Daten zu widersprechen.\n\n'
            '6. Datensicherheit\n'
            'Wir setzen technische und organisatorische Sicherheitsmaßnahmen ein (z. B. SSL/TLS-Verschlüsselung der Übertragung an Supabase), um Ihre Daten gegen Manipulation, Verlust oder unbefugten Zugriff zu schützen.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _privacyPolicyAccepted = true);
              Navigator.pop(context);
            },
            child: const Text('Akzeptieren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrieren'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Vollständiger Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte Namen eingeben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Benutzername',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte Benutzername eingeben';
                    }
                    if (value.length < 3) {
                      return 'Mindestens 3 Zeichen';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                      return 'Mindestens 6 Zeichen';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: GestureDetector(
                    onTap: _showPrivacyPolicy,
                    child: const Text(
                      'Ich akzeptiere die Datenschutzerklärung',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  value: _privacyPolicyAccepted,
                  onChanged: (bool value) {
                    if (value) {
                      _showPrivacyPolicy();
                    } else {
                      setState(() => _privacyPolicyAccepted = false);
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleRegister,
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Registrieren'),
                  ),
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
    _usernameController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }
}
