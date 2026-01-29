class ReelModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? categoryId;
  final int? duration;
  final DateTime createdAt;
  final Map<String, dynamic>? profile;

  ReelModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    this.categoryId,
    this.duration,
    required this.createdAt,
    this.profile,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      videoUrl: json['video_url'],
      thumbnailUrl: json['thumbnail_url'],
      categoryId: json['category_id'],
      duration: json['duration'],
      createdAt: DateTime.parse(json['created_at']),
      profile: json['profiles'],
    );
  }
}
