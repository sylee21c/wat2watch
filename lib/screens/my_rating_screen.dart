import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wat2watch_app/models/rating.dart';
import 'package:wat2watch_app/models/content.dart';
import 'package:wat2watch_app/services/api_service.dart';
import 'package:wat2watch_app/providers/user_provider.dart';
import 'package:wat2watch_app/screens/detail_screen.dart';

class MyRatingScreen extends StatefulWidget {
  const MyRatingScreen({super.key});

  @override
  State<MyRatingScreen> createState() => _MyRatingScreenState();
}

class _MyRatingScreenState extends State<MyRatingScreen> {
  bool isLoading = true;
  List<Rating> myRatings = [];
  Map<String, Content> contentMap = {}; // contentId -> Content

  @override
  void initState() {
    super.initState();
    _fetchRatingsAndContents();
  }

  Future<void> _fetchRatingsAndContents() async {
    setState(() => isLoading = true);
    try {
      // 1. 유저 정보 가져오기
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user == null || user.id == null) {
        setState(() {
          myRatings = [];
          contentMap = {};
          isLoading = false;
        });
        return;
      }

      // 2. 평점(별점) 리스트 가져오기
      final ratings = await ApiService.fetchUserRatings(user.id!);

      // 3. 평점에 달린 contentId 모아 각 영화 상세정보 가져오기 (TMDB에서)
      Map<String, Content> cMap = {};
      for (final rating in ratings) {
        final contentId = rating.contentId;
        // 이미 가져온 영화 정보면 다시 요청하지 않음
        if (!cMap.containsKey(contentId)) {
          try {
            final content = await ApiService.fetchContentDetail(contentId, true); // isMovie: true
            cMap[contentId] = content;
          } catch (e) {
            // 에러 시 최소한 제목만 보이게 더미 생성
            cMap[contentId] = Content(id: contentId, title: '영화 정보 없음');
          }
        }
      }

      setState(() {
        myRatings = ratings;
        contentMap = cMap;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        myRatings = [];
        contentMap = {};
        isLoading = false;
      });
      debugPrint("별점 조회 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 별점 기록'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : myRatings.isEmpty
          ? const Center(child: Text('아직 별점을 남긴 영화가 없습니다.'))
          : ListView.builder(
        itemCount: myRatings.length,
        itemBuilder: (context, index) {
          final rating = myRatings[index];
          final content = contentMap[rating.contentId];
          return ListTile(
            leading: content?.posterUrl != null
                ? Image.network(
              'https://image.tmdb.org/t/p/w92${content?.posterUrl}',
              width: 48,
            )
                : const Icon(Icons.movie),
            title: Text(content?.title ?? '영화 정보 없음'),
            subtitle: Row(
              children: [
                const Text('내 별점: '),
                Icon(Icons.star, color: Colors.amber, size: 20),
                Text('${rating.score} / 5'),
                if (rating.comment != null && rating.comment!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      '"${rating.comment}"',
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  ),
              ],
            ),
            onTap: content != null
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(content: content),
                ),
              );
            }
                : null,
          );
        },
      ),
    );
  }
}
