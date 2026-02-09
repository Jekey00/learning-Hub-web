import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/reels/providers/reel_provider.dart';
import 'features/flashcards/providers/flashcard_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  String url = const String.fromEnvironment('SUPABASE_URL');
  String key = const String.fromEnvironment('SUPABASE_ANON_KEY');

  // LOKALER MODUS: Wenn GitHub-Daten fehlen, versuche .env zu laden
  if (url.isEmpty || url.contains('YOUR_PROJECT_ID')) {
    try {
      await dotenv.load(fileName: ".env");
      url = dotenv.env['SUPABASE_URL'] ?? '';
      key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    } catch (e) {
      debugPrint('Keine .env Datei gefunden.');
    }
  }

  // FALLBACK: Wenn immer noch leer, nutze die Config-Datei
  if (url.isEmpty) {
    url = SupabaseConfig.supabaseUrl;
    key = SupabaseConfig.supabaseAnonKey;
  }

  // FINALER CHECK: Wenn alles leer ist oder Platzhalter enthält, zeige Error-Screen
  if (url.isEmpty || url.contains('YOUR_PROJECT_ID')) {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, color: Colors.blue, size: 80),
                const SizedBox(height: 24),
                const Text('Datenbank-Verbindung fehlt', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text(
                  'Bitte stelle sicher, dass deine .env Datei lokal vorhanden ist oder die Secrets bei GitHub eingetragen sind.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    return;
  }

  try {
    await Supabase.initialize(url: url, anonKey: key);
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Supabase Start-Fehler: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReelProvider()),
        ChangeNotifierProvider(create: (_) => FlashcardProvider()),
      ],
      child: MaterialApp.router(
        title: 'Learning Hub',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
