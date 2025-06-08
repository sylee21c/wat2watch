import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wat2watch_app/services/api_service.dart';
import 'package:wat2watch_app/services/session_manager.dart';
import 'package:wat2watch_app/models/user.dart';
import 'package:wat2watch_app/providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    final id = _idController.text.trim();
    final password = _passwordController.text;

    if (id.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'ID와 비밀번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = await ApiService.loginUser(id, password);
      await SessionManager.saveUserId(user.id);

      Provider.of<UserProvider>(context, listen: false).setUser(user);
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _errorMessage = '로그인 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wat2Watch 로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: '아이디'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _login,
                child: const Text('로그인'),
              ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text(
                '아직 회원이 아니신가요? 회원가입',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
