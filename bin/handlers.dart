library handlers;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// 전역 변수 선언
String? globalUserId;
const String baseUrl = 'http://localhost:8080';
String contentType = 'movie';

void loadSession() {
  try {
    final sessionFile = File('.session');
    if (sessionFile.existsSync()) {
      globalUserId = sessionFile.readAsStringSync().trim();
      if (globalUserId!.isNotEmpty) {
        print('✅ 세션 복원됨: user-id=$globalUserId');
      } else {
        globalUserId = null;
      }
    }
  } catch (e) {
    print('⚠️ 세션 불러오기 실패: $e');
    globalUserId = null;
  }
}

// --- 공통 유틸 함수 ---
Future<http.Response> safeApiCall(Future<http.Response> Function() apiCall) async {
  try {
    final response = await apiCall();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      print('❌ API 오류 (${response.statusCode}): ${response.body}');
    }
    return response;
  } on SocketException catch (_) {
    print('❌ 서버 연결 실패. 서버가 실행 중인지 확인하세요.');
    exit(1);
  } on http.ClientException catch (e) {
    print('❌ HTTP 클라이언트 오류: $e');
    exit(1);
  } catch (e) {
    print('❌ 예상치 못한 오류: $e');
    exit(1);
  }
}

bool checkLogin() {
  if (globalUserId == null) {
    print('[!] 로그인이 필요합니다. 먼저 로그인해주세요.');
    return false;
  }
  return true;
}

String getUserInput(String prompt, {bool required = true}) {
  stdout.write('$prompt: ');
  final input = stdin.readLineSync();
  if (required && (input == null || input.trim().isEmpty)) {
    print('❌ 입력이 필요합니다.');
    return getUserInput(prompt, required: required);
  }
  return input?.trim() ?? '';
}

// --- 기능 처리 핸들러들 ---
Future<void> handleRegister({required String apiKey}) async {
  try {
    print('장르와 OTT 정보를 가져오는 중입니다...');
    final genres = await fetchGenreMap(apiKey);
    final otts = await fetchOttMap(apiKey);

    if (genres.isEmpty || otts.isEmpty) {
      print('❌ 장르 또는 OTT 정보를 가져오는데 실패했습니다.');
      print('API 키를 확인하거나 인터넷 연결을 확인해주세요.');
      return;
    }

    final username = getUserInput('\n사용자 이름');
    final password = getUserInput('비밀번호');

    print('\n[ 장르 ID 목록 ]');
    genres.forEach((id, name) => print('$id\t: $name'));

    final genresInput = getUserInput('선호 장르 ID들 (쉼표로 구분)').split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    print('\n[ OTT 서비스 ID 목록 ]');
    otts.forEach((id, name) => print('$id\t: $name'));

    final ottsInput = getUserInput('구독 중인 OTT ID들 (쉼표로 구분)').split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (genresInput.isEmpty) {
      print('⚠️ 최소 하나의 장르를 선택하세요.');
      return;
    }

    for (final genreId in genresInput) {
      if (!genres.containsKey(genreId)) {
        print('❌ 잘못된 장르 ID: $genreId');
        return;
      }
    }

    for (final ottId in ottsInput) {
      if (!otts.containsKey(ottId)) {
        print('❌ 잘못된 OTT ID: $ottId');
        return;
      }
    }

    final response = await safeApiCall(() => http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
        'genres': genresInput,
        'ottServices': ottsInput,
      }),
    ));

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ 회원가입 성공!');
      final jsonRes = json.decode(response.body);
      print(jsonRes['message'] ?? '등록되었습니다.');
    }
  } catch (e) {
    print('❌ 회원가입 중 오류 발생: $e');
  }
}

Future<void> handleLogin() async {
  try {
    final username = getUserInput('사용자 이름');
    final password = getUserInput('비밀번호');

    final res = await safeApiCall(() => http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    ));

    final jsonRes = json.decode(res.body);
    if (res.statusCode == 200) {
      globalUserId = jsonRes['userId'];
      try {
        File('.session').writeAsStringSync(globalUserId!);
        print('✅ 로그인 성공: user-id=$globalUserId');
      } catch (e) {
        print('⚠️ 세션 저장 실패: $e');
        print('✅ 로그인은 성공했습니다. user-id=$globalUserId');
      }
    } else {
      print('❌ 로그인 실패: ${jsonRes['error'] ?? '알 수 없는 오류'}');
    }
  } catch (e) {
    print('❌ 로그인 중 오류 발생: $e');
  }
}

Future<void> handleRecommend({required String apiKey}) async {
  if (!checkLogin()) return;

  try {
    final res = await safeApiCall(() => http.get(
      Uri.parse('$baseUrl/recommendations'),
      headers: {'user-id': globalUserId!},
    ));

    if (res.statusCode == 200) {
      printFormattedList(res.body);
    }
  } catch (e) {
    print('❌ 추천 목록 가져오기 실패: $e');
  }
}

Future<void> handleRating() async {
  if (!checkLogin()) return;

  final contentId = getUserInput('영화 ID');
  final ratingInput = getUserInput('평점 (1~5)');
  final rating = int.tryParse(ratingInput);

  if (rating == null || rating < 1 || rating > 5) {
    print('❌ 평점은 1에서 5 사이의 정수여야 합니다.');
    return;
  }

  try {
    final res = await safeApiCall(() => http.post(
      Uri.parse('$baseUrl/rate'),
      headers: {
        'Content-Type': 'application/json',
        'user-id': globalUserId!,
      },
      body: json.encode({
        'contentId': contentId,
        'contentType': contentType,  // contentType 추가
        'rating': rating,
      }),
    ));

    if (res.statusCode == 200) {
      final jsonRes = json.decode(res.body);
      print('✅ 평점이 저장되었습니다: ${jsonRes['message'] ?? ''}');
    } else {
      final errorMsg = json.decode(res.body)['error'] ?? '알 수 없는 오류';
      print('❌ 평점 저장 실패: $errorMsg');
    }
  } catch (e) {
    print('❌ 평점 등록 중 오류 발생: $e');
  }
}

Future<void> handleGetRatings() async {
  if (!checkLogin()) return;

  try {
    final res = await safeApiCall(() => http.get(
      Uri.parse('$baseUrl/ratings'),
      headers: {'user-id': globalUserId!},
    ));

    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final ratings = data['ratings'] as List<dynamic>;
      if (ratings.isEmpty) {
        print('🔍 별점 내역이 없습니다.');
      } else {
        print('🔍 별점 내역:');
        for (var item in ratings) {
          print('• 영화 ID ${item['contentId']}: ⭐ ${item['rating']}');
        }
      }
    }
  } catch (e) {
    print('❌ 별점 내역 조회 실패: $e');
  }
}

Future<void> handleTop10({required String apiKey}) async {
  try {
    final res = await safeApiCall(() => http.get(
      Uri.parse('$baseUrl/top10'),
    ));
    if (res.statusCode == 200) printFormattedList(res.body);
  } catch (e) {
    print('❌ Top 10 목록 가져오기 실패: $e');
  }
}

Future<void> handleSearch({required String apiKey}) async {
  try {
    final query = getUserInput('검색어');
    if (query.isEmpty) {
      print('❌ 검색어를 입력해주세요.');
      return;
    }

    final res = await safeApiCall(() => http.get(
      Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}'),
    ));

    if (res.statusCode == 200) {
      final list = json.decode(res.body);
      if (list is List && list.isEmpty) {
        print('❌ 검색 결과가 없습니다.');
        return;
      }
      printFormattedList(res.body);
    }
  } catch (e) {
    print('❌ 검색 중 오류 발생: $e');
  }
}

// // --- 즐겨찾기 ---
// Future<void> handleFavorite() async {
//   if (!checkLogin()) return;
//
//   final contentId = getUserInput('영화 ID');
//
//   final res = await safeApiCall(() => http.post(
//     Uri.parse('$baseUrl/favorite'),
//     headers: {
//       'Content-Type': 'application/json',
//       'user-id': globalUserId!,
//     },
//     body: json.encode({'contentId': contentId}),
//   ));
//
//   if (res.statusCode == 200) {
//     print('✅ 즐겨찾기에 추가되었습니다.');
//   } else {
//     print('❌ 즐겨찾기 추가 실패');
//   }
// }
//
// Future<void> handleUnfavorite() async {
//   if (!checkLogin()) return;
//
//   final contentId = getUserInput('영화 ID');
//
//   final res = await safeApiCall(() => http.delete(
//     Uri.parse('$baseUrl/favorite/$contentId'),
//     headers: {'user-id': globalUserId!},
//   ));
//
//   if (res.statusCode == 200) {
//     print('✅ 즐겨찾기에서 제거되었습니다.');
//   } else {
//     print('❌ 즐겨찾기 제거 실패');
//   }
// }

// --- TMDB API 직접 호출 ---
Future<Map<String, String>> fetchGenreMap(String apiKey) async {
  final uri = Uri.parse(
      'https://api.themoviedb.org/3/genre/movie/list'
          '?api_key=$apiKey&language=ko-KR'
  );
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final data = json.decode(response.body) as Map<String, dynamic>;
    final genres = data['genres'] as List<dynamic>;
    return {
      for (var g in genres)
        g['id'].toString(): g['name'] as String,
    };
  } else {
    print('❌ 장르 정보를 가져오는데 실패했습니다: ${response.statusCode}');
    print('응답: ${response.body}');
    return {};
  }
}

Future<Map<String, String>> fetchOttMap(String apiKey) async {
  final uri = Uri.parse(
      'https://api.themoviedb.org/3/watch/providers/movie'
          '?api_key=$apiKey&watch_region=KR'
  );
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final data = json.decode(response.body) as Map<String, dynamic>;
    final providers = data['results'] as List<dynamic>;
    return {
      for (var p in providers)
        p['provider_id'].toString(): p['provider_name'] as String,
    };
  } else {
    print('❌ OTT 서비스 정보를 가져오는데 실패했습니다: ${response.statusCode}');
    print('응답: ${response.body}');
    return {};
  }
}

// --- 결과 출력 ---
void printFormattedList(String jsonString) {
  try {
    final items = json.decode(jsonString) as List;
    if (items.isEmpty) {
      print('결과가 없습니다.');
      return;
    }

    print('\n=====================================================');
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final title = item['title'] ?? item['name'] ?? '제목 없음';

      // 연도 정보 제거: 제목만 출력
      print('${i + 1}. ID: ${item['id']} - $title');

      // 줄거리
      if (item['overview'] != null) {
        final overview = item['overview'] as String;
        final preview = overview.length > 100
            ? '${overview.substring(0, 100)}...'
            : overview;
        print('   줄거리: $preview');
      }

      // 장르, 평점
      if (item['genres'] != null) {
        print('   장르: ${(item['genres'] as List).join(', ')}');
      }
      if (item['rating'] != null) {
        print('   평점: ${item['rating']}');
      }

      print('-----------------------------------------------------');
    }
    print('=====================================================\n');
  } catch (e) {
    print('❌ 결과 출력 중 오류 발생: $e');
    print(jsonString);
  }
}