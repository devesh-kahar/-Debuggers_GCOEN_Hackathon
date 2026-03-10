import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/crime_incident.dart';
import '../config/api_keys.dart';

class CrimeDataService {
  static final CrimeDataService _instance = CrimeDataService._internal();
  factory CrimeDataService() => _instance;
  CrimeDataService._internal();

  /// Fetch crime data from UK Police API (No API key needed)
  Future<List<CrimeIncident>> fetchUKPoliceCrimes({
    required LatLng location,
    String? date, // Format: YYYY-MM
  }) async {
    try {
      final dateParam = date ?? _getLastMonthDate();
      final url = Uri.parse(
        '${ApiEndpoints.ukPoliceCrimeBase}/crimes-street/all-crime'
        '?lat=${location.latitude}'
        '&lng=${location.longitude}'
        '&date=$dateParam',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CrimeIncident.fromUKPoliceJson(json)).toList();
      } else {
        throw Exception('Failed to load crime data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching UK Police crimes: $e');
      return [];
    }
  }

  /// Fetch crime data from Crimeometer API (USA)
  Future<List<CrimeIncident>> fetchCrimeometerCrimes({
    required LatLng location,
    double radiusMiles = 1.0,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.crimeometerBase}/incidents/raw-data'
        '?lat=${location.latitude}'
        '&lon=${location.longitude}'
        '&distance=${radiusMiles}mi'
        '&datetime_ini=${_getDateDaysAgo(30)}'
        '&datetime_end=${_getCurrentDate()}',
      );

      final response = await http.get(
        url,
        headers: {
          'x-api-key': ApiKeys.crimeometerApiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> incidents = data['incidents'] ?? [];
        return incidents.map((json) => CrimeIncident.fromCrimeometerJson(json)).toList();
      } else {
        throw Exception('Failed to load crime data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching Crimeometer crimes: $e');
      return [];
    }
  }

  /// Get crimes along a route (within buffer distance)
  Future<List<CrimeIncident>> getCrimesAlongRoute({
    required List<LatLng> routePoints,
    double bufferMeters = 500,
  }) async {
    final Set<CrimeIncident> allCrimes = {};

    // Sample points along the route
    final samplePoints = _sampleRoutePoints(routePoints, maxPoints: 5);

    for (final point in samplePoints) {
      final crimes = await fetchUKPoliceCrimes(location: point);
      
      // Filter crimes within buffer distance
      final nearbyCrimes = crimes.where((crime) {
        final distance = _calculateDistance(
          point.latitude,
          point.longitude,
          crime.latitude,
          crime.longitude,
        );
        return distance <= bufferMeters;
      }).toList();

      allCrimes.addAll(nearbyCrimes);
    }

    return allCrimes.toList();
  }

  /// Sample points along route for efficient API calls
  List<LatLng> _sampleRoutePoints(List<LatLng> points, {int maxPoints = 5}) {
    if (points.length <= maxPoints) return points;

    final sampledPoints = <LatLng>[];
    final step = points.length / maxPoints;

    for (int i = 0; i < maxPoints; i++) {
      final index = (i * step).floor();
      sampledPoints.add(points[index]);
    }

    return sampledPoints;
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);

  String _getLastMonthDate() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    return '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  String _getDateDaysAgo(int days) {
    final date = DateTime.now().subtract(Duration(days: days));
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T00:00:00';
  }
}
