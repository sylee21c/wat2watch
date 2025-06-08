import 'package:flutter/material.dart';

class RatingStar extends StatelessWidget {
  final double rating;                  // 0.5 ~ 5.0
  final void Function(double)? onRate;  // 유저 평가 시 호출되는 콜백
  final bool editable;                  // 평가 가능 여부 (읽기 전용/수정 가능)

  const RatingStar({
    super.key,
    required this.rating,
    this.onRate,
    this.editable = false,
  });

  Widget _buildStar(int index, BuildContext context) {
    double current = index + 1.0;

    Icon icon;
    if (rating >= current) {
      icon = const Icon(Icons.star, color: Colors.amber);
    } else if (rating >= current - 0.5) {
      icon = const Icon(Icons.star_half, color: Colors.amber);
    } else {
      icon = const Icon(Icons.star_border, color: Colors.amber);
    }

    return GestureDetector(
      onTapDown: editable && onRate != null
          ? (details) {
        final box = context.findRenderObject() as RenderBox;
        final localX = details.localPosition.dx;
        final halfWidth = box.size.width / 2;

        final score = (localX < halfWidth) ? index + 0.5 : index + 1.0;
        onRate!(score);
      }
          : null,
      child: SizedBox(
        width: 30,
        child: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) => _buildStar(index, context)),
    );
  }
}
