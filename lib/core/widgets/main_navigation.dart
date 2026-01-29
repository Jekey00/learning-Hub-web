import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';

class MainNavigation extends StatefulWidget {
  final Widget child;

  const MainNavigation({super.key, required this.child});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Prüfe beim Start auf Benachrichtigungen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotifications();
    });
  }

  void _checkNotifications() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.unreadNotifications.isNotEmpty) {
      final latest = authProvider.unreadNotifications.first;
      _showNotificationDialog(latest['title'], latest['message'], latest['id']);
    }
  }

  void _showNotificationDialog(String title, String message, String id) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<AuthProvider>().markNotificationAsRead(id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    
    switch (index) {
      case 0:
        context.go('/feed');
        break;
      case 1:
        context.go('/reels');
        break;
      case 2:
        context.go('/flashcards');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: 'Reels',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.copy),
            label: 'Lernen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
