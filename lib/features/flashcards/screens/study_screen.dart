import 'package:flutter/material.dart';
import '../services/flashcard_service.dart';
import '../models/flashcard_model.dart';

class StudyScreen extends StatefulWidget {
  final String setId;

  const StudyScreen({super.key, required this.setId});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final FlashcardService _flashcardService = FlashcardService();
  List<Flashcard> _cards = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await _flashcardService.getCardsInSet(widget.setId);
      if (mounted) {
        setState(() {
          _cards = cards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _showBack = false;
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Glückwunsch!'),
          content: const Text('Du hast alle Karten in diesem Set gelernt.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Fertig'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_cards.isEmpty) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Keine Karten in diesem Set.')));

    final card = _cards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Lernen: ${_currentIndex + 1}/${_cards.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'App-Informationen',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Learning Hub',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.hub, color: Colors.blue, size: 40),
                applicationLegalese: '© 2025 Justyn Kuhne\nApache 2.0 Lizenz',
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Dieses Projekt ist Open Source. Gemäß der Apache 2.0 Lizenz darf der Code unter Namensnennung genutzt, verändert und verbreitet werden.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showBack = !_showBack),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: _showBack ? Colors.blue.shade50 : Colors.white,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showBack ? 'ANTWORT' : 'FRAGE',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _showBack ? card.backText : card.frontText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (_showBack)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton('Nochmal', Colors.red, _nextCard),
                  _buildActionButton('Gut', Colors.green, _nextCard),
                ],
              )
            else
              const Text('Tippe auf die Karte, um die Antwort zu sehen', 
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}
