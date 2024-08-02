import 'package:flutter/material.dart';
import 'package:location/models/weather.dart';
import 'package:location/services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherService _weatherService = WeatherService();
  Weather? _weather;
  bool _loading = false;
  String? _errorMessage;

  Weather? get weather => _weather;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWeatherByCoordinates(
      double latitude, double longitude) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _weather =
          await _weatherService.fetchWeatherByCoordinates(latitude, longitude);
    } catch (e) {
      _errorMessage = e.toString();
      _weather = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
