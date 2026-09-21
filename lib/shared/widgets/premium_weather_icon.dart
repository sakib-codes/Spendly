import 'package:flutter/material.dart';

class PremiumWeatherIcon extends StatelessWidget {
  final int weatherCode;
  final double size;

  const PremiumWeatherIcon({
    super.key,
    required this.weatherCode,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    List<Color> gradientColors;
    Color glowColor;

    // Map WMO Weather codes to visuals
    if (weatherCode == 0) {
      // Clear sky (Sunny)
      iconData = Icons.wb_sunny_rounded;
      gradientColors = [const Color(0xFFFFD700), const Color(0xFFFF8C00)];
      glowColor = const Color(0xFFFF8C00);
    } else if (weatherCode == 1 || weatherCode == 2) {
      // Partly cloudy
      iconData = Icons.cloud_rounded; // partly_cloudy could be used if available
      gradientColors = [const Color(0xFFFFD700), const Color(0xFF90A4AE)];
      glowColor = const Color(0xFF90A4AE);
    } else if (weatherCode == 3) {
      // Overcast
      iconData = Icons.cloud_rounded;
      gradientColors = [const Color(0xFFB0BEC5), const Color(0xFF78909C)];
      glowColor = const Color(0xFF78909C);
    } else if (weatherCode >= 45 && weatherCode <= 48) {
      // Fog
      iconData = Icons.foggy;
      gradientColors = [const Color(0xFFCFD8DC), const Color(0xFF90A4AE)];
      glowColor = const Color(0xFF90A4AE);
    } else if ((weatherCode >= 51 && weatherCode <= 67) || (weatherCode >= 80 && weatherCode <= 82)) {
      // Rain / Drizzle
      iconData = Icons.water_drop_rounded;
      gradientColors = [const Color(0xFF4FC3F7), const Color(0xFF0288D1)];
      glowColor = const Color(0xFF0288D1);
    } else if ((weatherCode >= 71 && weatherCode <= 77) || (weatherCode >= 85 && weatherCode <= 86)) {
      // Snow
      iconData = Icons.ac_unit_rounded;
      gradientColors = [const Color(0xFFE1F5FE), const Color(0xFF81D4FA)];
      glowColor = const Color(0xFF81D4FA);
    } else if (weatherCode >= 95 && weatherCode <= 99) {
      // Thunderstorm
      iconData = Icons.flash_on_rounded;
      gradientColors = [const Color(0xFFB39DDB), const Color(0xFF5E35B1)];
      glowColor = const Color(0xFF5E35B1);
    } else {
      // Unknown / Default (Cloudy)
      iconData = Icons.cloud_rounded;
      gradientColors = [const Color(0xFFB0BEC5), const Color(0xFF78909C)];
      glowColor = const Color(0xFF78909C);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.5),
            blurRadius: size * 0.4,
            spreadRadius: size * 0.1,
            offset: Offset(0, size * 0.1),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.3),
            blurRadius: size * 0.1,
            spreadRadius: 0,
            offset: Offset(-size * 0.05, -size * 0.05),
          ), // inner light reflection
        ],
      ),
      child: Center(
        child: Icon(
          iconData,
          color: Colors.white,
          size: size * 0.55,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
      ),
    );
  }
}
