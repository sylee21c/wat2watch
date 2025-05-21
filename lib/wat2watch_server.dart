import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:wat2watch/models/user.dart';
import 'package:wat2watch/models/content.dart';
import 'package:wat2watch/api/tmdb.dart';

class Wat2WatchServer {
  final Router _router;
  final Map<String, User> _users = {};
  final Map<String, Map<String, int>> _ratings = {}; // 사용자별 평점 저장
  final TmdbApi _tmdbApi;
  final _uuid = Uuid();

  Wat2WatchServer(this._tmdbApi) : _router = Router() {
    _setupRoutes();
  }

  Router get router => _router;

  void _setupRoutes() {
    _router.post('/register', _handleRegister);
    _router.post('/login', _handleLogin);
    _router.get('/recommendations', _handleRecommendations);
    _router.get('/top10', _handleTop10);
    _router.get('/search', _handleSearch);
    _router.post('/favorite', _handleAddFavorite);
    _router.delete('/favorite', _handleRemoveFavorite);
    _router.post('/rate', _handleRate); // 평점 저장
    _router.get('/ratings', _handleGetRatings); // 평점 내역 조회
  }

  Future<Response> _handleRegister(Request request) async {
    final data = json.decode(await request.readAsString());
    final user = User(
      id: _uuid.v4(),
      username: data['username'],
      passwordHash: _hashPassword(data['password']),
      subscribedOttServices: List<String>.from(data['ottServices']),
      preferredGenres: List<String>.from(data['genres']),
    );
    _users[user.id] = user;
    return Response.ok(json.encode({'userId': user.id}));
  }

  Future<Response> _handleLogin(Request request) async {
    final data = json.decode(await request.readAsString());
    final user = _users.values.firstWhere(
          (u) => u.username == data['username'],
      orElse: () => throw Exception('User not found'),
    );
    if (user.passwordHash != _hashPassword(data['password'])) {
      return Response.forbidden(json.encode({'error': 'Invalid password'}));
    }
    return Response.ok(json.encode({'userId': user.id}));
  }

  Future<Response> _handleRecommendations(Request request) async {
    final userId = request.headers['user-id'];
    if (userId == null || !_users.containsKey(userId)) {
      return Response.forbidden(json.encode({'error': 'Missing or invalid user ID'}));
    }
    final user = _users[userId]!;
    final contents = await _tmdbApi.discoverContent(
      genreIds: user.preferredGenres,
      providerIds: user.subscribedOttServices,
    );
    return Response.ok(json.encode(contents.map((c) => c.toJson()).toList()));
  }

  Future<Response> _handleTop10(Request request) async {
    final contents = await _tmdbApi.fetchTop10();
    return Response.ok(json.encode(contents.map((c) => c.toJson()).toList()));
  }

  Future<Response> _handleSearch(Request request) async {
    final keyword = request.url.queryParameters['q'];
    if (keyword == null || keyword.trim().isEmpty) {
      return Response.badRequest(body: json.encode({'error': 'Missing search keyword'}));
    }
    final results = await _tmdbApi.searchMovies(keyword);
    return Response.ok(json.encode(results.map((c) => c.toJson()).toList()));
  }

  Future<Response> _handleAddFavorite(Request request) async {
    final userId = request.headers['user-id'];
    final data = json.decode(await request.readAsString());
    final contentId = data['contentId'];
    final user = _users[userId];
    if (user == null || contentId == null) {
      return Response.badRequest(body: json.encode({'error': 'Invalid request'}));
    }
    if (!user.favoriteContents.contains(contentId)) {
      user.favoriteContents.add(contentId);
    }
    return Response.ok(json.encode({'message': 'Added to favorites'}));
  }

  Future<Response> _handleRemoveFavorite(Request request) async {
    final userId = request.headers['user-id'];
    final data = json.decode(await request.readAsString());
    final contentId = data['contentId'];
    final user = _users[userId];
    if (user == null || contentId == null) {
      return Response.badRequest(body: json.encode({'error': 'Invalid request'}));
    }
    user.favoriteContents.remove(contentId);
    return Response.ok(json.encode({'message': 'Removed from favorites'}));
  }

  Future<Response> _handleRate(Request request) async {
    final userId = request.headers['user-id'];
    if (userId == null || !_users.containsKey(userId)) {
      return Response.forbidden(json.encode({'error': 'Missing or invalid user ID'}));
    }
    final data = json.decode(await request.readAsString());
    final contentId = data['contentId']?.toString();
    final rating = data['rating'];
    if (contentId == null || rating == null || rating is! int || rating < 1 || rating > 5) {
      return Response.badRequest(body: json.encode({'error': 'Invalid rating data'}));
    }
    _ratings.putIfAbsent(userId, () => {})[contentId] = rating;
    return Response.ok(json.encode({'message': 'Rating saved'}));
  }

  /// 사용자별 별점 내역 조회 핸들러
  Future<Response> _handleGetRatings(Request request) async {
    final userId = request.headers['user-id'];
    if (userId == null || !_users.containsKey(userId)) {
      return Response.forbidden(json.encode({'error': 'Missing or invalid user ID'}));
    }
    final userRatings = _ratings[userId] ?? {};
    final ratingsList = userRatings.entries
        .map((e) => {'contentId': e.key, 'rating': e.value})
        .toList();
    return Response.ok(json.encode({'ratings': ratingsList}));
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
