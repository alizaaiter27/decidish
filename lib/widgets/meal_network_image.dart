import 'package:decidish/utils/app_colors.dart';
import 'package:flutter/material.dart';

/// Loads [imageUrl] over HTTPS (e.g. TheMealDB). Sizes the image from [LayoutBuilder]
/// so we never pass an unbounded width into [Image.network].
class MealNetworkImage extends StatelessWidget {
  const MealNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.iconSize = 32,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double iconSize;

  static const _kHeaders = {
    'User-Agent': 'Mozilla/5.0 (compatible; Decidish/1.0)',
  };

  static bool _hasUrl(String? u) {
    if (u == null) return false;
    final s = u.trim();
    return s.isNotEmpty && (s.startsWith('http://') || s.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    if (!_hasUrl(imageUrl)) {
      return _fallback(radius);
    }

    final url = imageUrl!.trim();
    final fixedH = height;

    return ClipRRect(
      borderRadius: radius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          var maxW = constraints.maxWidth;
          if (!maxW.isFinite || maxW <= 0) {
            maxW = MediaQuery.sizeOf(context).width;
          }
          if (width != null && width != double.infinity && width!.isFinite) {
            maxW = width!;
          }

          if (fixedH != null) {
            return SizedBox(
              width: maxW,
              height: fixedH,
              child: Image.network(
                url,
                fit: fit,
                width: maxW,
                height: fixedH,
                alignment: Alignment.center,
                headers: _kHeaders,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => _fallback(radius),
              ),
            );
          }

          return Image.network(
            url,
            fit: fit,
            width: maxW,
            headers: _kHeaders,
            errorBuilder: (_, __, ___) => _fallback(radius),
          );
        },
      ),
    );
  }

  Widget _fallback(BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: width,
        height: height,
        color: AppColors.secondary,
        alignment: Alignment.center,
        child: Icon(
          Icons.restaurant_menu,
          size: iconSize,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
