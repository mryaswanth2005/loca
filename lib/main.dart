import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'models/weather.dart';
import 'services/weather_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WeatherProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: WeatherScreen(),
      ),
    );
  }
}

class WeatherProvider extends ChangeNotifier {
  WeatherService _weatherService = WeatherService();
  Weather? _weather;
  bool _loading = false;

  Weather? get weather => _weather;
  bool get loading => _loading;

  Future<void> fetchWeatherByCoordinates(
      double latitude, double longitude) async {
    _loading = true;
    notifyListeners();

    try {
      _weather =
          await _weatherService.fetchWeatherByCoordinates(latitude, longitude);
    } catch (e) {
      _weather = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String currentAddress = 'My Address';
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: 'Please enable Your Location Service');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg:
              'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];

      setState(() {
        currentPosition = position;
        currentAddress =
            "${place.locality}, ${place.postalCode}, ${place.country}";
      });

      var weatherProvider =
          Provider.of<WeatherProvider>(context, listen: false);
      weatherProvider.fetchWeatherByCoordinates(
          position.latitude, position.longitude);
    } catch (e) {
      print(e.toString());
      Fluttertoast.showToast(msg: 'Error getting location: $e');
    }
  }

  void _onContainerTap(BuildContext context) {
    var weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    if (weatherProvider.weather != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FiveDayForecastScreen(
              forecast: weatherProvider.weather!.forecast),
        ),
      );
    } else {
      Fluttertoast.showToast(msg: 'No weather data available to show');
    }
  }

  @override
  Widget build(BuildContext context) {
    var weatherProvider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _onContainerTap(context),
              child: Container(
                height: 200,
                width: double.infinity,
                margin: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.black),
                ),
                child: weatherProvider.loading
                    ? Center(child: CircularProgressIndicator())
                    : weatherProvider.weather != null
                        ? Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: -10,
                                child: Container(
                                  height: 140,
                                  width: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        'http://openweathermap.org/img/wn/${weatherProvider.weather!.icon}@2x.png',
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 40,
                                bottom: 20,
                                child: Text(
                                  '${weatherProvider.weather!.cityName}',
                                  style: TextStyle(fontSize: 35),
                                ),
                              ),
                              Positioned(
                                right: 30,
                                top: 20,
                                child: Text(
                                  '${weatherProvider.weather!.temperature}°C',
                                  style: TextStyle(fontSize: 25),
                                ),
                              ),
                              Positioned(
                                right: 30,
                                top: 70,
                                child: Text(
                                  '${weatherProvider.weather!.description}',
                                  style: TextStyle(fontSize: 23),
                                ),
                              ),
                            ],
                          )
                        : Center(child: Text('No weather data available')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FiveDayForecastScreen extends StatelessWidget {
  final List<Forecast> forecast;

  FiveDayForecastScreen({required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('5-Day Forecast'),
      ),
      body: ListView.builder(
        itemCount: forecast.length,
        itemBuilder: (context, index) {
          final day = forecast[index];
          return Card(
            child: ListTile(
              leading: Image.network(
                  'http://openweathermap.org/img/wn/${day.icon}@2x.png'),
              title: Text(day.date),
              subtitle: Text('${day.temperature}°C, ${day.description}'),
            ),
          );
        },
      ),
    );
  }
}
