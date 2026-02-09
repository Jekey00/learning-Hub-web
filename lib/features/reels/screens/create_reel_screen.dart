import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
  final _youtubeUrlController = TextEditingController();
  final ReelService _reelService = ReelService();
  final ImagePicker _picker = ImagePicker();
  
  String? _selectedCategory;
  List<Map<String, dynamic>> _dbCategories = [];
  bool _isLoadingCategories = true;
  bool _isUploading = false;
  File? _selectedVideo;
  bool _isYoutubeMode = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('categories').select().order('name');
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
        _isYoutubeMode = false;
        _youtubeUrlController.clear();
      });
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_isYoutubeMode && _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte wähle ein Video oder gib einen YouTube-Link ein')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId == null) return;

      String videoUrl = '';
      String? youtubeId;

      if (_isYoutubeMode) {
        youtubeId = YoutubePlayer.convertUrlToId(_youtubeUrlController.text.trim());
        if (youtubeId == null) throw Exception('Ungültige YouTube URL');
        videoUrl = 'https://www.youtube.com/watch?v=$youtubeId';
      } else {
        // Bestehende Logik für Video-Kompression und Upload
        final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
          _selectedVideo!.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );
        if (mediaInfo == null || mediaInfo.file == null) throw Exception('Komprimierung fehlgeschlagen');
        
        final fileName = '${const Uuid().v4()}.mp4';
        await Supabase.instance.client.storage.from('reels').upload(fileName, mediaInfo.file!);
        videoUrl = Supabase.instance.client.storage.from('reels').getPublicUrl(fileName);
        await VideoCompress.deleteAllCache();
      }

      await _reelService.createReel(
        userId: userId,
        title: _topicController.text.trim(),
        videoUrl: videoUrl,
        youtubeId: youtubeId,
        categoryId: _selectedCategory,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erfolgreich veröffentlicht!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Neues Reel')),
      body: _isLoadingCategories 
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  const Text('Wie möchtest du das Video hinzufügen?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Datei-Upload'),
                          selected: !_isYoutubeMode,
                          onSelected: (val) => setState(() => _isYoutubeMode = !val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('YouTube Link'),
                          selected: _isYoutubeMode,
                          onSelected: (val) => setState(() => _isYoutubeMode = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Kategorie wählen', border: OutlineInputBorder()),
                    items: _dbCategories.map((cat) => DropdownMenuItem(value: cat['id'].toString(), child: Text('${cat['icon'] ?? ''} ${cat['name']}'))).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value),
                    validator: (value) => value == null ? 'Pflichtfeld' : null,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _topicController,
                    decoration: const InputDecoration(labelText: 'Titel / Thema', border: OutlineInputBorder()),
                    validator: (value) => (value == null || value.isEmpty) ? 'Bitte gib einen Titel ein' : null,
                  ),
                  const SizedBox(height: 24),
                  if (_isYoutubeMode)
                    TextFormField(
                      controller: _youtubeUrlController,
                      decoration: const InputDecoration(labelText: 'YouTube Video URL', hintText: 'https://www.youtube.com/watch?v=...', border: OutlineInputBorder()),
                      validator: (value) => (_isYoutubeMode && (value == null || value.isEmpty)) ? 'Bitte YouTube Link eingeben' : null,
                    )
                  else
                    Column(
                      children: [
                        if (_selectedVideo != null) Text('Video bereit: ${_selectedVideo!.path.split('/').last}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(onPressed: _isUploading ? null : _pickVideo, icon: const Icon(Icons.movie_outlined), label: const Text('Video aus Galerie wählen'))),
                      ],
                    ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _handleUpload,
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text('Veröffentlichen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    _youtubeUrlController.dispose();
    super.dispose();
  }
}
