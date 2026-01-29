import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/profile_service.dart';
import '../models/profile_model.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  ProfileModel? _profile;
  Map<String, int> _stats = {'posts': 0, 'followers': 0, 'following': 0};
  List<dynamic> _userItems = [];
  bool _isLoading = true;
  late TabController _tabController;
  int _selectedTab = 0; // 0 für Posts, 1 für Reels

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadProfile();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTab = _tabController.index;
      });
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = await _profileService.getProfile(userId);
      final stats = await _profileService.getProfileStats(userId);
      
      // Lade Daten basierend auf dem Tab
      List<dynamic> items;
      if (_selectedTab == 0) {
        items = await _profileService.getUserPosts(userId);
      } else {
        items = await _profileService.getUserReels(userId);
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _stats = stats;
          _userItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Laden des Profils: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_selectedTab == 0 ? 'Post löschen?' : 'Reel löschen?'),
        content: const Text('Möchtest du diesen Beitrag wirklich unwiderruflich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
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
        if (_selectedTab == 0) {
          await _profileService.deletePost(id);
        } else {
          await _profileService.deleteReel(id);
        }
        _loadProfile(); // Profil neu laden
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Beitrag gelöscht')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Löschen: $e')),
          );
        }
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (image == null) return;

      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;
      
      if (userId == null) return;

      setState(() => _isLoading = true);
      
      await _profileService.uploadAvatar(userId, File(image.path));
      await _loadProfile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profilbild aktualisiert')),
        );
      }
    } on PlatformException catch (e) {
      debugPrint('Platform Fehler beim Bild-Picker: $e');
    } catch (e) {
      debugPrint('Allgemeiner Fehler beim Bild-Picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_profile?.username ?? 'Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              await authProvider.signOut();
              if (mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _profile?.avatarUrl != null
                                ? CachedNetworkImageProvider(_profile!.avatarUrl!)
                                : null,
                            child: _profile?.avatarUrl == null
                                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          if (_isLoading)
                            const Positioned.fill(
                              child: CircularProgressIndicator(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _profile?.fullName ?? 'Kein Name',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '@${_profile?.username ?? ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_profile!.bio!, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('Posts', _stats['posts']!),
                        _buildStatColumn('Follower', _stats['followers']!),
                        _buildStatColumn('Folgt', _stats['following']!),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          if (_profile == null) return;
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(profile: _profile!),
                            ),
                          );
                          if (result == true) {
                            _loadProfile();
                          }
                        },
                        child: const Text('Profil bearbeiten'),
                      ),
                    ),
                    // ZAHNRAD BUTTON FÜR EINSTELLUNGEN
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => context.push('/settings'),
                      tooltip: 'Einstellungen',
                    ),
                  ],
                ),
              ),
            ),
            // Tab-Bar für Posts und Reels
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).primaryColor,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on)),
                    Tab(icon: Icon(Icons.play_circle_outline)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(4),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _userItems.length) return null;
                    final item = _userItems[index];
                    
                    // Thumbnail Logik
                    String? thumbnailUrl;
                    if (_selectedTab == 0) {
                      thumbnailUrl = item['image_url'];
                    } else {
                      thumbnailUrl = item['thumbnail_url'];
                    }

                    return GestureDetector(
                      onLongPress: () => _deleteItem(item['id']),
                      onTap: () {
                        // Details
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: thumbnailUrl ?? '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: Icon(_selectedTab == 0 ? Icons.image : Icons.play_arrow),
                            ),
                          ),
                          if (_selectedTab == 1)
                            const Positioned(
                              bottom: 4,
                              left: 4,
                              child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
                            ),
                        ],
                      ),
                    );
                  },
                  childCount: _userItems.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
