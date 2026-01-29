import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<ProfileModel?> getProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return ProfileModel.fromJson(response);
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? bio,
  }) async {
    await _supabase.from('profiles').update({
      if (fullName != null) 'full_name': fullName,
      if (bio != null) 'bio': bio,
    }).eq('id', userId);
  }

  Future<String?> uploadAvatar(String userId, File file) async {
    final fileExt = file.path.split('.').last;
    final fileName = '$userId.$fileExt';
    
    await _supabase.storage
        .from('avatars')
        .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

    final url = _supabase.storage.from('avatars').getPublicUrl(fileName);
    
    await _supabase
        .from('profiles')
        .update({'avatar_url': url}).eq('id', userId);

    return url;
  }

  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    final response = await _supabase
        .from('posts')
        .select('*, profiles(*), categories(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getUserReels(String userId) async {
    final response = await _supabase
        .from('reels')
        .select('*, profiles(*), categories(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deletePost(String postId) async {
    await _supabase.from('posts').delete().eq('id', postId);
  }

  Future<void> deleteReel(String reelId) async {
    await _supabase.from('reels').delete().eq('id', reelId);
  }

  Future<void> followUser(String followerId, String followingId) async {
    await _supabase.from('follows').insert({
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  Future<void> unfollowUser(String followerId, String followingId) async {
    await _supabase.from('follows').delete().match({
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    final response = await _supabase
        .from('follows')
        .select('id')
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
    
    return (response as List).isNotEmpty;
  }

  Future<Map<String, int>> getProfileStats(String userId) async {
    final posts = await _supabase
        .from('posts')
        .select('id')
        .eq('user_id', userId);

    final followers = await _supabase
        .from('follows')
        .select('id')
        .eq('following_id', userId);

    final following = await _supabase
        .from('follows')
        .select('id')
        .eq('follower_id', userId);

    return {
      'posts': (posts as List).length,
      'followers': (followers as List).length,
      'following': (following as List).length,
    };
  }
}
