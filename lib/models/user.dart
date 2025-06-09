class User {
  final String id;
  final String name;
  final List<String> subscribedOtt;
  final List<String> favorites;
  final List<String> watched;
  final List<String> favoriteGenres;

  User({
    required this.id,
    required this.name,
    required this.subscribedOtt,
    required this.favorites,
    required this.watched,
    required this.favoriteGenres,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      subscribedOtt: (json['subscribed_ott'] ?? []).cast<String>(),
      favorites: (json['favorites'] ?? []).cast<String>(),
      watched: (json['watched'] ?? []).cast<String>(),
      favoriteGenres: (json['favorite_genres'] ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subscribed_ott': subscribedOtt,
      'favorites': favorites,
      'watched': watched,
      'favorite_genres': favoriteGenres,
    };
  }
}
