import 'package:flutter/material.dart';
import 'package:wat2watch_app/services/api_service.dart';
import 'package:wat2watch_app/services/session_manager.dart';
import 'package:wat2watch_app/models/user.dart';
import 'package:provider/provider.dart';
import 'package:wat2watch_app/providers/user_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _nameController = TextEditingController();

  final List<String> _ottOptions = [
    'Netflix', 'Disney+', 'Watcha', 'Wavve', 'TVING', 'Coupang Play', 'Prime Video'
  ];
  final List<String> _genreOptions = [
    '액션', '코미디', '드라마', '로맨스', '공포', '스릴러', 'SF', '애니메이션', '다큐멘터리'
  ];

  final Set<String> _selectedOtt = {};
  final Set<String> _selectedGenres = {};

  bool _isSubmitting = false;
  String _message = '';

  Future<void> _submit() async {
    final id = _idController.text.trim();
    final pw = _pwController.text;
    final name = _nameController.text.trim();

    if (id.isEmpty || pw.isEmpty || name.isEmpty || _selectedOtt.isEmpty || _selectedGenres.isEmpty) {
      setState(() => _message = '모든 항목을 입력해주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = '';
    });

    try {
      print('📡 Registering user...');
      await ApiService.registerUser(
        id: id,
        password: pw,
        name: name,
        subscribedOtt: _selectedOtt.toList(),
        favoriteGenres: _selectedGenres.toList(),
      );

      print('✅ Registration success, now logging in...');
      final user = await ApiService.loginUser(id, pw);

      await SessionManager.saveUserId(user.id);
      if (!mounted) return;

      Provider.of<UserProvider>(context, listen: false).setUser(user);

      print('🚀 Navigating to home...');
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false, arguments: {'userId': user.id});
    } catch (e) {
      print('❌ Error during register/login: $e');
      setState(() => _message = '회원가입 실패: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildMultiChip(String label, Set<String> selectionSet) {
    final isSelected = selectionSet.contains(label);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selected ? selectionSet.add(label) : selectionSet.remove(label);
        });
      },
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: '아이디'),
            ),
            TextField(
              controller: _pwController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '닉네임'),
            ),
            const SizedBox(height: 20),
            const Text('구독 중인 OTT를 선택해주세요:'),
            Wrap(
              spacing: 8,
              children: _ottOptions.map((o) => _buildMultiChip(o, _selectedOtt)).toList(),
            ),
            const SizedBox(height: 20),
            const Text('좋아하는 장르를 선택해주세요:'),
            Wrap(
              spacing: 8,
              children: _genreOptions.map((g) => _buildMultiChip(g, _selectedGenres)).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('가입하기'),
            ),
            const SizedBox(height: 10),
            Text(_message, style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}