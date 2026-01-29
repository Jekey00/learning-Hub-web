import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../posts/models/post_model.dart';
import '../../posts/services/post_service.dart';
import '../../profile/services/profile_service.dart';
import '../widgets/category_filter.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PostService _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoading = true;
  String? _selectedCategory;
  bool _showFilter = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final posts = await _postService.getFeedPosts(
        categoryId: _selectedCategory,
      );
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Laden des Feeds: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Hub'),
        actions: [
          IconButton(
            icon: Icon(_showFilter ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilter = !_showFilter;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilter)
            CategoryFilter(
              selectedCategory: _selectedCategory,
              onCategoryChanged: (categoryId) {
                setState(() {
                  _selectedCategory = categoryId;
                });
                _loadPosts();
              },
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadPosts,
                    child: _posts.isEmpty 
                      ? const Center(child: Text('Keine Posts in dieser Kategorie'))
                      : ListView.builder(
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
                            final post = _posts[index];
                            return PostCard(post: post, onReposted: _loadPosts);
                          },
                        ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-post'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback onReposted;

  const PostCard({super.key, required this.post, required this.onReposted});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isDisliked = false;
  int _dislikesCount = 0;
  bool _isReposting = false;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadInteractionStatus();
    _checkFollowStatus();
  }

  Future<void> _loadInteractionStatus() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    
    if (userId == null) return;

    try {
      final isLiked = await _postService.isPostLiked(userId, widget.post.id);
      final likeCount = await _postService.getPostLikesCount(widget.post.id);
      final isDisliked = await _postService.isPostDisliked(userId, widget.post.id);
      final dislikeCount = await _postService.getPostDislikesCount(widget.post.id);

      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _likesCount = likeCount;
          _isDisliked = isDisliked;
          _dislikesCount = dislikeCount;
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Laden des Status: $e');
    }
  }

  Future<void> _checkFollowStatus() async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    final postUserId = widget.post.userId;

    if (currentUserId == null || currentUserId == postUserId) return;

    try {
      final following = await _profileService.isFollowing(currentUserId, postUserId);
      if (mounted) {
        setState(() {
          _isFollowing = following;
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Check Follow Status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    final postUserId = widget.post.userId;

    if (currentUserId == null || currentUserId == postUserId) return;

    try {
      if (_isFollowing) {
        await _profileService.unfollowUser(currentUserId, postUserId);
        if (mounted) setState(() => _isFollowing = false);
      } else {
        await _profileService.followUser(currentUserId, postUserId);
        if (mounted) setState(() => _isFollowing = true);
      }
    } catch (e) {
      debugPrint('Fehler beim Togglen von Follow: $e');
    }
  }

  Future<void> _toggleLike() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    if (userId == null) return;

    try {
      if (_isLiked) {
        await _postService.unlikePost(userId, widget.post.id);
        if (mounted) setState(() { _isLiked = false; _likesCount--; });
      } else {
        if (_isDisliked) await _toggleDislike(); // Dislike entfernen wenn geliked wird
        await _postService.likePost(userId, widget.post.id);
        if (mounted) setState(() { _isLiked = true; _likesCount++; });
      }
    } catch (e) {}
  }

  Future<void> _toggleDislike() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    if (userId == null) return;

    try {
      if (_isDisliked) {
        await _postService.undislikePost(userId, widget.post.id);
        if (mounted) setState(() { _isDisliked = false; _dislikesCount--; });
      } else {
        if (_isLiked) await _toggleLike(); // Like entfernen wenn disliket wird
        await _postService.dislikePost(userId, widget.post.id);
        if (mounted) setState(() { _isDisliked = true; _dislikesCount++; });
      }
    } catch (e) {}
  }

  Future<void> _handleRepost() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    if (userId == null) return;

    setState(() => _isReposting = true);

    try {
      await _postService.repost(userId, widget.post.id);
      widget.onReposted();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beitrag wurde nach oben gepusht!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Repost fehlgeschlagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isReposting = false);
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post löschen?'),
        content: const Text('Möchtest du diesen Post wirklich löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Supabase.instance.client.from('posts').delete().eq('id', widget.post.id);
      widget.onReposted();
    }
  }

  void _handleShare() {
    Share.share('Schau dir diesen Post von ${widget.post.profile?['username']} auf Tech Hub an: ${widget.post.title}');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    final isOwnPost = currentUserId == widget.post.userId;
    final isAdmin = authProvider.isAdmin;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.post.profile?['avatar_url'] != null
                  ? CachedNetworkImageProvider(
                      widget.post.profile!['avatar_url'])
                  : null,
              child: widget.post.profile?['avatar_url'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(widget.post.profile?['username'] ?? 'Unknown'),
            subtitle: Text(
              widget.post.category?['name'] ?? '',
              style: TextStyle(color: Colors.blue[700]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAdmin || isOwnPost)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _deletePost,
                  ),
                if (!isOwnPost)
                  TextButton(
                    onPressed: _toggleFollow,
                    child: Text(
                      _isFollowing ? 'Entfolgen' : 'Folgen',
                      style: TextStyle(color: _isFollowing ? Colors.grey : Colors.blue),
                    ),
                  )
                else
                  Text(_formatDate(widget.post.createdAt), style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          if (widget.post.imageUrl != null)
            CachedNetworkImage(
              imageUrl: widget.post.imageUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 300,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const SizedBox(
                height: 200,
                child: Center(child: Icon(Icons.error)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.post.description != null) ...[
                  const SizedBox(height: 8),
                  Text(widget.post.description!),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    // LIKE
                    IconButton(
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : null,
                      ),
                      onPressed: _toggleLike,
                    ),
                    Text('$_likesCount'),
                    const SizedBox(width: 12),
                    
                    // DISLIKE (💩)
                    IconButton(
                      icon: Text(
                        '💩', 
                        style: TextStyle(
                          fontSize: 24,
                          color: _isDisliked ? Colors.brown : Colors.grey.withOpacity(0.5),
                        ),
                      ),
                      onPressed: _toggleDislike,
                      tooltip: 'Dislike',
                    ),
                    Text('$_dislikesCount'),
                    
                    const SizedBox(width: 16),
                    
                    // REPOST
                    IconButton(
                      icon: _isReposting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.repeat),
                      onPressed: _isReposting ? null : _handleRepost,
                      tooltip: 'Repost & Push nach oben',
                    ),
                    
                    const Spacer(),
                    
                    // SHARE
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: _handleShare,
                      tooltip: 'Teilen',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}.${date.month}.${date.year}';
    } else if (diff.inDays > 0) {
      return 'vor ${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return 'vor ${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return 'vor ${diff.inMinutes}m';
    } else {
      return 'Gerade eben';
    }
  }
}
