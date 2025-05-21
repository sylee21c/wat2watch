class User {
  final String id;
  final String username;
  final String passwordHash;
  final List<String> subscribedOttServices; // ex: ["8", "97"] → TMDB provider ID
  final List<String> preferredGenres;       // ex: ["18", "10765"] → TMDB genre ID
  final List<String> favoriteContents;      // TMDB 콘텐츠 ID 목록

  User({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.subscribedOttServices,
    required this.preferredGenres,
    List<String>? favoriteContents,
  }) : favoriteContents = favoriteContents ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'passwordHash': passwordHash,
    'subscribedOttServices': subscribedOttServices,
    'preferredGenres': preferredGenres,
    'favoriteContents': favoriteContents,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    username: json['username'],
    passwordHash: json['passwordHash'],
    subscribedOttServices: List<String>.from(json['subscribedOttServices']),
    preferredGenres: List<String>.from(json['preferredGenres']),
    favoriteContents: List<String>.from(json['favoriteContents'] ?? []),
  );
}
