import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _unreadNotifications = [];

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _isAdmin;
  List<Map<String, dynamic>> get unreadNotifications => _unreadNotifications;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = _authService.currentUser;
    if (_user != null) {
      _checkAdminStatus();
      _fetchNotifications();
    }
    _authService.authStateChanges.listen((event) {
      _user = event.session?.user;
      if (_user != null) {
        _checkAdminStatus();
        _fetchNotifications();
      } else {
        _isAdmin = false;
        _unreadNotifications = [];
      }
      notifyListeners();
    });
  }

  Future<void> _checkAdminStatus() async {
    if (_user == null) return;
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('is_admin')
          .eq('id', _user!.id)
          .single();
      _isAdmin = response['is_admin'] == true;
      notifyListeners();
    } catch (e) {
      debugPrint('Fehler beim Admin-Check: $e');
      _isAdmin = false;
      notifyListeners();
    }
  }

  Future<void> _fetchNotifications() async {
    if (_user == null) return;
    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', _user!.id)
          .eq('is_read', false)
          .order('created_at', ascending: false);
      
      _unreadNotifications = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Fehler beim Laden der Benachrichtigungen: $e');
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
      _unreadNotifications.removeWhere((n) => n['id'] == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Fehler beim Markieren der Benachrichtigung: $e');
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
      );
      
      if (response.user == null) {
        return 'Registrierung fehlgeschlagen';
      }
      
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _isAdmin = false;
    _unreadNotifications = [];
    notifyListeners();
  }
}
