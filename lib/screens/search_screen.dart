// lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:wat2watch_app/services/api_service.dart';
import 'package:wat2watch_app/models/content.dart';
import 'package:wat2watch_app/widgets/content_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Content> _results = [];
  bool _isLoading = false;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final results = await ApiService.searchContent(query);
      setState(() => _results = results);
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('콘텐츠 검색')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: '영화/TV 제목 입력',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
              child: GridView.builder(
                itemCount: _results.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.6,
                ),
                itemBuilder: (context, index) {
                  final content = _results[index];
                  return ContentCard(
                    content: content,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/detail',
                        arguments: content,
                      );
                    },
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
