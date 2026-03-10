import 'package:google_maps_flutter/google_maps_flutter.dart';

// ============================================================================
// CRIME INCIDENT MODEL
// ============================================================================
class CrimeIncident {
  final String id;
  final double latitude;
  final double longitude;
  final String category;
  final String? outcomeStatus;
  final DateTime date;
  final String? location;
  final String severity;

  CrimeIncident({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.outcomeStatus,
    required this.date,
    this.location,
    required this.severity,
  });

  factory CrimeIncident.fromUKPoliceJson(Map<String, dynamic> json) {
    return CrimeIncident(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      latitude: double.parse(json['location']['latitude']),
      longitude: double.parse(json['location']['longitude']),
      category: json['category'] ?? 'unknown',
      outcomeStatus: json['outcome_status']?['category'],
      date: DateTime.parse(json['month'] + '-01'),
      location: json['location']['street']['name'],
      severity: _calculateSeverity(json['category']),
    );
  }

  static String _calculateSeverity(String? category) {
    if (category == null) return 'low';
    final violent = ['violent-crime', 'robbery', 'assault', 'homicide'];
    final moderate = ['burglary', 'theft', 'vehicle-crime'];
    if (violent.any((v) => category.toLowerCase().contains(v))) return 'high';
    if (moderate.any((m) => category.toLowerCase().contains(m))) return 'medium';
    return 'low';
  }
}

// ============================================================================
// ROUTE SAFETY MODEL
// ============================================================================
class RouteSafety {
  final String routeId;
  final List<LatLng> polylinePoints;
  final double distanceMeters;
  final int durationSeconds;
  final SafetyScore safetyScore;
  final List<CrimeIncident> nearbyCrimes;
  final int streetLightCount;
  final String summary;

  RouteSafety({
    required this.routeId,
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.safetyScore,
    required this.nearbyCrimes,
    required this.streetLightCount,
    required this.summary,
  });

  String get distanceText {
    if (distanceMeters < 1000) return '${distanceMeters.toInt()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get durationText {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = (minutes / 60).floor();
    final remainingMinutes = minutes % 60;
    return '$hours h $remainingMinutes min';
  }

  bool get isRecommended => safetyScore.overall >= 70;
}

class SafetyScore {
  final double overall;
  final double lightingScore;
  final double crimeScore;
  final double timeScore;
  final double userReportScore;

  SafetyScore({
    required this.overall,
    required this.lightingScore,
    required this.crimeScore,
    required this.timeScore,
    required this.userReportScore,
  });

  String get safetyLevel {
    if (overall >= 80) return 'Very Safe';
    if (overall >= 60) return 'Safe';
    if (overall >= 40) return 'Moderate';
    if (overall >= 20) return 'Caution';
    return 'Unsafe';
  }

  factory SafetyScore.calculate({
    required int crimeCount,
    required int streetLightCount,
    required bool isNightTime,
    required int userReports,
    required double routeLength,
  }) {
    final crimeScore = (100 - (crimeCount * 10)).clamp(0, 100).toDouble();
    final lightsPerKm = (streetLightCount / (routeLength / 1000));
    final lightingScore = (lightsPerKm * 10).clamp(0, 100).toDouble();
    final timeScore = isNightTime ? 60.0 : 100.0;
    final userReportScore = (100 - (userReports * 5)).clamp(0, 100).toDouble();
    final overall = (crimeScore * 0.35 + lightingScore * 0.25 + timeScore * 0.25 + userReportScore * 0.15).clamp(0, 100);

    return SafetyScore(
      overall: overall,
      lightingScore: lightingScore,
      crimeScore: crimeScore,
      timeScore: timeScore,
      userReportScore: userReportScore,
    );
  }
}

// ============================================================================
// EMERGENCY CONTACT MODEL
// ============================================================================
class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final bool isPrimary;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phoneNumber': phoneNumber,
    'email': email,
    'isPrimary': isPrimary,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
    id: json['id'],
    name: json['name'],
    phoneNumber: json['phoneNumber'],
    email: json['email'],
    isPrimary: json['isPrimary'] ?? false,
  );
}

// ============================================================================
// LOCATION SHARE SESSION MODEL
// ============================================================================
class LocationShareSession {
  final String sessionId;
  final String userId;
  final String userName;
  final LatLng currentLocation;
  final LatLng? destination;
  final DateTime startTime;
  final DateTime expiryTime;
  final bool isActive;
  final String? shareLink;

  LocationShareSession({
    required this.sessionId,
    required this.userId,
    required this.userName,
    required this.currentLocation,
    this.destination,
    required this.startTime,
    required this.expiryTime,
    required this.isActive,
    this.shareLink,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'userId': userId,
    'userName': userName,
    'latitude': currentLocation.latitude,
    'longitude': currentLocation.longitude,
    'destinationLat': destination?.latitude,
    'destinationLng': destination?.longitude,
    'startTime': startTime.toIso8601String(),
    'expiryTime': expiryTime.toIso8601String(),
    'isActive': isActive,
    'shareLink': shareLink,
  };

  factory LocationShareSession.fromJson(Map<String, dynamic> json) => LocationShareSession(
    sessionId: json['sessionId'],
    userId: json['userId'],
    userName: json['userName'],
    currentLocation: LatLng(json['latitude'], json['longitude']),
    destination: json['destinationLat'] != null ? LatLng(json['destinationLat'], json['destinationLng']) : null,
    startTime: DateTime.parse(json['startTime']),
    expiryTime: DateTime.parse(json['expiryTime']),
    isActive: json['isActive'],
    shareLink: json['shareLink'],
  );
}

// ============================================================================
// PRIVACY BREACH MODEL
// ============================================================================
class PrivacyBreach {
  final String source;
  final String title;
  final String description;
  final String url;
  final String severity;
  final DateTime? breachDate;
  final List<String> dataTypes;

  PrivacyBreach({
    required this.source,
    required this.title,
    required this.description,
    required this.url,
    required this.severity,
    this.breachDate,
    required this.dataTypes,
  });

  factory PrivacyBreach.fromHIBP(Map<String, dynamic> json) => PrivacyBreach(
    source: 'Have I Been Pwned',
    title: json['Title'] ?? json['Name'],
    description: json['Description'] ?? 'Data breach detected',
    url: json['Domain'] ?? '',
    severity: _calculateBreachSeverity(json['DataClasses']),
    breachDate: json['BreachDate'] != null ? DateTime.parse(json['BreachDate']) : null,
    dataTypes: List<String>.from(json['DataClasses'] ?? []),
  );

  static String _calculateBreachSeverity(List<dynamic>? dataClasses) {
    if (dataClasses == null) return 'low';
    final sensitive = ['passwords', 'credit cards', 'social security', 'financial'];
    if (dataClasses.any((d) => sensitive.any((s) => d.toString().toLowerCase().contains(s)))) return 'high';
    return 'medium';
  }
}

// ============================================================================
// SAFETY REPORT MODEL (Community Reports)
// ============================================================================
class SafetyReport {
  final String id;
  final LatLng location;
  final String reportType;
  final String description;
  final String severity;
  final DateTime timestamp;
  final String userId;
  final int upvotes;
  final int downvotes;

  SafetyReport({
    required this.id,
    required this.location,
    required this.reportType,
    required this.description,
    required this.severity,
    required this.timestamp,
    required this.userId,
    this.upvotes = 0,
    this.downvotes = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'latitude': location.latitude,
    'longitude': location.longitude,
    'reportType': reportType,
    'description': description,
    'severity': severity,
    'timestamp': timestamp.toIso8601String(),
    'userId': userId,
    'upvotes': upvotes,
    'downvotes': downvotes,
  };

  factory SafetyReport.fromJson(Map<String, dynamic> json) => SafetyReport(
    id: json['id'],
    location: LatLng(json['latitude'], json['longitude']),
    reportType: json['reportType'],
    description: json['description'],
    severity: json['severity'],
    timestamp: DateTime.parse(json['timestamp']),
    userId: json['userId'],
    upvotes: json['upvotes'] ?? 0,
    downvotes: json['downvotes'] ?? 0,
  );
}
