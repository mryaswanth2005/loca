class Weather {
  final String cityName;
  final double temperature;
  final String description;
  final String icon;
  final List<Forecast> forecast;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.forecast,
  });
}

class Forecast {
  final String date;
  final double temperature;
  final String description;
  final String icon;

  Forecast({
    required this.date,
    required this.temperature,
    required this.description,
    required this.icon,
  });
}
