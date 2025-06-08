import 'package:flutter/material.dart';

class OttChip extends StatelessWidget {
  final String ottName;

  const OttChip({super.key, required this.ottName});

  @override
  Widget build(BuildContext context) {
    final color = _getColor(ottName);
    final icon = _getIcon(ottName);

    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(ottName, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }

  /// OTT별 색상 지정
  Color _getColor(String name) {
    switch (name.toLowerCase()) {
      case 'netflix':
        return Colors.redAccent;
      case 'watcha':
        return Colors.pink;
      case 'tving':
        return Colors.deepPurple;
      case 'wavve':
        return Colors.blueAccent;
      case 'disney+':
        return Colors.indigo;
      case 'prime video':
      case 'amazon':
        return Colors.green;
      case 'coupang play':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// OTT별 대표 아이콘 (선택)
  IconData _getIcon(String name) {
    switch (name.toLowerCase()) {
      case 'netflix':
        return Icons.movie;
      case 'disney+':
        return Icons.star;
      case 'tving':
        return Icons.tv;
      case 'watcha':
        return Icons.theaters;
      case 'prime video':
      case 'amazon':
        return Icons.shopping_cart;
      case 'wavve':
        return Icons.waves;
      case 'coupang play':
        return Icons.local_play;
      default:
        return Icons.live_tv;
    }
  }
}
