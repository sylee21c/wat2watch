class Rating {
  final String userId;
  final String contentId;
  final double score;        // 0.5 ~ 5.0, 0.5 단위
  final String? comment;

  Rating({
    required this.userId,
    required this.contentId,
    required this.score,
    this.comment,
  }) {
    if (score < 0.5 || score > 5.0 || score * 10 % 5 != 0) {
      throw ArgumentError('Score must be in 0.5 increments between 0.5 and 5.0');
    }
  }

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      userId: json['user_id'],
      contentId: json['content_id'],
      score: (json['score'] as num).toDouble(),
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'content_id': contentId,
      'score': score,
      'comment': comment,
    };
  }
}
