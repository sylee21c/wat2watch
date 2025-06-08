import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content.dart';

class TMDBService {
  final String apiKey = '70eacb5a78b9c9c51fabb57426c078e4';

  Future<List<Content>> fetchPopularMovies() async {
    final url = Uri.parse('https://api.themoviedb.org/3/movie/popular?api_key=$apiKey&language=ko-KR');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List results = jsonDecode(response.body)['results'];
      return results.map((json) => Content.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load movies');
    }
  }
}
