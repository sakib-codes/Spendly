import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherInfo {
  final double temperature;
  final int weatherCode;
  final String condition;

  WeatherInfo({
    required this.temperature,
    required this.weatherCode,
    required this.condition,
  });
}

class WeatherService {
  Future<WeatherInfo> getCurrentWeather() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    } 

    // Fetch position with high accuracy to ensure it picks up emulator changes.
    Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
    );
    
    // Fetch weather from open-meteo (no API key required)
    final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current_weather=true');
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final weatherCode = data['current_weather']['weathercode'] as int;
      final temperature = (data['current_weather']['temperature'] as num).toDouble();
      final condition = _getConditionFromCode(weatherCode);

      print('🌦️ Real-time Weather Fetched for Lat: ${position.latitude}, Lon: ${position.longitude}');
      print('🌦️ Result: $temperature°C, $condition');

      return WeatherInfo(
        temperature: temperature,
        weatherCode: weatherCode,
        condition: condition,
      );
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  String _getConditionFromCode(int code) {
    if (code == 0) return 'Sunny';
    if (code == 1 || code == 2) return 'Partly Cloudy';
    if (code == 3) return 'Cloudy';
    if (code >= 45 && code <= 48) return 'Foggy';
    if (code >= 51 && code <= 57) return 'Drizzle';
    if (code >= 61 && code <= 67) return 'Rainy';
    if (code >= 71 && code <= 77) return 'Snowy';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 85 && code <= 86) return 'Snow Showers';
    if (code >= 95 && code <= 99) return 'Stormy';
    return 'Cloudy';
  }
}
