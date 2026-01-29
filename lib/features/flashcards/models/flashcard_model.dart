class FlashcardSet {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? categoryId;
  final DateTime createdAt;
  final int cardCount;
  final Map<String, dynamic>? profile;

  FlashcardSet({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.categoryId,
    required this.createdAt,
    this.cardCount = 0,
    this.profile,
  });

  factory FlashcardSet.fromJson(Map<String, dynamic> json) {
    return FlashcardSet(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      categoryId: json['category_id'],
      createdAt: DateTime.parse(json['created_at']),
      cardCount: json['flashcards'] != null ? (json['flashcards'] as List).length : 0,
      profile: json['profiles'],
    );
  }
}

class Flashcard {
  final String id;
  final String setId;
  final String frontText;
  final String backText;

  Flashcard({
    required this.id,
    required this.setId,
    required this.frontText,
    required this.backText,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'],
      setId: json['set_id'],
      frontText: json['front_text'],
      backText: json['back_text'],
    );
  }
}
