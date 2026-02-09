import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/services/profile_service.dart';
import '../models/reel_model.dart';
import '../services/reel_service.dart';

class ReelsScreen extends StatefulWidget {
  final String? categoryId;

  const ReelsScreen({super.key, this.categoryId});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with WidgetsBindingObserver {
  final ReelService _reelService = ReelService();
  List<ReelModel> _reels = [];
  bool _isLoading = true;
  final PageController _pageController = PageController();
  bool _autoPlay = true;
  final _storage = const FlutterSecureStorage();
  bool _isScreenActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _loadReels();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (mounted) setState(() => _isScreenActive = false);
    } else if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() => _isScreenActive = true);
    }
  }

  Future<void> _loadSettings() async {
    final autoPlay = await _storage.read(key: 'auto_play_reels');
    if (autoPlay != null) {
      setState(() {
        _autoPlay = autoPlay == 'true';
      });
    }
  }

  Future<void> _loadReels() async {
    try {
      final reels = await _reelService.getReels(categoryId: widget.categoryId);
      if (mounted) {
        setState(() {
          _reels = reels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onReelDeleted(String id) {
    setState(() {
      _reels.removeWhere((reel) => reel.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _reels.isEmpty
                  ? const Center(child: Text('Keine Reels vorhanden', style: TextStyle(color: Colors.white)))
                  : PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: _reels.length,
                      itemBuilder: (context, index) {
                        return ReelPlayer(
                          key: ValueKey(_reels[index].id),
                          reel: _reels[index], 
                          autoPlay: _autoPlay, 
                          onAction: _loadReels,
                          onDeleted: () => _onReelDeleted(_reels[index].id),
                          isScreenActive: _isScreenActive,
                        );
                      },
                    ),
          
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton(
              onPressed: () {
                if (mounted) setState(() => _isScreenActive = false);
                context.push('/create-reel').then((_) {
                  if (mounted) {
                    setState(() => _isScreenActive = true);
                    _loadReels();
                  }
                });
              },
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
          
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class ReelPlayer extends StatefulWidget {
  final ReelModel reel;
  final bool autoPlay;
  final VoidCallback onAction;
  final VoidCallback onDeleted;
  final bool isScreenActive;

  const ReelPlayer({
    super.key, 
    required this.reel, 
    required this.autoPlay, 
    required this.onAction,
    required this.onDeleted,
    required this.isScreenActive,
  });

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  bool _isInitialized = false;
  final ReelService _reelService = ReelService();
  final ProfileService _profileService = ProfileService();
  bool _isFollowing = false;
  bool _isLiked = false;
  bool _isDisliked = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _checkStatus();
  }

  @override
  void didUpdateWidget(ReelPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInitialized) {
      if (!widget.isScreenActive) {
        _videoController?.pause();
        _youtubeController?.pause();
      } else if (widget.autoPlay && oldWidget.isScreenActive == false) {
        if (widget.reel.youtubeId == null) {
          _videoController?.play();
        } else {
          _youtubeController?.play();
        }
      }
    }
  }

  Future<void> _checkStatus() async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    if (currentUserId == null) return;

    try {
      final following = await _profileService.isFollowing(currentUserId, widget.reel.userId);
      final liked = await _reelService.isReelLiked(currentUserId, widget.reel.id);
      final disliked = await _reelService.isReelDisliked(currentUserId, widget.reel.id);
      
      if (mounted) {
        setState(() {
          _isFollowing = following;
          _isLiked = liked;
          _isDisliked = disliked;
        });
      }
    } catch (e) {}
  }

  Future<void> _deleteReel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reel löschen?'),
        content: const Text('Möchtest du dieses Reel wirklich unwiderruflich löschen?'),
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
      try {
        await _reelService.deleteReel(widget.reel.id, widget.reel.videoUrl);
        widget.onDeleted();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reel gelöscht')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler beim Löschen: $e')));
        }
      }
    }
  }

  Future<void> _toggleFollow() async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    if (currentUserId == null || currentUserId == widget.reel.userId) return;

    if (_isFollowing) {
      await _profileService.unfollowUser(currentUserId, widget.reel.userId);
      if (mounted) setState(() => _isFollowing = false);
    } else {
      await _profileService.followUser(currentUserId, widget.reel.userId);
      if (mounted) setState(() => _isFollowing = true);
    }
  }

  Future<void> _toggleLike() async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    if (currentUserId == null) return;

    if (_isLiked) {
      await _reelService.unlikeReel(currentUserId, widget.reel.id);
      if (mounted) setState(() => _isLiked = false);
    } else {
      if (_isDisliked) await _toggleDislike();
      await _reelService.likeReel(currentUserId, widget.reel.id);
      if (mounted) setState(() => _isLiked = true);
    }
  }

  Future<void> _toggleDislike() async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    if (currentUserId == null) return;

    if (_isDisliked) {
      await _reelService.undislikeReel(currentUserId, widget.reel.id);
      if (mounted) setState(() => _isDisliked = false);
    } else {
      if (_isLiked) await _toggleLike();
      await _reelService.dislikeReel(currentUserId, widget.reel.id);
      if (mounted) setState(() => _isDisliked = true);
    }
  }

  Future<void> _initializePlayer() async {
    if (widget.reel.youtubeId != null && widget.reel.youtubeId!.isNotEmpty) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: widget.reel.youtubeId!,
        flags: YoutubePlayerFlags(
          autoPlay: widget.autoPlay && widget.isScreenActive,
          mute: false,
          loop: true,
          isLive: false,
          forceHD: false,
          enableCaption: true,
        ),
      );
      _isInitialized = true;
    } else if (widget.reel.videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: widget.autoPlay && widget.isScreenActive,
        looping: true,
        showControls: true,
        aspectRatio: 9 / 16,
      );
      _isInitialized = true;
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const Center(child: CircularProgressIndicator());
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    final isOwnReel = currentUserId == widget.reel.userId;
    final isAdmin = authProvider.isAdmin;

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: widget.reel.youtubeId != null && widget.reel.youtubeId!.isNotEmpty
              ? YoutubePlayer(
                  controller: _youtubeController!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.blueAccent,
                )
              : (_chewieController != null ? Chewie(controller: _chewieController!) : const Text('Video nicht verfügbar')),
        ),
        Positioned(
          bottom: 80,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: widget.reel.profile?['avatar_url'] != null
                        ? NetworkImage(widget.reel.profile!['avatar_url'])
                        : null,
                    child: widget.reel.profile?['avatar_url'] == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '@${widget.reel.profile?['username'] ?? 'Unknown'}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (!isOwnReel) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _toggleFollow,
                      child: Text(_isFollowing ? 'Entfolgen' : 'Folgen', style: const TextStyle(color: Colors.blue)),
                    ),
                  ],
                  if (isAdmin || isOwnReel)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: _deleteReel,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(widget.reel.title, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            children: [
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border, 
                  color: _isLiked ? Colors.red : Colors.white,
                ),
                iconSize: 32,
                onPressed: _toggleLike,
              ),
              const SizedBox(height: 16),
              IconButton(
                icon: Text(
                  '💩',
                  style: TextStyle(
                    fontSize: 32,
                    color: _isDisliked ? Colors.brown : Colors.white.withOpacity(0.7),
                  ),
                ),
                onPressed: _toggleDislike,
              ),
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(Icons.repeat, color: Colors.white),
                iconSize: 32,
                onPressed: () async {
                  if (currentUserId != null) {
                    await _reelService.repost(currentUserId, widget.reel.id);
                    widget.onAction();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reel wurde nach oben gepusht!')));
                  }
                },
              ),
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                iconSize: 32,
                onPressed: () => Share.share('Schau dir dieses Reel an: ${widget.reel.videoUrl}'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }
}
