import 'package:flutter/material.dart';
import 'package:spendly/shared/services/weather_service.dart';

class AdvancedWeatherCard extends StatelessWidget {
  final WeatherInfo weather;

  const AdvancedWeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Text Information
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weather.temperature.round()}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                Text(
                  '°',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              weather.condition,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // 3D Weather Graphic
        SizedBox(
          width: 70,
          height: 60,
          child: _buildWeatherGraphic(weather.weatherCode),
        ),
      ],
    );
  }

  Widget _buildWeatherGraphic(int code) {
    // Determine which components to show
    bool showSun = code == 0 || code == 1 || code == 2 || code == 3;
    bool showCloud = code >= 1;
    bool showRain = (code >= 51 && code <= 67) || (code >= 80 && code <= 82);
    bool showLightning = code >= 95 && code <= 99;
    bool showSnow = (code >= 71 && code <= 77) || (code >= 85 && code <= 86);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (showSun)
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
                    color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        if (showCloud)
          Positioned(
            bottom: 5,
            left: -5,
            child: _buildCloud(),
          ),
        if (showRain)
          Positioned(
            bottom: -5,
            right: 15,
            child: _buildRainDrop(),
          ),
        if (showLightning)
          Positioned(
            bottom: -5,
            right: 10,
            child: const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 24, shadows: [Shadow(color: Colors.orange, blurRadius: 8)]),
          ),
        if (showSnow)
          Positioned(
            bottom: -5,
            right: 15,
            child: const Icon(Icons.ac_unit_rounded, color: Colors.lightBlueAccent, size: 20, shadows: [Shadow(color: Colors.blue, blurRadius: 8)]),
          ),
      ],
    );
  }

  Widget _buildCloud() {
    return SizedBox(
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
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFCFD8DC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 6))
                ]
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white, Color(0xFFECEFF1)],
                  center: Alignment(-0.5, -0.5),
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white, Color(0xFFE0E0E0)],
                  center: Alignment(-0.3, -0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRainDrop() {
    return Container(
      width: 8,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
          topLeft: Radius.circular(2),
          topRight: Radius.circular(2),
        ),
        boxShadow: [
          BoxShadow(color: Colors.lightBlueAccent.withValues(alpha: 0.5), blurRadius: 4)
        ]
      ),
    );
  }
}
