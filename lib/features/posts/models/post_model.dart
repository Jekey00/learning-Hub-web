class PostModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? categoryId;
  final DateTime createdAt;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? category;

  PostModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.imageUrl,
    this.categoryId,
    required this.createdAt,
    this.profile,
    this.category,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      categoryId: json['category_id'],
      createdAt: DateTime.parse(json['created_at']),
      profile: json['profiles'],
      category: json['categories'],
    );
  }
}
