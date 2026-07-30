import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class AvatarStack extends StatelessWidget {
  final List<String> initials;
  final double size;
  final int maxVisible;

  const AvatarStack({
    super.key,
    required this.initials,
    this.size = 26,
    this.maxVisible = 4,
  });

  static const _palette = [
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
    Color(0xFF2563EB),
    Color(0xFFDB2777),
  ];

  @override
  Widget build(BuildContext context) {
    final displayCount = initials.length > maxVisible
        ? maxVisible
        : initials.length;
    final remaining = initials.length - displayCount;
    final totalItems = displayCount + (remaining > 0 ? 1 : 0);
    const overlap = 6.0;
    final totalWidth = size * totalItems - overlap * (totalItems - 1);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(totalItems, (index) {
          final isOverflow = remaining > 0 && index == displayCount;
          return Positioned(
            left: index * (size - overlap),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOverflow
                    ? AppColors.sand
                    : _palette[index % _palette.length],
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: isOverflow
                  ? Text(
                      '+$remaining',
                      style: TextStyle(
                        fontSize: size * 0.34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    )
                  : Text(
                      initials[index],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }
}
