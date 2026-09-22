import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/weather_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final weatherInfoProvider = FutureProvider<WeatherInfo>((ref) async {
  final service = ref.watch(weatherServiceProvider);
  return await service.getCurrentWeather();
});
