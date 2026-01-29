import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/reel_service.dart';

class CreateReelScreen extends StatefulWidget {
  const CreateReelScreen({super.key});

  @override
  State<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<CreateReelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final ReelService _reelService = ReelService();
  final ImagePicker _picker = ImagePicker();
  
  String? _selectedCategory;
  List<Map<String, dynamic>> _dbCategories = [];
  bool _isLoadingCategories = true;
  bool _isUploading = false;
  File? _selectedVideo;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('categories')
          .select()
          .order('name');
      
      if (mounted) {
        setState(() {
          _dbCategories = List<Map<String, dynamic>>.from(response);
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = File(video.path);
      });
    }
  }

  Future<void> _uploadOwnVideo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wähle zuerst ein Video aus')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wähle eine Kategorie')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;
      if (userId == null) return;

      // VIDEO KOMPRIMIERUNG
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        _selectedVideo!.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );

      if (mediaInfo == null || mediaInfo.file == null) {
        throw Exception('Komprimierung fehlgeschlagen');
      }

      final compressedFile = mediaInfo.file!;
      final supabase = Supabase.instance.client;
      final fileName = '${const Uuid().v4()}.mp4';
      
      // 1. Komprimiertes Video in Storage hochladen
      await supabase.storage.from('reels').upload(fileName, compressedFile);
      final videoUrl = supabase.storage.from('reels').getPublicUrl(fileName);

      // 2. Datenbank-Eintrag erstellen
      await _reelService.createReel(
        userId: userId,
        title: _topicController.text.trim(),
        description: 'Benutzer Video',
        videoUrl: videoUrl,
        categoryId: _selectedCategory,
      );

      // Cache leeren
      await VideoCompress.deleteAllCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reel erfolgreich veröffentlicht!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reel erstellen'),
      ),
      body: _isLoadingCategories 
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Veröffentliche dein eigenes Video',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategorie wählen',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _dbCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat['id'].toString(),
                        child: Text('${cat['icon'] ?? ''} ${cat['name']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                    validator: (value) => value == null ? 'Pflichtfeld' : null,
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _topicController,
                    decoration: const InputDecoration(
                      labelText: 'Titel / Thema',
                      hintText: 'Was ist in deinem Video zu sehen?',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte gib einen Titel ein';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  if (_selectedVideo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text('Video ausgewählt: ${_selectedVideo!.path.split('/').last}', 
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickVideo,
                      icon: const Icon(Icons.movie_outlined),
                      label: const Text('Video aus Galerie wählen'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (_isUploading || _selectedVideo == null) ? null : _uploadOwnVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isUploading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(width: 16),
                                Text('Wird komprimiert & hochgeladen...'),
                              ],
                            )
                          : const Text(
                              'Reel veröffentlichen',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }
}
