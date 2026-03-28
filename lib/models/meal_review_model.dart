class MealReviewItem {
  MealReviewItem({
    this.id,
    this.authorUserId,
    required this.authorName,
    this.authorEmail,
    required this.rating,
    required this.reviewText,
    this.updatedAt,
  });

  /// Server-side rating document id (when provided).
  final String? id;
  /// Author's user id when API includes `user.id` (for delete / ownership).
  final String? authorUserId;
  final String authorName;
  final String? authorEmail;
  final int rating;
  final String reviewText;
  final DateTime? updatedAt;

  factory MealReviewItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String name = 'Member';
    String? email;
    String? authorUserId;
    if (user is Map) {
      final m = Map<String, dynamic>.from(user);
      name = m['name']?.toString().trim() ?? '';
      email = m['email']?.toString();
      final idRaw = m['id'] ?? m['_id'];
      authorUserId = idRaw?.toString();
      if (name.isEmpty) {
        name = email ?? 'Member';
      }
    }
    final rawReview = json['review']?.toString().trim() ?? '';
    final updatedRaw = json['updatedAt'];
    DateTime? updated;
    if (updatedRaw != null) {
      updated = DateTime.tryParse(updatedRaw.toString());
    }
    final idRaw = json['id'] ?? json['_id'];
    return MealReviewItem(
      id: idRaw?.toString(),
      authorUserId: authorUserId,
      authorName: name,
      authorEmail: email,
      rating: (json['rating'] as num?)?.toInt().clamp(1, 5) ?? 1,
      reviewText: rawReview,
      updatedAt: updated,
    );
  }
}
