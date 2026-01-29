import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/flashcard_service.dart';
import '../models/flashcard_model.dart';

class FlashcardSetsScreen extends StatefulWidget {
  const FlashcardSetsScreen({super.key});

  @override
  State<FlashcardSetsScreen> createState() => _FlashcardSetsScreenState();
}

class _FlashcardSetsScreenState extends State<FlashcardSetsScreen> {
  final FlashcardService _flashcardService = FlashcardService();
  List<FlashcardSet> _sets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    try {
      final sets = await _flashcardService.getFlashcardSets();
      if (mounted) {
        setState(() {
          _sets = sets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSet(String setId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lernset löschen?'),
        content: const Text('Möchtest du dieses Lernset wirklich unwiderruflich löschen?'),
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
        await _flashcardService.deleteFlashcardSet(setId);
        _loadSets();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lernset gelöscht')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Karteikarten'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSets,
              child: _sets.isEmpty
                  ? const Center(child: Text('Noch keine Lernsets vorhanden.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sets.length,
                      itemBuilder: (context, index) {
                        final set = _sets[index];
                        final isOwner = currentUserId == set.userId;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(set.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                                if (isOwner || isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteSet(set.id),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(set.description ?? 'Keine Beschreibung'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.copy, size: 16, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Text('${set.cardCount} Karten'),
                                    const Spacer(),
                                    Text('von @${set.profile?['username'] ?? 'unbekannt'}', 
                                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () => context.push('/flashcards/study/${set.id}'),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/flashcards/create'),
        tooltip: 'Neues Set erstellen',
        child: const Icon(Icons.add_card),
      ),
    );
  }
}
