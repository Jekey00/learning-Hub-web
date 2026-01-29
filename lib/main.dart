import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/reels/providers/reel_provider.dart';
import 'features/flashcards/providers/flashcard_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Wir holen die Daten AUSSCHLIESSLICH aus der Umgebung (GitHub Secrets)
  const String url = String.fromEnvironment('SUPABASE_URL');
  const String key = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Sicherheits-Check: Wenn die Daten fehlen, zeigen wir einen Error-Screen
  if (url.isEmpty || url.contains('YOUR_PROJECT_ID')) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'FEHLER: Supabase-Keys fehlen!\n\nBitte trage SUPABASE_URL und SUPABASE_ANON_KEY in den GitHub Secrets ein.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
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
    print('Supabase Start-Fehler: $e');
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
