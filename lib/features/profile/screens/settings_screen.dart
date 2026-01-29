import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoPlayReels = true;
  final _storage = const FlutterSecureStorage();
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final autoPlay = await _storage.read(key: 'auto_play_reels');
    if (autoPlay != null) {
      setState(() {
        _autoPlayReels = autoPlay == 'true';
      });
    }
  }

  Future<void> _saveSettings(bool value) async {
    setState(() {
      _autoPlayReels = value;
    });
    await _storage.write(key: 'auto_play_reels', value: value.toString());
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konto unwiderruflich löschen?', style: TextStyle(color: Colors.red)),
        content: const Text('Bist du sicher? Dein Profil, alle deine Beiträge, Reels und Likes werden sofort gelöscht. Dieser Vorgang kann NICHT rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Alles löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        final supabase = Supabase.instance.client;
        
        // Wir rufen die neue Postgres-Funktion auf
        await supabase.rpc('delete_user_account');
        
        if (mounted) {
          final authProvider = context.read<AuthProvider>();
          await authProvider.signOut();
          context.go('/login');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dein Konto wurde erfolgreich gelöscht.')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Löschen: $e')),
          );
        }
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
            'Der Verantwortliche für die Datenverarbeitung in dieser App ist: [Justyn Kuhne] [Kämpenstr 50, 45147 Essen, Deutschland] [justyn.kuhne@yahoo.de]\n\n'
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              SwitchListTile(
                title: const Text('Reels automatisch abspielen'),
                subtitle: const Text('Videos starten sofort beim Scrollen'),
                value: _autoPlayReels,
                onChanged: _saveSettings,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Datenschutzerklärung'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showPrivacyPolicy,
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Gefahrenzone', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Konto und alle Daten löschen', style: TextStyle(color: Colors.red)),
                onTap: _isDeleting ? null : _deleteAccount,
              ),
            ],
          ),
          if (_isDeleting)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Lösche Account...', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
