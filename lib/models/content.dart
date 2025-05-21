class Content {
  final String id;                     // TMDB 콘텐츠 ID (문자열화)
  final String title;                 // 제목
  final String description;           // 설명 or 개요
  final List<String> genres;          // TMDB 장르 ID 목록
  final List<String> availableOn;     // TMDB OTT provider ID 목록
  final String posterPath;            // 포스터 이미지 경로 (TMDB base URL과 결합 필요)
  final double voteAverage;           // 평점
  final int popularityScore;          // TMDB 인기 순위 지표 (정렬용)

  Content({
    required this.id,
    required this.title,
    required this.description,
    required this.genres,
    required this.availableOn,
    required this.posterPath,
    required this.voteAverage,
    required this.popularityScore,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'genres': genres,
    'availableOn': availableOn,
    'posterPath': posterPath,
    'voteAverage': voteAverage,
    'popularityScore': popularityScore,
  };

  factory Content.fromJson(Map<String, dynamic> json) => Content(
    id: json['id'].toString(),
    title: json['title'] ?? json['name'] ?? '',
    description: json['overview'] ?? '',
    genres: List<String>.from(json['genre_ids'].map((id) => id.toString())),
    availableOn: List<String>.from(json['ott_providers'] ?? []),
    posterPath: json['poster_path'] ?? '',
    voteAverage: (json['vote_average'] as num).toDouble(),
    popularityScore: (json['popularity'] as num).toInt(),
  );
}
