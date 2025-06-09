import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wat2watch_app/models/content.dart';
import 'package:wat2watch_app/providers/user_provider.dart';
import 'package:wat2watch_app/services/api_service.dart';
import 'package:wat2watch_app/widgets/content_card.dart';
import 'package:wat2watch_app/screens/detail_screen.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}
class _RecommendationScreenState extends State<RecommendationScreen> {
  List<Content> recommendedMovies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommended();
  }

  Future<void> _fetchRecommended() async {
    final user = Provider
        .of<UserProvider>(context, listen: false)
        .user;
    final ottList = user?.subscribedOtt ?? [];
    final genreList = user?.favoriteGenres ?? [];

    try {
      // 1. TMDB에서 인기영화 등 리스트 받아오기
      final allMovies = await ApiService.fetchPopularMovies();

      // 2. 각 영화별 ottList 채우기 (직접 값 할당)
      for (final movie in allMovies) {
        if (movie.id == null) continue;
        final providers = await ApiService.fetchWatchProviders(movie.id!);
        movie.ottList =
            providers.map((p) => p['provider_name'] as String).toList();
      }

      // 3. ott + 장르 모두 만족하는 영화만 필터링
      final filtered = allMovies.where((movie) {
        final ottMatch = ottList.any((ott) =>
        movie.ottList?.map((e) => e.toLowerCase()).contains(
            ott.toLowerCase()) ?? false);
        final genreMatch = genreList.any((g) =>
        movie.genres?.map((e) => e.toLowerCase()).contains(g.toLowerCase()) ??
            false);
        return ottMatch && genreMatch;
      }).toList();

      if (filtered.isEmpty) {
        setState(() {
          recommendedMovies = allMovies.take(10).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          recommendedMovies = filtered;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("추천 영화 불러오기 실패: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToDetail(Content content) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailScreen(content: content)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider
        .of<UserProvider>(context)
        .user;
    final otts = (user?.subscribedOtt ?? []).join(', ');
    final genres = (user?.favoriteGenres ?? []).join(', ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 OTT/장르 추천'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ),
          Expanded(
            child: recommendedMovies.isEmpty
                ? const Center(
              child: Text(
                '추천 영화가 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: recommendedMovies.length,
              itemBuilder: (context, index) {
                final content = recommendedMovies[index];
                return ContentCard(
                  content: content,
                  onTap: () => _navigateToDetail(content),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}