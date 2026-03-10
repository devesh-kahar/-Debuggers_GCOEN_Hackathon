class PrivacyBreach {
  final String id;
  final String title;
  final String description;
  final String source;
  final String url;
  final DateTime? discoveredDate;
  final BreachSeverity severity;
  final BreachType type;
  final bool canRemove;

  PrivacyBreach({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    required this.url,
    this.discoveredDate,
    required this.severity,
    required this.type,
    this.canRemove = true,
  });

  factory PrivacyBreach.fromHIBPJson(Map<String, dynamic> json) {
    return PrivacyBreach(
      id: json['Name'],
      title: json['Title'] ?? json['Name'],
      description: json['Description'] ?? 'Data breach detected',
      source: json['Domain'] ?? 'Unknown',
      url: json['Domain'] ?? '',
      discoveredDate: json['BreachDate'] != null 
          ? DateTime.parse(json['BreachDate']) 
          : null,
      severity: _calculateSeverity(json['PwnCount']),
      type: BreachType.dataBreach,
      canRemove: false,
    );
  }

  factory PrivacyBreach.fromSearchResult(Map<String, dynamic> json) {
    return PrivacyBreach(
      id: json['link'],
      title: json['title'],
      description: json['snippet'] ?? '',
      source: _extractDomain(json['link']),
      url: json['link'],
      discoveredDate: DateTime.now(),
      severity: BreachSeverity.medium,
      type: BreachType.publicInfo,
      canRemove: true,
    );
  }

  static BreachSeverity _calculateSeverity(int? pwnCount) {
    if (pwnCount == null) return BreachSeverity.low;
    if (pwnCount > 1000000) return BreachSeverity.critical;
    if (pwnCount > 100000) return BreachSeverity.high;
    if (pwnCount > 10000) return BreachSeverity.medium;
    return BreachSeverity.low;
  }

  static String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return 'Unknown';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'source': source,
      'url': url,
      'discoveredDate': discoveredDate?.toIso8601String(),
      'severity': severity.toString(),
      'type': type.toString(),
      'canRemove': canRemove,
    };
  }
}

enum BreachSeverity {
  low,
  medium,
  high,
  critical,
}

enum BreachType {
  dataBreach,
  publicInfo,
  socialMedia,
  dataBroker,
  imageSearch,
}

extension BreachSeverityExtension on BreachSeverity {
  String get label {
    switch (this) {
      case BreachSeverity.low:
        return 'Low Risk';
      case BreachSeverity.medium:
        return 'Medium Risk';
      case BreachSeverity.high:
        return 'High Risk';
      case BreachSeverity.critical:
        return 'Critical';
    }
  }

  String get emoji {
    switch (this) {
      case BreachSeverity.low:
        return '🟢';
      case BreachSeverity.medium:
        return '🟡';
      case BreachSeverity.high:
        return '🟠';
      case BreachSeverity.critical:
        return '🔴';
    }
  }
}

extension BreachTypeExtension on BreachType {
  String get label {
    switch (this) {
      case BreachType.dataBreach:
        return 'Data Breach';
      case BreachType.publicInfo:
        return 'Public Information';
      case BreachType.socialMedia:
        return 'Social Media';
      case BreachType.dataBroker:
        return 'Data Broker';
      case BreachType.imageSearch:
        return 'Image Found';
    }
  }
}
