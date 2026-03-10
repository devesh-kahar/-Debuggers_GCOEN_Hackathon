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

  // ================================================
  // MAIN FETCH: tries UK Police API, falls back to demo
  // ================================================

  /// Fetch crimes near a location. Tries UK Police API first,
  /// falls back to realistic mock data for demo/non-UK areas.
  Future<List<CrimeIncident>> fetchCrimesNear({
    required LatLng location,
    String? date,
  }) async {
    try {
      final crimes = await fetchUKPoliceCrimes(location: location, date: date);
      if (crimes.isNotEmpty) return crimes;
      // Fall through to mock if API returned empty
    } catch (_) {
      // Fall through to mock
    }
    return _generateMockCrimes(location);
  }

  /// Fetch crime data from UK Police API (No API key needed)
  Future<List<CrimeIncident>> fetchUKPoliceCrimes({
    required LatLng location,
    String? date,
  }) async {
    final dateParam = date ?? _getLastMonthDate();
    final url = Uri.parse(
      '${ApiEndpoints.ukPoliceCrimeBase}/crimes-street/all-crime'
      '?lat=${location.latitude}'
      '&lng=${location.longitude}'
      '&date=$dateParam',
    );

    final response = await http
        .get(url)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) => CrimeIncident.fromUKPoliceJson(json))
          .toList();
    } else {
      throw Exception('UK Police API: ${response.statusCode}');
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
        return incidents
            .map((json) => CrimeIncident.fromCrimeometerJson(json))
            .toList();
      }
    } catch (e) {
      print('Crimeometer error: $e');
    }
    return [];
  }

  // ================================================
  // SAFETY SCORE
  // ================================================

  /// Calculate a 0–100 safety score for a location based on crime count and severity.
  /// 100 = perfectly safe, 0 = very dangerous.
  AreaSafetyReport calculateSafetyScore(
    List<CrimeIncident> crimes,
    LatLng center,
  ) {
    if (crimes.isEmpty) {
      return AreaSafetyReport(
        score: 85,
        rating: 'Safe',
        color: SafetyColor.safe,
        crimeCount: 0,
        topCategory: 'None',
        breakdown: {},
      );
    }

    // Weight crimes by severity
    double weightedCrimeScore = 0;
    for (final c in crimes) {
      weightedCrimeScore += switch (c.severity) {
        'high' => 3.0,
        'medium' => 1.5,
        _ => 0.8,
      };
    }

    // Crime density penalty (per km²  radius ~1km → π km²)
    final crimeIndexPer100 = (weightedCrimeScore / 3.14) * 100;

    // Time of day factor (not dynamic in model, use neutral)
    const timeScore = 80.0;

    // Final score
    final rawScore = timeScore - (crimeIndexPer100 * 0.5).clamp(0, 75);
    final score = rawScore.clamp(5, 100).toInt();

    // Category breakdown
    final Map<String, int> breakdown = {};
    for (final c in crimes) {
      final cat = _formatCategory(c.category);
      breakdown[cat] = (breakdown[cat] ?? 0) + 1;
    }
    final topCategory = breakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    SafetyColor color;
    String rating;
    if (score >= 70) {
      color = SafetyColor.safe;
      rating = 'Safe';
    } else if (score >= 45) {
      color = SafetyColor.moderate;
      rating = 'Moderate Risk';
    } else {
      color = SafetyColor.danger;
      rating = 'High Risk';
    }

    return AreaSafetyReport(
      score: score,
      rating: rating,
      color: color,
      crimeCount: crimes.length,
      topCategory: topCategory,
      breakdown: breakdown,
    );
  }

  // ================================================
  // MOCK DATA (for demo / non-UK areas)
  // ================================================

  List<CrimeIncident> _generateMockCrimes(LatLng center) {
    final rng = math.Random(
      (center.latitude * 1000).toInt() + (center.longitude * 1000).toInt(),
    );

    final categories = [
      ('violent-crime', 'high'),
      ('robbery', 'high'),
      ('burglary', 'medium'),
      ('theft-from-the-person', 'medium'),
      ('vehicle-crime', 'medium'),
      ('anti-social-behaviour', 'low'),
      ('shoplifting', 'low'),
      ('drugs', 'low'),
      ('criminal-damage-arson', 'medium'),
      ('other-crime', 'low'),
    ];

    final count = 8 + rng.nextInt(22); // 8–30 crimes
    final List<CrimeIncident> incidents = [];

    for (int i = 0; i < count; i++) {
      // Random offset within ~1 km
      final latOffset = (rng.nextDouble() - 0.5) * 0.018;
      final lngOffset = (rng.nextDouble() - 0.5) * 0.022;
      final cat = categories[rng.nextInt(categories.length)];

      final daysAgo = rng.nextInt(90);
      final date = DateTime.now().subtract(Duration(days: daysAgo));

      incidents.add(CrimeIncident(
        id: 'mock_${i}_${date.millisecondsSinceEpoch}',
        latitude: center.latitude + latOffset,
        longitude: center.longitude + lngOffset,
        category: cat.$1,
        date: date,
        severity: cat.$2,
        location: _randomStreetName(rng),
        outcomeStatus: rng.nextBool() ? 'Under investigation' : 'No further action',
        isMock: true,
      ));
    }

    return incidents;
  }

  String _randomStreetName(math.Random rng) {
    final prefixes = ['Main', 'High', 'Church', 'Park', 'Station', 'Mill', 'King', 'Queen'];
    final suffixes = ['Street', 'Road', 'Avenue', 'Lane', 'Way', 'Close'];
    return '${prefixes[rng.nextInt(prefixes.length)]} ${suffixes[rng.nextInt(suffixes.length)]}';
  }

  // ================================================
  // ROUTE ANALYSIS
  // ================================================

  Future<List<CrimeIncident>> getCrimesAlongRoute({
    required List<LatLng> routePoints,
    double bufferMeters = 500,
  }) async {
    final Set<String> seenIds = {};
    final List<CrimeIncident> allCrimes = [];
    final samplePoints = _sampleRoutePoints(routePoints, maxPoints: 5);

    for (final point in samplePoints) {
      final crimes = await fetchCrimesNear(location: point);
      for (final crime in crimes) {
        if (seenIds.contains(crime.id)) continue;
        final dist = _calculateDistance(
          point.latitude, point.longitude,
          crime.latitude, crime.longitude,
        );
        if (dist <= bufferMeters) {
          seenIds.add(crime.id);
          allCrimes.add(crime);
        }
      }
    }
    return allCrimes;
  }

  List<LatLng> _sampleRoutePoints(List<LatLng> points, {int maxPoints = 5}) {
    if (points.length <= maxPoints) return points;
    final sampledPoints = <LatLng>[];
    final step = points.length / maxPoints;
    for (int i = 0; i < maxPoints; i++) {
      sampledPoints.add(points[(i * step).floor()]);
    }
    return sampledPoints;
  }

  // ================================================
  // HELPERS
  // ================================================

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.asin(math.sqrt(a));
  }

  double _toRad(double d) => d * math.pi / 180;

  String _getLastMonthDate() {
    final now = DateTime.now();
    final last = DateTime(now.year, now.month - 1);
    return '${last.year}-${last.month.toString().padLeft(2, '0')}';
  }

  String _getCurrentDate() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}'
        'T${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  String _getDateDaysAgo(int days) {
    final d = DateTime.now().subtract(Duration(days: days));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T00:00:00';
  }

  static String _formatCategory(String raw) {
    return raw
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String formatCategory(String raw) => _formatCategory(raw);
}

// ================================================
// DATA MODELS
// ================================================

enum SafetyColor { safe, moderate, danger }

class AreaSafetyReport {
  final int score;          // 0–100
  final String rating;      // 'Safe', 'Moderate Risk', 'High Risk'
  final SafetyColor color;
  final int crimeCount;
  final String topCategory;
  final Map<String, int> breakdown;

  const AreaSafetyReport({
    required this.score,
    required this.rating,
    required this.color,
    required this.crimeCount,
    required this.topCategory,
    required this.breakdown,
  });
}
