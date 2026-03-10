class CrimeIncident {
  final String id;
  final double latitude;
  final double longitude;
  final String category;
  final String? outcomeStatus;
  final DateTime date;
  final String? location;
  final String severity; // 'low', 'medium', 'high'

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
      id: json['id']?.toString() ?? '',
      latitude: double.parse(json['location']['latitude']),
      longitude: double.parse(json['location']['longitude']),
      category: json['category'] ?? 'unknown',
      outcomeStatus: json['outcome_status']?['category'],
      date: DateTime.parse(json['month'] + '-01'),
      location: json['location']['street']['name'],
      severity: _calculateSeverity(json['category']),
    );
  }

  factory CrimeIncident.fromCrimeometerJson(Map<String, dynamic> json) {
    return CrimeIncident(
      id: json['incident_id']?.toString() ?? '',
      latitude: json['incident_latitude'],
      longitude: json['incident_longitude'],
      category: json['incident_offense'] ?? 'unknown',
      outcomeStatus: null,
      date: DateTime.parse(json['incident_date']),
      location: json['incident_address'],
      severity: _calculateSeverity(json['incident_offense']),
    );
  }

  static String _calculateSeverity(String? category) {
    if (category == null) return 'low';
    
    final violent = ['violent-crime', 'robbery', 'assault', 'homicide'];
    final moderate = ['burglary', 'theft', 'vehicle-crime'];
    
    if (violent.any((v) => category.toLowerCase().contains(v))) {
      return 'high';
    } else if (moderate.any((m) => category.toLowerCase().contains(m))) {
      return 'medium';
    }
    return 'low';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'outcomeStatus': outcomeStatus,
      'date': date.toIso8601String(),
      'location': location,
      'severity': severity,
    };
  }
}
