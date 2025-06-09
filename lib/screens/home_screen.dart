import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wat2watch_app/services/api_service.dart';
import 'package:wat2watch_app/widgets/content_card.dart';
import 'package:wat2watch_app/models/content.dart';
import 'package:wat2watch_app/providers/user_provider.dart';
import 'package:wat2watch_app/screens/detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 추천영화 삭제
  List<Content> trendingMovies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  Future<void> _fetchMovies() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    try {
      // 추천영화 삭제
      final trending = await ApiService.fetchTrendingMovies();
      setState(() {
        trendingMovies = trending;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching movies: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToDetail(Content content) {
    debugPrint("=== 영화 탭 이벤트 발생 ===");
    debugPrint("영화 제목: ${content.title}");
    debugPrint("영화 ID: ${content.id}");
    debugPrint("Content 객체 null 체크: ${content != null}");

    try {
      Navigator.pushNamed(
        context,
        '/detail',
        arguments: {
          'content': content,
        },
      ).then((result) {
        debugPrint("네비게이션 성공적으로 완료");
      }).catchError((error) {
        debugPrint("네비게이션 에러 발생: $error");
        _navigateToDetailDirect(content);
      });
    } catch (e) {
      debugPrint("Navigator.pushNamed 실패: $e");
      _navigateToDetailDirect(content);
    }
  }

  void _navigateToDetailDirect(Content content) {
    debugPrint("대안 네비게이션 사용: Navigator.push");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(content: content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Wat2Watch - 환영합니다, ${user?.name ?? '사용자'}님'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // 홈
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/recommendation');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/rating');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.thumb_up_alt), label: '추천'),
          BottomNavigationBarItem(icon: Icon(Icons.grade), label: '내 별점'),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/search');
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(width: 12),
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        '영화 제목, 배우, 감독 검색...',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('🔥 인기 영화', style: TextStyle(fontSize: 30)),
            ),
            SizedBox(
              height: 250,
              child: trendingMovies.isEmpty
                  ? const Center(
                child: Text(
                  '인기 영화가 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: trendingMovies.length,
                itemBuilder: (context, index) {
                  final content = trendingMovies[index];
                  return ContentCard(
                    content: content,
                    onTap: () => _navigateToDetail(content),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
