import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';

class PostService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PostModel>> getFeedPosts({String? categoryId}) async {
    dynamic query = _supabase
        .from('posts')
        .select('*, profiles(*), categories(*)');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((e) => PostModel.fromJson(e)).toList();
  }

  Future<void> createPost({
    required String userId,
    required String title,
    String? description,
    File? image,
    String? categoryId,
  }) async {
    String? imageUrl;

    if (image != null) {
      imageUrl = await _uploadImage(image);
    }

    await _supabase.from('posts').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'category_id': categoryId,
    });
  }

  Future<String> _uploadImage(File file) async {
    final fileExt = file.path.split('.').last;
    final fileName = '${const Uuid().v4()}.$fileExt';

    await _supabase.storage.from('post-images').upload(fileName, file);

    return _supabase.storage.from('post-images').getPublicUrl(fileName);
  }

  // --- LIKE LOGIK ---
  Future<void> likePost(String userId, String postId) async {
    await _supabase.from('likes').upsert({
      'user_id': userId,
      'post_id': postId,
    });
  }

  Future<void> unlikePost(String userId, String postId) async {
    await _supabase.from('likes').delete().match({
      'user_id': userId,
      'post_id': postId,
    });
  }

  Future<bool> isPostLiked(String userId, String postId) async {
    final response = await _supabase
        .from('likes')
        .select('id')
        .eq('user_id', userId)
        .eq('post_id', postId);

    return (response as List).isNotEmpty;
  }

  Future<int> getPostLikesCount(String postId) async {
    final response = await _supabase
        .from('likes')
        .select('id')
        .eq('post_id', postId);

    return (response as List).length;
  }

  // --- DISLIKE LOGIK ---
  Future<void> dislikePost(String userId, String postId) async {
    await _supabase.from('dislikes').upsert({
      'user_id': userId,
      'post_id': postId,
    });
  }

  Future<void> undislikePost(String userId, String postId) async {
    await _supabase.from('dislikes').delete().match({
      'user_id': userId,
      'post_id': postId,
    });
  }

  Future<bool> isPostDisliked(String userId, String postId) async {
    final response = await _supabase
        .from('dislikes')
        .select('id')
        .eq('user_id', userId)
        .eq('post_id', postId);

    return (response as List).isNotEmpty;
  }

  Future<int> getPostDislikesCount(String postId) async {
    final response = await _supabase
        .from('dislikes')
        .select('id')
        .eq('post_id', postId);

    return (response as List).length;
  }

  Future<void> repost(String userId, String postId) async {
    await likePost(userId, postId);
    await _supabase.rpc('repost_post', params: {'post_id_param': postId});
  }
}
