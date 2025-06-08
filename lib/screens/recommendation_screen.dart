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
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final userId = user?.id ?? '';
    try {
      final recs = await ApiService.fetchRecommendedMovies(userId);
      setState(() {
        recommendedMovies = recs;
        isLoading = false;
      });
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
    final user = Provider.of<UserProvider>(context).user;
    final otts = user?.subscribedOtt?.join(', ') ?? '';
    final genres = user?.favoriteGenres?.join(', ') ?? '';

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
            child: Text(
              '회원정보 기반 추천 영화',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          if (otts.isNotEmpty || genres.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '• 구독 OTT: $otts\n• 선호 장르: $genres',
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          const SizedBox(height: 8),
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
