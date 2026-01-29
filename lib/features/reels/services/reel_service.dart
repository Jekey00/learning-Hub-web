import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/reel_model.dart';

class ReelService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ReelModel>> getReels({String? categoryId}) async {
    try {
      debugPrint('Lade Reels für Kategorie: $categoryId');
      
      var query = _supabase
          .from('reels')
          .select('*, profiles(*)');

      // Filter nur anwenden, wenn categoryId nicht null und nicht leer ist
      if (categoryId != null && categoryId != 'null' && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      // Sortierung: Wir nutzen created_at als Fallback, falls order_index NULL ist
      final response = await query
          .order('created_at', ascending: false) 
          .timeout(const Duration(seconds: 15));
          
      final List<dynamic> data = response as List;
      debugPrint('${data.length} Reels erfolgreich geladen.');
      
      return data.map((e) => ReelModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('KRITISCH: Fehler beim Laden der Reels: $e');
      return [];
    }
  }

  Future<void> createReel({
    required String userId,
    required String title,
    String? description,
    required String videoUrl,
    String? thumbnailUrl,
    String? categoryId,
    int? duration,
  }) async {
    await _supabase.from('reels').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'category_id': categoryId,
      'duration': duration,
    });
  }

  Future<void> deleteReel(String reelId, String videoUrl) async {
    await _supabase.from('reels').delete().eq('id', reelId);
    try {
      if (videoUrl.contains('storage/v1/object/public/reels/')) {
        final fileName = videoUrl.split('/').last;
        await _supabase.storage.from('reels').remove([fileName]);
      }
    } catch (e) {
      debugPrint('Storage Löschfehler: $e');
    }
  }

  Future<void> likeReel(String userId, String reelId) async {
    await _supabase.from('likes').upsert({
      'user_id': userId,
      'reel_id': reelId,
    });
  }

  Future<void> unlikeReel(String userId, String reelId) async {
    await _supabase.from('likes').delete().match({
      'user_id': userId,
      'reel_id': reelId,
    });
  }

  Future<bool> isReelLiked(String userId, String reelId) async {
    final response = await _supabase
        .from('likes')
        .select('id')
        .eq('user_id', userId)
        .eq('reel_id', reelId);
    return (response as List).isNotEmpty;
  }

  Future<void> dislikeReel(String userId, String reelId) async {
    await _supabase.from('dislikes').upsert({
      'user_id': userId,
      'reel_id': reelId,
    });
  }

  Future<void> undislikeReel(String userId, String reelId) async {
    await _supabase.from('dislikes').delete().match({
      'user_id': userId,
      'reel_id': reelId,
    });
  }

  Future<bool> isReelDisliked(String userId, String reelId) async {
    final response = await _supabase
        .from('dislikes')
        .select('id')
        .eq('user_id', userId)
        .eq('reel_id', reelId);
    return (response as List).isNotEmpty;
  }

  Future<void> repost(String userId, String reelId) async {
    await _supabase.rpc('repost_reel', params: {'reel_id_param': reelId});
  }
}
