import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/models.dart';
import '../models/crime_incident.dart';
import '../config/api_keys.dart';
import 'crime_data_service.dart';

class MapsService {
  static final MapsService _instance = MapsService._internal();
  factory MapsService() => _instance;
  MapsService._internal();

  final CrimeDataService _crimeService = CrimeDataService();

  // ────────────────────────────────────────────────────────
  // PUBLIC: Get route options with full safety analysis
  // ────────────────────────────────────────────────────────

  Future<List<RouteSafety>> getRoutesWithSafety({
    required LatLng origin,
    required LatLng destination,
    bool isNightTime = false,
  }) async {
    try {
      final rawRoutes = await _getDirections(origin, destination);
      if (rawRoutes.isEmpty) {
        // API key not set or quota exceeded — return mock routes
        return _generateMockRoutes(origin, destination, isNightTime);
      }

      final results = <RouteSafety>[];

      for (int i = 0; i < rawRoutes.length; i++) {
        final route = rawRoutes[i];
        final points = route['polylinePoints'] as List<LatLng>;

        final crimes = await _crimeService.getCrimesAlongRoute(
          routePoints: points,
          bufferMeters: 400,
        );

        final streetLights = _estimateStreetLights(points);

        final safetyScore = SafetyScore.calculate(
          crimeCount: crimes.length,
          streetLightCount: streetLights,
          isNightTime: isNightTime,
          userReports: 0,
          routeLength: (route['distance'] as double).clamp(1, double.infinity),
        );

        final narration = generateSafetyNarration(
          route: RouteSafety(
            routeId: 'route_$i',
            polylinePoints: points,
            distanceMeters: route['distance'] as double,
            durationSeconds: route['duration'] as int,
            safetyScore: safetyScore,
            nearbyCrimes: crimes,
            streetLightCount: streetLights,
            summary: route['summary'] as String,
          ),
          isNightTime: isNightTime,
        );

        results.add(RouteSafety(
          routeId: 'route_$i',
          polylinePoints: points,
          distanceMeters: route['distance'] as double,
          durationSeconds: route['duration'] as int,
          safetyScore: safetyScore,
          nearbyCrimes: crimes,
          streetLightCount: streetLights,
          summary: route['summary'] as String,
          safetyNarration: narration,
        ));
      }

      // Sort: safest first
      results.sort((a, b) => b.safetyScore.overall.compareTo(a.safetyScore.overall));

      // Mark top as recommended
      return results;
    } catch (e) {
      print('MapsService error: $e');
      return _generateMockRoutes(origin, destination, isNightTime);
    }
  }

  // ────────────────────────────────────────────────────────
  // GOOGLE DIRECTIONS API
  // ────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _getDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    final key = ApiKeys.googleMapsApiKey;
    if (key.isEmpty) return [];

    final url = Uri.parse(
      '${ApiEndpoints.googleMapsDirections}'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&alternatives=true'
      '&mode=walking'
      '&key=$key',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return [];
    final data = json.decode(response.body);
    if (data['status'] != 'OK') return [];

    return (data['routes'] as List).map((route) {
      final leg = route['legs'][0];
      return {
        'polylinePoints': _decodePolyline(route['overview_polyline']['points']),
        'distance': (leg['distance']['value'] as num).toDouble(),
        'duration': (leg['duration']['value'] as num).toInt(),
        'summary': route['summary']?.toString() ?? 'Route',
      };
    }).toList();
  }

  // ────────────────────────────────────────────────────────
  // POLYLINE DECODER
  // ────────────────────────────────────────────────────────

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    final len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  // ────────────────────────────────────────────────────────
  // STREET LIGHT ESTIMATE (heuristic — saves API quota)
  // ────────────────────────────────────────────────────────
  // Urban areas → more lights. We approximate from route length.
  int _estimateStreetLights(List<LatLng> points) {
    if (points.isEmpty) return 5;
    final lengthKm = _routeLengthKm(points);
    // Assume 1 light per ~40 m in urban areas → 25 per km
    return (lengthKm * 25).round().clamp(2, 200);
  }

  double _routeLengthKm(List<LatLng> points) {
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += _haversineKm(points[i], points[i + 1]);
    }
    return total;
  }

  double _haversineKm(LatLng a, LatLng b) {
    const R = 6371.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(a.latitude * math.pi / 180) *
            math.cos(b.latitude * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.asin(math.sqrt(x));
  }

  // ────────────────────────────────────────────────────────
  // AI SAFETY NARRATION GENERATOR
  // ────────────────────────────────────────────────────────

  String generateSafetyNarration({
    required RouteSafety route,
    required bool isNightTime,
  }) {
    final score = route.safetyScore.overall;
    final crimes = route.nearbyCrimes;
    final highCrimes = crimes.where((c) => c.severity == 'high').length;
    final medCrimes = crimes.where((c) => c.severity == 'medium').length;
    final dist = route.distanceText;
    final dur = route.durationText;
    final timeNote = isNightTime ? 'at night' : 'at this time';

    // Top crime category
    final cats = <String, int>{};
    for (final c in crimes) {
      cats[c.categoryLabel] = (cats[c.categoryLabel] ?? 0) + 1;
    }
    final topCat = cats.isEmpty
        ? null
        : cats.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final StringBuffer narration = StringBuffer();

    if (score >= 75) {
      narration.write('✅ This $dist route looks safe $timeNote. ');
      if (crimes.isEmpty) {
        narration.write('No crime incidents detected along this path.');
      } else {
        narration.write(
            'Only ${crimes.length} minor incident${crimes.length > 1 ? 's' : ''} detected nearby.');
      }
    } else if (score >= 50) {
      narration.write('⚠️ Moderate risk along this $dist route. ');
      if (topCat != null) narration.write('$topCat is the most reported issue. ');
      if (highCrimes > 0) {
        narration.write('$highCrimes high-severity zone${highCrimes > 1 ? 's' : ''} nearby — stay alert. ');
      }
      if (isNightTime) narration.write('Consider travelling during daylight hours.');
    } else {
      narration.write('🚨 High risk detected. ${crimes.length} incidents near this route. ');
      if (highCrimes > 0) {
        narration.write('$highCrimes violent crime zone${highCrimes > 1 ? 's' : ''}. ');
      }
      if (medCrimes > 0) narration.write('$medCrimes medium-risk areas. ');
      narration.write('We recommend an alternative route if available.');
    }

    narration.write(' ($dur walk)');
    return narration.toString();
  }

  // ────────────────────────────────────────────────────────
  // MOCK ROUTES (when API key missing / quota exceeded)
  // ────────────────────────────────────────────────────────

  List<RouteSafety> _generateMockRoutes(
    LatLng origin,
    LatLng dest,
    bool isNightTime,
  ) {
    final rng = math.Random(42);

    // Generate 3 slightly different paths
    final routeConfigs = [
      (name: 'Main Road', crimeCount: 3 + rng.nextInt(4), distFactor: 1.0,  lightFactor: 1.2),
      (name: 'Back Street', crimeCount: 8 + rng.nextInt(6), distFactor: 0.85, lightFactor: 0.6),
      (name: 'Park Route',  crimeCount: 1 + rng.nextInt(3), distFactor: 1.15, lightFactor: 0.9),
    ];

    final baseDist = _haversineKm(origin, dest) * 1000; // meters
    final baseDur  = (baseDist / 1.4).toInt();          // ~5 km/h walk

    final results = <RouteSafety>[];

    for (int i = 0; i < routeConfigs.length; i++) {
      final cfg = routeConfigs[i];
      final points = _generateMockPath(origin, dest, i, rng);
      final distance = baseDist * cfg.distFactor;
      final lights = (cfg.lightFactor * 15).round();

      final crimes = _generateMockCrimesAlongRoute(points, cfg.crimeCount, rng);

      final score = SafetyScore.calculate(
        crimeCount: crimes.length,
        streetLightCount: lights,
        isNightTime: isNightTime,
        userReports: 0,
        routeLength: distance.clamp(1, double.infinity),
      );

      final route = RouteSafety(
        routeId: 'mock_$i',
        polylinePoints: points,
        distanceMeters: distance,
        durationSeconds: (baseDur * cfg.distFactor).toInt(),
        safetyScore: score,
        nearbyCrimes: crimes,
        streetLightCount: lights,
        summary: cfg.name,
        safetyNarration: '',
        isMock: true,
      );

      results.add(route.copyWith(
        safetyNarration: generateSafetyNarration(route: route, isNightTime: isNightTime),
      ));
    }

    results.sort((a, b) => b.safetyScore.overall.compareTo(a.safetyScore.overall));
    return results;
  }

  List<LatLng> _generateMockPath(
      LatLng origin, LatLng dest, int variant, math.Random rng) {
    final steps = 12;
    final points = <LatLng>[];
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final jitter = (variant + 1) * 0.0008 * math.sin(t * math.pi);
      final jitterLat =
          (variant == 1 ? jitter : -jitter) * (rng.nextDouble() * 0.5 + 0.75);
      points.add(LatLng(
        origin.latitude + (dest.latitude - origin.latitude) * t + jitterLat,
        origin.longitude + (dest.longitude - origin.longitude) * t,
      ));
    }
    return points;
  }

  List<CrimeIncident> _generateMockCrimesAlongRoute(
      List<LatLng> points, int count, math.Random rng) {
    final categories = [
      ('violent-crime', 'high'),
      ('robbery', 'high'),
      ('burglary', 'medium'),
      ('theft-from-the-person', 'medium'),
      ('anti-social-behaviour', 'low'),
      ('shoplifting', 'low'),
    ];

    final crimes = <CrimeIncident>[];
    for (int i = 0; i < count; i++) {
      final pt = points[rng.nextInt(points.length)];
      final cat = categories[rng.nextInt(categories.length)];
      crimes.add(CrimeIncident(
        id: 'mock_route_$i',
        latitude: pt.latitude + (rng.nextDouble() - 0.5) * 0.003,
        longitude: pt.longitude + (rng.nextDouble() - 0.5) * 0.003,
        category: cat.$1,
        severity: cat.$2,
        date: DateTime.now().subtract(Duration(days: rng.nextInt(60))),
        isMock: true,
      ));
    }
    return crimes;
  }

  // ────────────────────────────────────────────────────────
  // GEOCODING (address search → LatLng)
  // ────────────────────────────────────────────────────────

  Future<GeocodingResult?> geocodeAddress(String address) async {
    try {
      final key = ApiKeys.googleMapsApiKey;
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(address)}'
        '&key=$key',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body);
      if (data['status'] != 'OK' || (data['results'] as List).isEmpty) return null;
      final result = data['results'][0];
      final loc = result['geometry']['location'];
      return GeocodingResult(
        latLng: LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble()),
        formattedAddress: result['formatted_address'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> reverseGeocode(LatLng location) async {
    try {
      final key = ApiKeys.googleMapsApiKey;
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${location.latitude},${location.longitude}'
        '&key=$key',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return 'Unknown location';
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
        return data['results'][0]['formatted_address'] as String;
      }
    } catch (_) {}
    return 'Unknown location';
  }
}

// ────────────────────────────────────────────────────────
// RESULT TYPES
// ────────────────────────────────────────────────────────

class GeocodingResult {
  final LatLng latLng;
  final String formattedAddress;
  const GeocodingResult({required this.latLng, required this.formattedAddress});
}
