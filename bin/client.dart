import 'dart:io';
import 'handlers.dart';

void main() async {
  loadSession();

  const apiKey = '70eacb5a78b9c9c51fabb57426c078e4';

  while (true) {
    print('''
~~~Wat2Watch~~~
1. 회원 가입
2. 로그인
3. 추천 콘텐츠 보기
4. 인기 콘텐츠 (TOP 10)
5. 콘텐츠 검색
6. 영화에 별점 주기
7. 별점 내역 조회
0. 종료
''');
    stdout.write('선택: ');
    final choice = stdin.readLineSync();

    switch (choice) {
      case '1':
        await handleRegister(apiKey: apiKey);
        break;
      case '2':
        await handleLogin();
        break;
      case '3':
        await handleRecommend(apiKey: apiKey);
        break;
      case '4':
        await handleTop10(apiKey: apiKey);
        break;
      case '5':
        await handleSearch(apiKey: apiKey);
        break;
      case '6':
        await handleRating();
        break;
      case '7':
        await handleGetRatings();
        break;
      case '0':
        exit(0);
      default:
        print('❌ 잘못된 선택입니다.');
    }

    print('엔터 키를 누르면 계속합니다...');
    stdin.readLineSync();
  }
}
