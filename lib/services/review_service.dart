import 'dart:convert';
import 'package:http/http.dart' as http;

class ReviewService {
  static const _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');

  /// 외부 평점 (IMDb, Rotten Tomatoes 등) + 내부 사용자 평점 통합
  static Future<Map<String, dynamic>> fetchAggregatedRatings(String contentId) async {
    final response = await http.get(Uri.parse('$_baseUrl/review/aggregate/$contentId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch aggregated ratings');
    }
  }

  /// 사용자 리뷰 목록
  static Future<List<Map<String, dynamic>>> fetchUserReviews(String contentId) async {
    final response = await http.get(Uri.parse('$_baseUrl/review/user/$contentId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to fetch user reviews');
    }
  }

  /// 사용자 리뷰 제출 (텍스트 기반)
  static Future<void> submitUserReview({
    required String userId,
    required String contentId,
    required String comment,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/review/user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'content_id': contentId,
        'comment': comment,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit review');
    }
  }
}
