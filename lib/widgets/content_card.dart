import 'package:flutter/material.dart';
import 'package:wat2watch_app/models/content.dart';

class ContentCard extends StatelessWidget {
  final Content content;
  final VoidCallback? onTap;

  const ContentCard({super.key, required this.content, this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = content.posterUrl != null
        ? 'https://image.tmdb.org/t/p/w500${content.posterUrl}'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            imageUrl != null
                ? Image.network(imageUrl, height: 200, fit: BoxFit.cover)
                : Container(height: 200, color: Colors.grey),
            const SizedBox(height: 5),
            Text(
              content.title ?? '제목 없음',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
