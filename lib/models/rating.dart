class Rating {
  final String userId;
  final String contentId;
  final double rating;        // 0.5 ~ 5.0, 0.5 단위
  final String? comment;

  Rating({
    required this.userId,
    required this.contentId,
    required this.rating,
    this.comment,
  }) {
    if (rating < 0.5 || rating > 5.0 || rating * 10 % 5 != 0) {
      throw ArgumentError('Rating must be in 0.5 increments between 0.5 and 5.0');
    }
  }

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      userId: json['userId'] ?? json['user_id'],
      contentId: json['contentId'] ?? json['content_id'],
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'content_id': contentId,
      'rating': rating,
      'comment': comment,
    };
  }
}
