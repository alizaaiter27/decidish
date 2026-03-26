import 'package:decidish/models/meal_model.dart';

class FeedPostModel {
  final String id;
  final String content;
  final String? createdAt;
  final int likesCount;
  final bool likedByMe;
  final FeedPostAuthor? user;

  FeedPostModel({
    required this.id,
    required this.content,
    this.createdAt,
    this.likesCount = 0,
    this.likedByMe = false,
    this.user,
  });

  factory FeedPostModel.fromJson(Map<String, dynamic> json) {
    return FeedPostModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] == true,
      user: json['user'] != null
          ? FeedPostAuthor.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : null,
    );
  }
}

class FeedPostAuthor {
  final String id;
  final String? name;
  final String? email;

  FeedPostAuthor({required this.id, this.name, this.email});

  factory FeedPostAuthor.fromJson(Map<String, dynamic> json) {
    return FeedPostAuthor(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString(),
      email: json['email']?.toString(),
    );
  }
}

class FeedSectionModel {
  final String id;
  final String title;
  final String? subtitle;
  final List<MealModel> meals;
  final List<FeedPostModel> posts;

  FeedSectionModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.meals = const [],
    this.posts = const [],
  });

  factory FeedSectionModel.fromJson(Map<String, dynamic> json) {
    final mealsRaw = json['meals'] as List<dynamic>? ?? [];
    final postsRaw = json['posts'] as List<dynamic>? ?? [];
    return FeedSectionModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      meals: mealsRaw
          .map((e) => MealModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      posts: postsRaw
          .map((e) => FeedPostModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
