import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content.dart';

class TmdbApi {
  final String apiKey;
  final String baseUrl = 'https://api.themoviedb.org/3';

  TmdbApi(this.apiKey);

  /// 장르 목록 가져오기 (Movie 기준)
  Future<Map<String, String>> fetchGenreMap() async {
    final res = await http.get(
        Uri.parse('$baseUrl/genre/movie/list?api_key=$apiKey&language=ko-KR')
    );
    final data = json.decode(res.body);
    final genres = Map<String, String>.fromIterable(
      data['genres'],
      key: (g) => g['id'].toString(),
      value: (g) => g['name'],
    );
    return genres;
  }

  /// OTT 목록 가져오기 (한국 기준, Movie 기준)
  Future<Map<String, String>> fetchOttProviders() async {
    final res = await http.get(
        Uri.parse('$baseUrl/watch/providers/movie?api_key=$apiKey&watch_region=KR')
    );
    final data = json.decode(res.body);
    final providers = Map<String, String>.fromIterable(
      data['results'],
      key: (p) => p['provider_id'].toString(),
      value: (p) => p['provider_name'],
    );
    return providers;
  }

  /// 장르 + OTT 기반 콘텐츠 추천 (Movie 기준)
  Future<List<Content>> discoverContent({
    required List<String> genreIds,
    required List<String> providerIds,
    int count = 10,
  }) async {
    final query = {
      'api_key': apiKey,
      'language': 'ko-KR',
      'sort_by': 'popularity.desc',
      'with_genres': genreIds.join(','),
      'with_watch_providers': providerIds.join('|'),
      'watch_region': 'KR',
      'page': '1',
    };

    final uri = Uri.https('api.themoviedb.org', '/3/discover/movie', query);
    final res = await http.get(uri);
    final data = json.decode(res.body);

    return (data['results'] as List)
        .take(count)
        .map((json) => Content.fromJson(json))
        .toList();
  }

  /// 인기 콘텐츠 (Top 10, Movie 기준)
  Future<List<Content>> fetchTop10() async {
    final uri = Uri.parse('$baseUrl/movie/popular?api_key=$apiKey&language=ko-KR&page=1');
    final res = await http.get(uri);
    final data = json.decode(res.body);

    return (data['results'] as List)
        .take(10)
        .map((json) => Content.fromJson(json))
        .toList();
  }

  /// 검색 (Movie 기준)
  Future<List<Content>> searchMovies(String query) async {
    final uri = Uri.parse(
        '$baseUrl/search/movie?api_key=$apiKey&language=ko-KR&query=${Uri.encodeComponent(query)}'
    );
    final res = await http.get(uri);
    final data = json.decode(res.body);

    return (data['results'] as List)
        .map((json) => Content.fromJson(json))
        .toList();
  }
}
