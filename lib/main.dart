import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wat2watch_app/providers/user_provider.dart';
import 'package:wat2watch_app/screens/login_screen.dart';
import 'package:wat2watch_app/screens/register_screen.dart';
import 'package:wat2watch_app/screens/home_screen.dart';
import 'package:wat2watch_app/screens/search_screen.dart';
import 'package:wat2watch_app/screens/rating_screen.dart';
import 'package:wat2watch_app/screens/my_rating_screen.dart';
import 'package:wat2watch_app/screens/detail_screen.dart';
import 'package:wat2watch_app/screens/recommendation_screen.dart';
import 'package:wat2watch_app/models/content.dart';

void main() {
  runApp(const Wat2WatchApp());
}

class Wat2WatchApp extends StatelessWidget {
  const Wat2WatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MaterialApp(
        title: 'Wat2Watch',
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/search': (context) => const SearchScreen(),
          '/recommendation': (context) => const RecommendationScreen(),
          '/rating': (context) => const MyRatingScreen(),  // 내 별점 목록
        },
        onGenerateRoute: (settings) {
          // Detail 화면 이동
          if (settings.name == '/detail') {
            final content = settings.arguments as Content?;
            if (content != null) {
              return MaterialPageRoute(
                builder: (_) => DetailScreen(content: content),
              );
            } else {
              // arguments가 없거나 잘못된 경우 홈으로 리다이렉트
              return MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              );
            }
          }
          return null;
        },
      ),
    );
  }
}