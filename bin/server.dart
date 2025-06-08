import 'dart:io';
import 'dart:convert';

// 사용자 정보 저장
final Map<String, Map<String, dynamic>> users = {};
// 별점 정보 저장
final List<Map<String, dynamic>> ratings = [];

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('Server is running on http://localhost:8080');

  await for (HttpRequest request in server) {
    final method = request.method;
    final path = request.uri.path;

    // 🏠 루트 접속 테스트
    if (method == 'GET' && path == '/') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write('<h2> Wat2Watch Dart Server is Running!</h2>')
        ..close();
    }

    // 회원가입
    else if (method == 'POST' && path == '/register') {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body);
      final id = data['id'];
      users[id] = data;

      print('Received registration: $data');

      request.response
        ..statusCode = HttpStatus.ok
        ..write('User registered!')
        ..close();
    }

    // 로그인
    else if (method == 'POST' && path == '/login') {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body);
      final id = data['id'];
      final pw = data['password'];

      if (users.containsKey(id) && users[id]!['password'] == pw) {
        print('Login success: $id');
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'id': users[id]!['id'],
            'name': users[id]!['name'],
            'subscribed_ott': users[id]!['subscribed_ott'],
            'favorite_genres': users[id]!['favorite_genres'],
          }))
          ..close();
      } else {
        print('Login failed for id=$id');
        request.response
          ..statusCode = HttpStatus.unauthorized
          ..write('Invalid credentials')
          ..close();
      }
    }

    //추천 영화 API
    else if (method == 'GET' && path.startsWith('/recommend/')) {
      final userId = path.split('/').last;

      if (!users.containsKey(userId)) {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('User not found')
          ..close();
        continue;
      }


    }

    // 별점 등록 API
    else if (method == 'POST' && path == '/rating') {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body);

      // 필수 파라미터 체크
      if (data['userId'] == null || data['contentId'] == null || data['rating'] == null) {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write('Missing parameter(s)')
          ..close();
        continue;
      }

      ratings.add({
        'userId': data['userId'],
        'contentId': data['contentId'],
        'rating': data['rating'],
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('Rating received: $data');

      request.response
        ..statusCode = HttpStatus.ok
        ..write('Rating submitted!')
        ..close();
    }

    // 기타 경로
    else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found')
        ..close();
    }
  }
}
