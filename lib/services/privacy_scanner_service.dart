import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/privacy_breach.dart';
import '../config/api_keys.dart';

class PrivacyScannerService {
  static final PrivacyScannerService _instance = PrivacyScannerService._internal();
  factory PrivacyScannerService() => _instance;
  PrivacyScannerService._internal();

  /// Scan for data breaches using Have I Been Pwned API
  Future<List<PrivacyBreach>> checkDataBreaches(String email) async {
    try {
      final url = Uri.parse('${ApiEndpoints.hibpBase}/breachedaccount/$email');
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'SafeGuard-App',
          if (ApiKeys.haveibeenpwnedApiKey.isNotEmpty)
            'hibp-api-key': ApiKeys.haveibeenpwnedApiKey,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PrivacyBreach.fromHIBPJson(json)).toList();
      } else if (response.statusCode == 404) {
        // No breaches found
        return [];
      } else {
        throw Exception('Failed to check breaches: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking data breaches: $e');
      return [];
    }
  }

  /// Search for personal information using Google Custom Search
  Future<List<PrivacyBreach>> searchPersonalInfo({
    required String name,
    String? email,
    String? phone,
  }) async {
    try {
      final query = _buildSearchQuery(name: name, email: email, phone: phone);
      final url = Uri.parse(
        '${ApiEndpoints.googleCustomSearch}'
        '?key=${ApiKeys.googleCustomSearchApiKey}'
        '&cx=${ApiKeys.googleCustomSearchEngineId}'
        '&q=$query'
        '&num=10',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];
        
        return items.map((item) {
          return PrivacyBreach.fromSearchResult({
            'title': item['title'],
            'snippet': item['snippet'],
            'link': item['link'],
          });
        }).toList();
      } else {
        throw Exception('Failed to search: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching personal info: $e');
      return [];
    }
  }

  /// Comprehensive privacy scan
  Future<Map<String, dynamic>> performFullScan({
    required String name,
    required String email,
    String? phone,
  }) async {
    final results = <String, dynamic>{};
    
    // Check data breaches
    final breaches = await checkDataBreaches(email);
    results['breaches'] = breaches;

    // Search for personal information
    final publicInfo = await searchPersonalInfo(
      name: name,
      email: email,
      phone: phone,
    );
    results['publicInfo'] = publicInfo;

    // Calculate privacy score
    final privacyScore = _calculatePrivacyScore(
      breachCount: breaches.length,
      publicInfoCount: publicInfo.length,
    );
    results['privacyScore'] = privacyScore;

    // Generate recommendations
    final recommendations = _generateRecommendations(
      breaches: breaches,
      publicInfo: publicInfo,
    );
    results['recommendations'] = recommendations;

    return results;
  }

  /// Build search query for personal information
  String _buildSearchQuery({
    required String name,
    String? email,
    String? phone,
  }) {
    final parts = <String>[name];
    if (email != null && email.isNotEmpty) parts.add(email);
    if (phone != null && phone.isNotEmpty) parts.add(phone);
    return Uri.encodeComponent(parts.join(' '));
  }

  /// Calculate privacy score (0-100)
  int _calculatePrivacyScore({
    required int breachCount,
    required int publicInfoCount,
  }) {
    int score = 100;

    // Deduct points for breaches
    score -= (breachCount * 15).clamp(0, 50);

    // Deduct points for public information
    score -= (publicInfoCount * 5).clamp(0, 30);

    return score.clamp(0, 100);
  }

  /// Generate privacy recommendations
  List<String> _generateRecommendations({
    required List<PrivacyBreach> breaches,
    required List<PrivacyBreach> publicInfo,
  }) {
    final recommendations = <String>[];

    if (breaches.isNotEmpty) {
      recommendations.add('Change passwords for affected accounts immediately');
      recommendations.add('Enable two-factor authentication on all accounts');
      recommendations.add('Monitor your credit report for suspicious activity');
    }

    if (publicInfo.isNotEmpty) {
      recommendations.add('Request removal of personal information from websites');
      recommendations.add('Review and update privacy settings on social media');
      recommendations.add('Use privacy-focused search engines');
    }

    if (breaches.isEmpty && publicInfo.isEmpty) {
      recommendations.add('Great! Keep monitoring your digital footprint regularly');
      recommendations.add('Use strong, unique passwords for each account');
      recommendations.add('Be cautious about sharing personal information online');
    }

    return recommendations;
  }

  /// Get list of data broker websites
  List<Map<String, String>> getDataBrokerList() {
    return [
      {
        'name': 'Spokeo',
        'url': 'https://www.spokeo.com/optout',
        'description': 'People search engine',
      },
      {
        'name': 'WhitePages',
        'url': 'https://www.whitepages.com/suppression-requests',
        'description': 'Phone and address directory',
      },
      {
        'name': 'BeenVerified',
        'url': 'https://www.beenverified.com/app/optout/search',
        'description': 'Background check service',
      },
      {
        'name': 'PeopleFinder',
        'url': 'https://www.peoplefinder.com/opt-out',
        'description': 'Public records search',
      },
      {
        'name': 'Intelius',
        'url': 'https://www.intelius.com/opt-out',
        'description': 'Background reports',
      },
    ];
  }

  /// Generate removal request email template
  String generateRemovalRequest({
    required String siteName,
    required String name,
    required String email,
  }) {
    return '''
Subject: Request to Remove Personal Information

Dear $siteName Team,

I am writing to request the removal of my personal information from your database in accordance with privacy regulations (GDPR/CCPA).

Name: $name
Email: $email

Please confirm the removal of all my personal data from your systems within 30 days as required by law.

Thank you for your prompt attention to this matter.

Best regards,
$name
''';
  }
}
