import 'package:flutter/material.dart';
import 'package:wat2watch_app/services/api_service.dart';

class RatingScreen extends StatefulWidget {
  final String userId;

  const RatingScreen({super.key, required this.userId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double? _savedRating;
  String? _savedComment;
  bool _isSubmitting = false;
  String _statusMessage = '';

  void _showRatingDialog(BuildContext context, String contentId, String contentTitle) async {
    double tempRating = 0.0;
    TextEditingController commentController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$contentTitle 평점 입력'),
          content: SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('평점: ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Slider(
                            value: tempRating,
                            onChanged: (v) => setState(() => tempRating = v),
                            divisions: 10,
                            min: 0.0,
                            max: 5.0,
                            label: tempRating.toStringAsFixed(1),
                          ),
                        ),
                        Text(tempRating.toStringAsFixed(1)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '코멘트(선택)',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'rating': tempRating,
                  'comment': commentController.text.trim(),
                });
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await _submitRating(
        userId: widget.userId,
        contentId: contentId,
        rating: result['rating'],
        comment: result['comment'],
      );
    }
  }

  Future<void> _submitRating({
    required String userId,
    required String contentId,
    required double rating,
    String? comment,
  }) async {
    setState(() {
      _isSubmitting = true;
      _statusMessage = '';
    });

    try {
      await ApiService.submitRating(userId, contentId, rating, comment ?? ''); // 서버에 평점 저장
      setState(() {
        _savedRating = rating;
        _savedComment = comment ?? '';
        _statusMessage = '평가가 저장되었습니다!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '저장 실패: $e';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final contentId = args['contentId'] as String;
    final contentTitle = args['contentTitle'] as String;

    return Scaffold(
      appBar: AppBar(title: Text('$contentTitle 평가')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () => _showRatingDialog(context, contentId, contentTitle),
              child: const Text('평가하기'),
            ),
            const SizedBox(height: 32),
            if (_savedRating != null)
              Column(
                children: [
                  Text('내가 남긴 평점: ${_savedRating!.toStringAsFixed(1)} / 5.0', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  if (_savedComment != null && _savedComment!.isNotEmpty)
                    Text('코멘트: "${_savedComment!}"', style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
                ],
              ),
            const SizedBox(height: 20),
            Text(_statusMessage, style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}
