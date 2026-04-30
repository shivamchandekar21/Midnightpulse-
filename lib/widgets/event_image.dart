import 'package:flutter/material.dart';
import 'package:midnight_pulse/data/models/event.dart';
import 'package:midnight_pulse/theme/app_theme.dart';

class EventImage extends StatelessWidget {
  const EventImage({
    super.key,
    required this.event,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  final Event event;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (event.imageUrl.isEmpty) {
      return _ImageFallback(event: event, height: height, width: width);
    }

    if (event.usesLocalAsset) {
      return Image.asset(
        event.imageUrl,
        fit: fit,
        height: height,
        width: width,
        errorBuilder: (_, __, ___) =>
            _ImageFallback(event: event, height: height, width: width),
      );
    }

    return Image.network(
      event.imageUrl,
      fit: fit,
      height: height,
      width: width,
      errorBuilder: (_, __, ___) =>
          _ImageFallback(event: event, height: height, width: width),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            _ImageFallback(event: event, height: height, width: width),
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.event, this.height, this.width});

  final Event event;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = _paletteFor(event.tag);

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              _iconFor(event.tag),
              color: AppColors.textPrimary.withValues(alpha: 0.8),
              size: 46,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _paletteFor(String tag) {
    switch (tag.toLowerCase()) {
      case 'club':
        return const [Color(0xFF172B65), Color(0xFF7D3CFF)];
      case 'festival':
        return const [Color(0xFF103D4A), Color(0xFF49D8FF)];
      case 'live':
        return const [Color(0xFF37205F), Color(0xFFE056FD)];
      case 'lounge':
        return const [Color(0xFF16344D), Color(0xFF20E3B2)];
      case 'premium':
        return const [Color(0xFF24164E), Color(0xFF9E81FF)];
      case 'rooftop':
        return const [Color(0xFF0D2B45), Color(0xFF48C6EF)];
      default:
        return const [AppColors.surfaceAlt, AppColors.surfaceStrong];
    }
  }

  IconData _iconFor(String tag) {
    switch (tag.toLowerCase()) {
      case 'club':
        return Icons.nightlife_rounded;
      case 'festival':
        return Icons.festival_rounded;
      case 'live':
        return Icons.graphic_eq_rounded;
      case 'lounge':
        return Icons.local_bar_rounded;
      case 'premium':
        return Icons.workspace_premium_rounded;
      case 'rooftop':
        return Icons.location_city_rounded;
      default:
        return Icons.music_note_rounded;
    }
  }
}
