import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A sleek, atmospheric skeleton loader for the weather card.
///
/// Features:
/// - Exact pixel alignment with [AdvancedWeatherCard] to eliminate shifting during transitions.
/// - The sun container and cloud are pinned at the exact same coordinates and dimensions as [AdvancedWeatherCard].
/// - Gentle breathing ambient glow on the sun and soft breathing opacity on the cloud.
/// - Shimmering typography placeholders matching temperature and condition geometry.
class WeatherSkeletonLoader extends StatefulWidget {
  const WeatherSkeletonLoader({super.key});

  @override
  State<WeatherSkeletonLoader> createState() => _WeatherSkeletonLoaderState();
}

class _WeatherSkeletonLoaderState extends State<WeatherSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Breathing pulse for ambient glow (0.0 -> 1.0 -> 0.0)
        final pulse = (math.sin(t * 2 * math.pi) + 1) / 2;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Shimmering typography placeholders
            // Right-aligned to anchor at the exact same baseline as AdvancedWeatherCard
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerPill(
                      width: 38,
                      height: 28,
                      borderRadius: 6,
                      theme: theme,
                      isDark: isDark,
                      shimmerValue: t,
                    ),
                    const SizedBox(width: 4),
                    _buildShimmerPill(
                      width: 10,
                      height: 10,
                      borderRadius: 5,
                      theme: theme,
                      isDark: isDark,
                      shimmerValue: t,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                _buildShimmerPill(
                  width: 60,
                  height: 14,
                  borderRadius: 4,
                  theme: theme,
                  isDark: isDark,
                  shimmerValue: t,
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Right: Living 3D weather graphic preview
            // Fixed 70x60 dimensions, perfectly overlapping AdvancedWeatherCard
            SizedBox(
              width: 70,
              height: 60,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Glowing sun - fixed 45x45 at top: 0, right: 0 (exact match to AdvancedWeatherCard)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFFFF59D), Color(0xFFFFB300)],
                          center: Alignment(-0.3, -0.3),
                          radius: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFB300).withValues(
                              alpha: 0.4 + (pulse * 0.25),
                            ),
                            blurRadius: 12 + (pulse * 6),
                            spreadRadius: 1 + (pulse * 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Soft cloud - fixed at bottom: 5, left: -5 (exact match to AdvancedWeatherCard)
                  Positioned(
                    bottom: 5,
                    left: -5,
                    child: _buildCloud(isDark, pulse),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerPill({
    required double width,
    required double height,
    required double borderRadius,
    required ThemeData theme,
    required bool isDark,
    required double shimmerValue,
  }) {
    final baseAlpha = isDark ? 0.08 : 0.06;
    final highlightAlpha = isDark ? 0.22 : 0.16;

    final baseColor = theme.colorScheme.onSurface.withValues(alpha: baseAlpha);
    final highlightColor =
        theme.colorScheme.onSurface.withValues(alpha: highlightAlpha);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(-1.8 + (shimmerValue * 3.6), -0.2),
          end: Alignment(-0.6 + (shimmerValue * 3.6), 0.2),
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildCloud(bool isDark, double pulse) {
    final baseColor = isDark ? const Color(0xFF90A4AE) : Colors.white;
    final darkShade =
        isDark ? const Color(0xFF607D8B) : const Color(0xFFCFD8DC);
    final midShade =
        isDark ? const Color(0xFF78909C) : const Color(0xFFECEFF1);
    final lightShade =
        isDark ? const Color(0xFF546E7A) : const Color(0xFFE0E0E0);

    return Opacity(
      opacity: 0.85 + (pulse * 0.15),
      child: SizedBox(
        width: 65,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Base pill
            Positioned(
              bottom: 0,
              child: Container(
                width: 60,
                height: 25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    colors: [baseColor, darkShade],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
            // Left bump
            Positioned(
              bottom: 8,
              left: 5,
              child: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [baseColor, midShade],
                    center: const Alignment(-0.5, -0.5),
                  ),
                ),
              ),
            ),
            // Right bump
            Positioned(
              bottom: 8,
              right: 12,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [baseColor, lightShade],
                    center: const Alignment(-0.3, -0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
