import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/flashcard_model.dart';

class FlashcardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<FlashcardSet>> getFlashcardSets({String? categoryId}) async {
    var query = _supabase
        .from('flashcard_sets')
        .select('*, profiles(*), flashcards(id)');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((e) => FlashcardSet.fromJson(e)).toList();
  }

  Future<List<Flashcard>> getCardsInSet(String setId) async {
    final response = await _supabase
        .from('flashcards')
        .select()
        .eq('set_id', setId);
    
    return (response as List).map((e) => Flashcard.fromJson(e)).toList();
  }

  Future<void> createFlashcardSet({
    required String userId,
    required String title,
    String? description,
    String? categoryId,
    required List<Map<String, String>> cards,
  }) async {
    // 1. Set erstellen
    final setResponse = await _supabase.from('flashcard_sets').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'category_id': categoryId,
    }).select().single();

    final setId = setResponse['id'];

    // 2. Karten einfügen
    final cardsData = cards.map((card) => {
      'set_id': setId,
      'front_text': card['front'],
      'back_text': card['back'],
    }).toList();

    await _supabase.from('flashcards').insert(cardsData);
  }

  Future<void> deleteFlashcardSet(String setId) async {
    await _supabase.from('flashcard_sets').delete().eq('id', setId);
  }
}
