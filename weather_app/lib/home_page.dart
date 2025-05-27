import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Weather> _hourlyForecast = [];
  List<Weather> _weeklyForecast = [];

  final WeatherFactory _wf = WeatherFactory("23bcaf5f94718844e0bfa902b1d1145a");

  Weather? _weather;
  String _cityName = "mednipur";

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  void _fetchWeather() {
    if (_cityName.isNotEmpty) {
      _wf.currentWeatherByCityName(_cityName).then((weather) {
        setState(() {
          _weather = weather;
        });
      });

      _wf
          .fiveDayForecastByCityName(_cityName)
          .then((forecast) {
            setState(() {
              _hourlyForecast =
                  forecast
                      .take(6)
                      .toList(); // next 6 time points (3-hour intervals)
              _weeklyForecast = _groupDailyForecast(forecast);
            });
          })
          .catchError((error) {
            print("Error fetching forecast: $error");
          });
    }
  }

  List<Weather> _groupDailyForecast(List<Weather> forecast) {
    Map<String, Weather> daily = {};
    for (var weather in forecast) {
      final date = DateFormat('yyyy-MM-dd').format(weather.date!);
      if (!daily.containsKey(date)) {
        daily[date] = weather; // pick the first data point of each day
      }
    }
    return daily.values.take(8).toList(); // max 7 days
  }

  IconData getWeatherIcon(String main, {DateTime? dateTime}) {
    final now = dateTime ?? DateTime.now();
    final hour = now.hour;

    final isNight = hour < 5 || hour > 19;
    // morning 5 am to evening 7 pm icon will sun

    switch (main.toLowerCase()) {
      case 'clear':
        return isNight ? Icons.nights_stay : Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.blur_on;
      default:
        return Icons.cloud_queue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMM d | hh:mm a').format(now);

    return Scaffold(
      appBar: AppBar(title: Text("Weather App", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, ),), centerTitle: true, backgroundColor: Colors.orange.shade100,),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child:
            _weather == null
                ? Center(child: Text("No such city"))
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15),
                      _cityInput(),
                      SizedBox(height: 15),
                      Card(
                        child: Column(
                          children: [
                            Container(
                              height: 220,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade900,
                                    Colors.blue.shade500,
                                    Colors.blue.shade200,
                                    Colors.orange.shade100,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Today",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          children: [
                                            _currentTemp(),
                                            SizedBox(height: 10),
                                            Text(
                                              "Day: ${_weather?.tempMax?.celsius?.toStringAsFixed(0) ?? "--"}°C | "
                                              "Night: ${_weather?.tempMin?.celsius?.toStringAsFixed(0) ?? "--"}°C",
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Icon(
                                              getWeatherIcon(
                                                _weather?.weatherMain ?? "",
                                              ),
                                              size: 60,
                                              color: Colors.white,
                                            ),
                                            SizedBox(height: 15),
                                            _overCast(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _hourlyForecast.length,
                                itemBuilder: (context, index) {
                                  final hour = _hourlyForecast[index];
                                  final time = DateFormat(
                                    'h:mm a',
                                  ).format(hour.date!);
                                  final temp =
                                      "${hour.temperature?.celsius?.toStringAsFixed(0)}°C";
                                  final rain =
                                      "${hour.rainLast3Hours?.toStringAsFixed(0) ?? "0"}%";
                                  return Container(
                                    width: 90,
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          time,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text("$rain"),
                                        Icon(
                                          getWeatherIcon(
                                            _hourlyForecast[index]
                                                    .weatherMain ??
                                                "",
                                            dateTime:
                                                _hourlyForecast[index].date,
                                          ),
                                          color: Colors.blue,
                                        ),

                                        Text(temp),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Weekly Forecast
                      Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                "7-Day Forecast",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            ..._weeklyForecast.map((day) {
                              final date = DateFormat(
                                'EEEE, MMM d',
                              ).format(day.date!);
                              final min =
                                  day.tempMin?.celsius?.toStringAsFixed(0) ??
                                  "--";
                              final max =
                                  day.tempMax?.celsius?.toStringAsFixed(0) ??
                                  "--";
                              final icon = getEmoji(day.weatherMain ?? "");

                              return Column(
                                children: [
                                  ListTile(
                                    title: Text(date),
                                    subtitle: Text("Temp: $max°C / $min°C"),
                                    trailing: Text(
                                      icon,
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  Divider(height: 10),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _cityInput() {
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 60),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: 'Enter City Name',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          prefixIcon: Icon(Icons.location_on, color: Colors.red),
        ),
        onSubmitted: (cityName) {
          setState(() {
            _cityName = cityName;
          });
          _fetchWeather(); // Fetch weather for the entered city
        },
      ),
    );
  }

  Widget _locationHeader() {
    return Text(
      _weather?.areaName ?? "Loading...",
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
    );
  }

  Widget _currentTemp() {
    return Text(
      "${_weather?.temperature?.celsius?.toStringAsFixed(0) ?? "N/A"}°C",
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _overCast() {
    return Text(
      _weather?.weatherDescription ?? "No description available",
      style: TextStyle(color: Colors.white, fontSize: 15),
    );
  }

  String getEmoji(String main) {
    switch (main.toLowerCase()) {
      case 'clear':
        return "☀️";
      case 'clouds':
        return "☁️";
      case 'rain':
      case 'drizzle':
        return "🌧️";
      case 'thunderstorm':
        return "⛈️";
      case 'snow':
        return "❄️";
      case 'mist':
      case 'fog':
      case 'haze':
        return "🌫️";
      default:
        return "🌤️";
    }
  }
}
