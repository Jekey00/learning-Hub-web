import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../services/flashcard_service.dart';

class FlashcardProvider extends ChangeNotifier {
  final FlashcardService _flashcardService = FlashcardService();
  List<FlashcardSet> _flashcardSets = [];
  bool _isLoading = false;

  List<FlashcardSet> get flashcardSets => _flashcardSets;
  bool get isLoading => _isLoading;

  Future<void> loadFlashcardSets({String? categoryId, bool forceRefresh = false}) async {
    if (!forceRefresh && _flashcardSets.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      _flashcardSets = await _flashcardService.getFlashcardSets(categoryId: categoryId);
    } catch (e) {
      debugPrint('FlashcardProvider Fehler: $e');
      _flashcardSets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeSet(String id) {
    _flashcardSets.removeWhere((set) => set.id == id);
    notifyListeners();
  }
}
