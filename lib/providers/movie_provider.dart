import 'package:flutter/material.dart';
import '../models/content.dart';
import '../services/recommendation_service.dart';

class MovieProvider with ChangeNotifier {
  List<Content> _movies = [];
  final TMDBService _service = TMDBService();

  List<Content> get movies => _movies;

  Future<void> loadMovies() async {
    _movies = await _service.fetchPopularMovies();
    notifyListeners();
  }
}
