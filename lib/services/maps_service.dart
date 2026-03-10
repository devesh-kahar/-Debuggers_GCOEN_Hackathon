import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/models.dart';
import '../config/api_keys.dart';
import 'crime_data_service.dart';

class MapsService {
  static final MapsService _instance = MapsService._internal();
  factory MapsService() => _instance;
  MapsService._internal();

  final CrimeDataService _crimeService = CrimeDataService();

  /// Get multiple route options with safety scores
  Future<List<RouteSafety>> getRoutesWithSafety({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      // Get alternative routes from Google Directions API
      final routes = await _getDirections(origin, destination);
      
      // Calculate safety score for each route
      final routesWithSafety = <RouteSafety>[];
      
      for (int i = 0; i < routes.length; i++) {
        final route = routes[i];
        
        // Get crimes along this route
        final crimes = await _crimeService.getCrimesAlongRoute(
          routePoints: route['polylinePoints'],
          bufferMeters: 500,
        );

        // Get street light count (simplified - using Places API)
        final streetLights = await _getStreetLightCount(route['polylinePoints']);

        // Calculate safety score
        final safetyScore = SafetyScore.calculate(
          crimeCount: crimes.length,
          streetLightCount: streetLights,
          isNightTime: _isNightTime(),
          userReports: 0, // TODO: Implement user reports from Firebase
          routeLength: route['distance'],
        );

        routesWithSafety.add(
          RouteSafety(
            routeId: 'route_$i',
            polylinePoints: route['polylinePoints'],
            distanceMeters: route['distance'],
            durationSeconds: route['duration'],
            safetyScore: safetyScore,
            nearbyCrimes: crimes,
            streetLightCount: streetLights,
            summary: route['summary'],
          ),
        );
      }

      // Sort by safety score (highest first)
      routesWithSafety.sort((a, b) => b.safetyScore.overall.compareTo(a.safetyScore.overall));

      return routesWithSafety;
    } catch (e) {
      print('Error getting routes with safety: $e');
      return [];
    }
  }

  /// Get directions from Google Directions API
  Future<List<Map<String, dynamic>>> _getDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    final url = Uri.parse(
      '${ApiEndpoints.googleMapsDirections}'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&alternatives=true'
      '&mode=walking'
      '&key=${ApiKeys.googleMapsApiKey}',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        final routes = data['routes'] as List;
        
        return routes.map((route) {
          final leg = route['legs'][0];
          final polyline = route['overview_polyline']['points'];
          
          return {
            'polylinePoints': _decodePolyline(polyline),
            'distance': leg['distance']['value'].toDouble(),
            'duration': leg['duration']['value'],
            'summary': route['summary'] ?? 'Route',
          };
        }).toList();
      }
    }

    throw Exception('Failed to get directions');
  }

  /// Decode Google polyline to list of LatLng
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  /// Get street light count along route (simplified)
  Future<int> _getStreetLightCount(List<LatLng> routePoints) async {
    try {
      // Sample a few points along the route
      final samplePoints = _samplePoints(routePoints, 3);
      int totalLights = 0;

      for (final point in samplePoints) {
        final url = Uri.parse(
          '${ApiEndpoints.googlePlaces}'
          '?location=${point.latitude},${point.longitude}'
          '&radius=200'
          '&keyword=street+light'
          '&key=${ApiKeys.googleMapsApiKey}',
        );

        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          totalLights += (data['results'] as List).length;
        }
      }

      return totalLights;
    } catch (e) {
      print('Error getting street light count: $e');
      // Return estimated count based on route length
      return (routePoints.length / 10).round();
    }
  }

  List<LatLng> _samplePoints(List<LatLng> points, int count) {
    if (points.length <= count) return points;
    
    final step = points.length / count;
    return List.generate(count, (i) => points[(i * step).floor()]);
  }

  bool _isNightTime() {
    final hour = DateTime.now().hour;
    return hour < 6 || hour >= 20;
  }

  /// Get address from coordinates
  Future<String> getAddressFromCoordinates(LatLng location) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${location.latitude},${location.longitude}'
        '&key=${ApiKeys.googleMapsApiKey}',
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    
    return 'Unknown location';
  }
}
