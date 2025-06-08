import 'dart:convert';
import 'package:flutter/foundation.dart'; // Add this import for debugPrint
import 'package:http/http.dart' as http;
import 'package:wat2watch_app/models/content.dart';
import 'package:wat2watch_app/models/rating.dart';
import 'package:wat2watch_app/models/user.dart';
import 'package:wat2watch_app/utils/app_config.dart';

class ApiService {
  static final String _tmdbApiKey = AppConfig.tmdbApiKey;
  static final String _tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static final String _baseUrl = AppConfig.apiBaseUrl;

  // 기존 사용자 관련 메서드들
  static Future<User> fetchUserInfo(String userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/user/$userId'));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return User.fromJson(json);
    } else {
      throw Exception('Failed to load user info');
    }
  }

  static Future<User> loginUser(String id, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': id, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      throw Exception('로그인 실패: ${response.body}');
    }
  }

  static Future<void> registerUser({
    required String id,
    required String password,
    required String name,
    required List<String> subscribedOtt,
    required List<String> favoriteGenres,
  }) async {
    if (_baseUrl.isEmpty) {
      throw Exception('❌ API_BASE_URL is not defined');
    }

    final url = Uri.parse('$_baseUrl/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'password': password,
        'name': name,
        'subscribed_ott': subscribedOtt,
        'favorite_genres': favoriteGenres,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('서버 오류: ${response.statusCode} - ${response.body}');
    }
  }

  // 개선된 콘텐츠 관련 메서드들
  static Future<List<Content>> fetchRecommendedMovies(String userId) async {
    try {
      // 먼저 백엔드에서 추천 영화 ID 목록을 가져옴
      final response = await http.get(Uri.parse('$_baseUrl/recommend/$userId'));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        // 각 영화의 상세 정보를 TMDB에서 가져옴
        final List<Content> detailedMovies = [];

        for (var item in data) {
          try {
            final contentId = item['id']?.toString() ?? item['tmdb_id']?.toString();
            if (contentId != null) {
              final detailedContent = await fetchContentDetail(contentId, true);
              detailedMovies.add(detailedContent);
            } else {
              // fallback: 기본 정보만 사용
              detailedMovies.add(Content.fromJson(item));
            }
          } catch (e) {
            print('Error fetching detailed info for movie: $e');
            // 에러 발생시 기본 정보라도 사용
            detailedMovies.add(Content.fromJson(item));
          }
        }

        return detailedMovies;
      } else {
        throw Exception('Failed to fetch recommended movies');
      }
    } catch (e) {
      print('Error in fetchRecommendedMovies: $e');
      // fallback: 인기 영화 반환
      return await fetchPopularMovies();
    }
  }

  static Future<List<Content>> fetchTrendingMovies() async {
    final url = Uri.parse('$_tmdbBaseUrl/trending/movie/week?api_key=$_tmdbApiKey&language=ko-KR');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];

      // 상위 10개 영화의 상세 정보를 가져옴
      final List<Content> detailedMovies = [];
      final limitedResults = results.take(10).toList();

      for (var movieData in limitedResults) {
        try {
          final movieId = movieData['id'].toString();
          final detailedMovie = await fetchContentDetail(movieId, true);
          detailedMovies.add(detailedMovie);
        } catch (e) {
          print('Error fetching detailed info for trending movie: $e');
          // 에러 발생시 기본 정보 사용
          detailedMovies.add(Content.fromJson(movieData));
        }
      }

      return detailedMovies;
    } else {
      throw Exception('Failed to fetch trending movies');
    }
  }

  // 인기 영화 가져오기 (fallback용)
  static Future<List<Content>> fetchPopularMovies() async {
    final url = Uri.parse('$_tmdbBaseUrl/movie/popular?api_key=$_tmdbApiKey&language=ko-KR');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.take(20).map((json) => Content.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch popular movies');
    }
  }

  // 영화/TV 상세 정보 가져오기 (모든 정보 포함)
  static Future<Content> fetchContentDetail(String contentId, bool isMovie) async {
    final type = isMovie ? 'movie' : 'tv';
    final url = Uri.parse('$_tmdbBaseUrl/$type/$contentId?api_key=$_tmdbApiKey&language=ko-KR');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Content.fromJson(data);
    } else {
      throw Exception('Failed to fetch content detail');
    }
  }

  // 영화 크레딧 정보 가져오기 (출연진, 감독 등)
  static Future<Map<String, dynamic>> fetchContentCredits(String contentId, bool isMovie) async {
    final type = isMovie ? 'movie' : 'tv';
    final url = Uri.parse('$_tmdbBaseUrl/$type/$contentId/credits?api_key=$_tmdbApiKey&language=ko-KR');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch content credits');
    }
  }

  // 비슷한 영화/TV 추천
  static Future<List<Content>> fetchSimilarContent(String contentId, bool isMovie) async {
    final type = isMovie ? 'movie' : 'tv';
    final url = Uri.parse('$_tmdbBaseUrl/$type/$contentId/similar?api_key=$_tmdbApiKey&language=ko-KR');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.take(10).map((json) => Content.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch similar content');
    }
  }

  // 영화/TV 동영상 (트레일러 등)
  static Future<List<Map<String, dynamic>>> fetchContentVideos(String contentId, bool isMovie) async {
    final type = isMovie ? 'movie' : 'tv';
    final url = Uri.parse('$_tmdbBaseUrl/$type/$contentId/videos?api_key=$_tmdbApiKey&language=ko-KR');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch content videos');
    }
  }

  // 개선된 검색 기능
  static Future<List<Content>> searchContent(String query) async {
    final url = Uri.parse('$_tmdbBaseUrl/search/multi?api_key=$_tmdbApiKey&query=${Uri.encodeComponent(query)}&language=ko-KR');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];

      final filteredResults = results
          .where((json) => json['media_type'] == 'movie' || json['media_type'] == 'tv')
          .toList();

      // 상위 결과들의 상세 정보를 가져옴
      final List<Content> detailedResults = [];
      final limitedResults = filteredResults.take(20).toList();

      for (var item in limitedResults) {
        try {
          final contentId = item['id'].toString();
          final isMovie = item['media_type'] == 'movie';
          final detailedContent = await fetchContentDetail(contentId, isMovie);
          detailedResults.add(detailedContent);
        } catch (e) {
          print('Error fetching detailed search result: $e');
          // 에러 발생시 기본 정보 사용
          detailedResults.add(Content.fromJson(item));
        }
      }

      return detailedResults;
    } else {
      throw Exception('Failed to search content');
    }
  }

  // 장르별 영화 가져오기
  static Future<List<Content>> fetchMoviesByGenre(int genreId) async {
    final url = Uri.parse('$_tmdbBaseUrl/discover/movie?api_key=$_tmdbApiKey&with_genres=$genreId&language=ko-KR&sort_by=popularity.desc');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.take(20).map((json) => Content.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch movies by genre');
    }
  }

  // 장르 목록 가져오기
  static Future<List<Map<String, dynamic>>> fetchGenres(bool isMovie) async {
    final type = isMovie ? 'movie' : 'tv';
    final url = Uri.parse('$_tmdbBaseUrl/genre/$type/list?api_key=$_tmdbApiKey&language=ko-KR');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List genres = data['genres'];
      return genres.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch genres');
    }
  }

  // OTT 플랫폼별 콘텐츠 가져오기
  static Future<List<Content>> fetchContentByProvider(int providerId, bool isMovie) async {
    final type = isMovie ? 'movie' : 'tv';
    final url = Uri.parse('$_tmdbBaseUrl/discover/$type?api_key=$_tmdbApiKey&with_watch_providers=$providerId&watch_region=KR&language=ko-KR&sort_by=popularity.desc');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      return results.take(20).map((json) => Content.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch content by provider');
    }
  }

  // 사용자 평점 목록 가져오기
  static Future<List<Rating>> fetchUserRatings(String userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/user/$userId/ratings'));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Rating.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch user ratings');
    }
  }

  // 에러 처리용 헬퍼 메서드
  static void _handleHttpError(http.Response response, String operation) {
    if (response.statusCode != 200) {
      throw Exception('$operation failed: ${response.statusCode} - ${response.body}');
    }
  }

  // 영화 출연진 정보 가져오기
  static Future<List<Map<String, dynamic>>> fetchMovieCast(String movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$_tmdbBaseUrl/movie/$movieId/credits?api_key=$_tmdbApiKey&language=ko-KR'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final cast = data['cast'] as List;
        return cast.map((actor) => actor as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load cast');
      }
    } catch (e) {
      debugPrint('Error fetching cast: $e');
      return [];
    }
  }

  // 비슷한 영화 가져오기
  static Future<List<Content>> fetchSimilarMovies(String movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$_tmdbBaseUrl/movie/$movieId/similar?api_key=$_tmdbApiKey&language=ko-KR&page=1'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Content.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load similar movies');
      }
    } catch (e) {
      debugPrint('Error fetching similar movies: $e');
      return [];
    }
  }

  // 특정 영화에 대한 추천 영화 가져오기
  static Future<List<Content>> fetchRecommendedMoviesForMovie(String movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$_tmdbBaseUrl/movie/$movieId/recommendations?api_key=$_tmdbApiKey&language=ko-KR&page=1'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Content.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load recommended movies');
      }
    } catch (e) {
      debugPrint('Error fetching recommended movies: $e');
      return [];
    }
  }

  // 외부 ID 가져오기 (IMDb ID 등)
  static Future<Map<String, dynamic>?> fetchExternalIds(String movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$_tmdbBaseUrl/movie/$movieId/external_ids?api_key=$_tmdbApiKey'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load external IDs');
      }
    } catch (e) {
      debugPrint('Error fetching external IDs: $e');
      return null;
    }
  }

  // 영화 리뷰 가져오기
  static Future<List<Map<String, dynamic>>> fetchMovieReviews(String movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$_tmdbBaseUrl/movie/$movieId/reviews?api_key=$_tmdbApiKey&language=ko-KR&page=1'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((review) => review as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  // 사용자 평점 가져오기 (특정 영화에 대한)
  static Future<double?> getUserRating(String userId, String movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ratings/$userId/$movieId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}', // 인증 토큰 필요
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['rating']?.toDouble();
      } else if (response.statusCode == 404) {
        // 평점이 없는 경우
        return null;
      } else {
        throw Exception('Failed to load user rating: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching user rating: $e');
      return null;
    }
  }

  // 별점을 서버에 전송하는 메서드
  static Future<void> submitRating(String userId, String movieId, double rating, String comment) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ratings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}', // 인증 토큰 필요
        },
        body: json.encode({
          'user_id': userId,
          'movie_id': movieId,
          'rating': rating,
          'comment': comment,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to submit rating: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      throw Exception('별점 등록에 실패했습니다: $e');
    }
  }

  // 인증 토큰 가져오기
  static Future<String> _getAuthToken() async {
    return '';
  }
  static Future<List<Map<String, dynamic>>> fetchWatchProviders(String movieId, {String countryCode = 'KR'}) async {
    final apiKey = AppConfig.tmdbApiKey; // 실제 프로젝트에서는 여기에 API 키가 있음
    final url = Uri.parse(
      'https://api.themoviedb.org/3/movie/$movieId/watch/providers?api_key=$apiKey',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'];
      if (results != null && results[countryCode] != null) {
        final countryData = results[countryCode];
        final flatrate = countryData['flatrate'] as List?;
        if (flatrate != null) {
          return flatrate.map<Map<String, dynamic>>((item) => {
            'provider_name': item['provider_name'],
            'logo_path': item['logo_path'],
          }).toList();
        }
      }
    }
    return [];
  }

}