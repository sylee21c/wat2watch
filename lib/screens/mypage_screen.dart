import 'package:flutter/material.dart';
import 'package:wat2watch_app/services/api_service.dart';
import 'package:wat2watch_app/services/session_manager.dart';
import 'package:wat2watch_app/models/user.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userId = await SessionManager.getUserId();
    if (userId == null) return;

    try {
      final user = await ApiService.fetchUserInfo(userId);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load user: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await SessionManager.clearSession();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? const Center(child: Text('사용자 정보를 불러올 수 없습니다.'))
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 아이디: ${_user!.id}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('📛 닉네임: ${_user!.name}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text('🎞️ 구독 중인 OTT:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _user!.subscribedOtt.map((o) => Chip(label: Text(o))).toList(),
            ),
            const SizedBox(height: 16),
            const Text('💖 선호 장르:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _user!.favoriteGenres.map((g) => Chip(label: Text(g))).toList(),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _logout,
                child: const Text('로그아웃'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
