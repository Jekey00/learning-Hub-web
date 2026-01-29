import 'package:flutter/material.dart';
import '../models/reel_model.dart';
import '../services/reel_service.dart';

class ReelProvider extends ChangeNotifier {
  final ReelService _reelService = ReelService();
  List<ReelModel> _reels = [];
  bool _isLoading = false;
  String? _currentCategoryId;

  List<ReelModel> get reels => _reels;
  bool get isLoading => _isLoading;

  Future<void> loadReels({String? categoryId, bool forceRefresh = false}) async {
    if (!forceRefresh && _reels.isNotEmpty && _currentCategoryId == categoryId) return;

    _isLoading = true;
    _currentCategoryId = categoryId;
    notifyListeners();

    try {
      _reels = await _reelService.getReels(categoryId: categoryId);
    } catch (e) {
      debugPrint('ReelProvider Fehler: $e');
      _reels = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeReel(String id) {
    _reels.removeWhere((reel) => reel.id == id);
    notifyListeners();
  }
}
