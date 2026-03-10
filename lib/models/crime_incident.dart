class CrimeIncident {
  final String id;
  final double latitude;
  final double longitude;
  final String category;
  final String? outcomeStatus;
  final DateTime date;
  final String? location;
  final String severity; // 'low', 'medium', 'high'
  final bool isMock;

  CrimeIncident({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.outcomeStatus,
    required this.date,
    this.location,
    required this.severity,
    this.isMock = false,
  });

  factory CrimeIncident.fromUKPoliceJson(Map<String, dynamic> json) {
    return CrimeIncident(
      id: json['id']?.toString() ?? '',
      latitude: double.tryParse(json['location']['latitude'].toString()) ?? 0,
      longitude: double.tryParse(json['location']['longitude'].toString()) ?? 0,
      category: json['category'] ?? 'unknown',
      outcomeStatus: json['outcome_status']?['category'],
      date: DateTime.tryParse((json['month'] ?? '2024-01') + '-01') ?? DateTime.now(),
      location: json['location']?['street']?['name'],
      severity: _calculateSeverity(json['category']),
    );
  }

  factory CrimeIncident.fromCrimeometerJson(Map<String, dynamic> json) {
    return CrimeIncident(
      id: json['incident_id']?.toString() ?? '',
      latitude: (json['incident_latitude'] as num).toDouble(),
      longitude: (json['incident_longitude'] as num).toDouble(),
      category: json['incident_offense'] ?? 'unknown',
      outcomeStatus: null,
      date: DateTime.tryParse(json['incident_date'] ?? '') ?? DateTime.now(),
      location: json['incident_address'],
      severity: _calculateSeverity(json['incident_offense']),
    );
  }

  static String _calculateSeverity(String? category) {
    if (category == null) return 'low';
    final cat = category.toLowerCase();
    const violent = ['violent-crime', 'robbery', 'assault', 'homicide', 'rape', 'weapon'];
    const moderate = ['burglary', 'theft', 'vehicle-crime', 'criminal-damage', 'arson', 'drugs'];
    if (violent.any((v) => cat.contains(v))) return 'high';
    if (moderate.any((m) => cat.contains(m))) return 'medium';
    return 'low';
  }

  /// Human-readable category label
  String get categoryLabel {
    return category
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
        'outcomeStatus': outcomeStatus,
        'date': date.toIso8601String(),
        'location': location,
        'severity': severity,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CrimeIncident && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
