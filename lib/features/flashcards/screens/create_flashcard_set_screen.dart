import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/flashcard_service.dart';

class CreateFlashcardSetScreen extends StatefulWidget {
  const CreateFlashcardSetScreen({super.key});

  @override
  State<CreateFlashcardSetScreen> createState() => _CreateFlashcardSetScreenState();
}

class _CreateFlashcardSetScreenState extends State<CreateFlashcardSetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<Map<String, TextEditingController>> _cardControllers = [
    {'front': TextEditingController(), 'back': TextEditingController()}
  ];
  
  final FlashcardService _flashcardService = FlashcardService();
  String? _selectedCategory;
  List<Map<String, dynamic>> _dbCategories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;

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

  void _addCard({String? front, String? back}) {
    setState(() {
      _cardControllers.add({
        'front': TextEditingController(text: front ?? ''),
        'back': TextEditingController(text: back ?? '')
      });
    });
  }

  void _removeCard(int index) {
    if (_cardControllers.length > 1) {
      setState(() {
        _cardControllers.removeAt(index);
      });
    }
  }

  String _cleanText(String text) {
    if (text.isEmpty) return '';
    String cleaned = text.replaceAll(RegExp(r'<br\s*/?>|<div>|</div>'), '\n');
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ');
    cleaned = cleaned.trim();
    if (cleaned.length >= 2 && cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1).trim();
    }
    return cleaned.replaceAll(RegExp(r' +'), ' ').replaceAll(RegExp(r'\n+'), '\n').trim();
  }

  Future<void> _importCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      String content = utf8.decode(bytes, allowMalformed: true);

      // Wir versuchen verschiedene Trennzeichen mit dem CsvToListConverter
      List<List<dynamic>> rows = [];
      
      // Priorität: NotebookLM/Standard CSV (Kommata)
      try {
        rows = const CsvToListConverter(
          fieldDelimiter: ',',
          textDelimiter: '"',
          eol: '\n',
          shouldParseNumbers: false,
        ).convert(content);
        
        // Falls nur eine Spalte erkannt wurde, probieren wir Semikolon (Anki/Excel)
        if (rows.isNotEmpty && rows[0].length < 2) {
          rows = const CsvToListConverter(
            fieldDelimiter: ';',
            textDelimiter: '"',
            eol: '\n',
            shouldParseNumbers: false,
          ).convert(content);
        }
        
        // Letzter Versuch: Tabulator (Anki Standard)
        if (rows.isNotEmpty && rows[0].length < 2) {
          rows = const CsvToListConverter(
            fieldDelimiter: '\t',
            textDelimiter: '"',
            eol: '\n',
            shouldParseNumbers: false,
          ).convert(content);
        }
      } catch (e) {
        debugPrint('CSV Parsing Fehler: $e');
      }

      if (rows.isNotEmpty) {
        // Header-Erkennung
        int startIndex = 0;
        String firstCell = rows[0][0].toString().toLowerCase();
        if (firstCell.contains('question') || firstCell.contains('vorderseite') || firstCell.contains('front')) {
          startIndex = 1;
        }

        int importedCount = 0;
        setState(() {
          if (_cardControllers.length == 1 && 
              _cardControllers[0]['front']!.text.isEmpty && 
              _cardControllers[0]['back']!.text.isEmpty) {
            _cardControllers.clear();
          }

          for (var i = startIndex; i < rows.length; i++) {
            var row = rows[i];
            if (row.length >= 2) {
              String front = _cleanText(row[0].toString());
              String back = _cleanText(row[1].toString());
              
              if (front.isNotEmpty || back.isNotEmpty) {
                _cardControllers.add({
                  'front': TextEditingController(text: front),
                  'back': TextEditingController(text: back)
                });
                importedCount++;
              }
            }
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$importedCount Karten erfolgreich importiert!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Import: $e')),
        );
      }
    }
  }

  Future<void> _saveSet() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    try {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId == null) return;

      final cards = _cardControllers.map((controllers) => {
        'front': controllers['front']!.text.trim(),
        'back': controllers['back']!.text.trim(),
      }).toList();

      await _flashcardService.createFlashcardSet(
        userId: userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategory,
        cards: cards,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lernset erfolgreich erstellt!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neues Lernset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveSet,
          ),
        ],
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titel des Sets',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Bitte Titel eingeben' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Beschreibung (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _importCsvFile,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Set importieren (.txt / .csv)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      side: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategorie',
                      border: OutlineInputBorder(),
                    ),
                    items: _dbCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat['id'].toString(),
                        child: Text('${cat['icon'] ?? ''} ${cat['name']}'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value),
                  ),
                  const SizedBox(height: 16),
                  const Text('Karten', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...List.generate(_cardControllers.length, (index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Karte ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (_cardControllers.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeCard(index),
                                  ),
                              ],
                            ),
                            TextFormField(
                              controller: _cardControllers[index]['front'],
                              decoration: const InputDecoration(labelText: 'Vorderseite (Frage)'),
                              validator: (value) => value == null || value.isEmpty ? 'Pflichtfeld' : null,
                              maxLines: null,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _cardControllers[index]['back'],
                              decoration: const InputDecoration(labelText: 'Rückseite (Antwort)'),
                              validator: (value) => value == null || value.isEmpty ? 'Pflichtfeld' : null,
                              maxLines: null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  ElevatedButton.icon(
                    onPressed: _addCard,
                    icon: const Icon(Icons.add),
                    label: const Text('Manuell Karte hinzufügen'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveSet,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Set veröffentlichen', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controllers in _cardControllers) {
      controllers['front']!.dispose();
      controllers['back']!.dispose();
    }
    super.dispose();
  }
}
