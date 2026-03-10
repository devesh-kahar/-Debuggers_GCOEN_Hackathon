/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'SafeGuard';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your AI-Powered Safety Companion';

  // Emergency Numbers by Country
  static const Map<String, String> emergencyNumbers = {
    'US': '911',
    'GB': '999',
    'IN': '112',
    'AU': '000',
    'CA': '911',
    'EU': '112',
    'JP': '110',
    'CN': '110',
  };

  // Safety Score Thresholds
  static const int safetyScoreExcellent = 80;
  static const int safetyScoreGood = 60;
  static const int safetyScoreFair = 40;
  static const int safetyScorePoor = 20;

  // Location Sharing Durations (in minutes)
  static const List<int> sharingDurations = [30, 60, 120, 240];

  // Voice Detection Keywords
  static const List<String> emergencyKeywords = [
    'help',
    'help me',
    'emergency',
    'stop',
    'police',
    'fire',
    'ambulance',
    'danger',
    'attack',
    'scared',
  ];

  // Crime Severity Levels
  static const String severityHigh = 'high';
  static const String severityMedium = 'medium';
  static const String severityLow = 'low';

  // Route Buffer Distance (meters)
  static const double routeBufferMeters = 500;

  // Location Update Interval (seconds)
  static const int locationUpdateInterval = 10;

  // Voice Detection Listening Duration (seconds)
  static const int voiceListeningDuration = 30;

  // Emergency Countdown Duration (seconds)
  static const int emergencyCountdown = 5;

  // Privacy Score Thresholds
  static const int privacyScoreExcellent = 80;
  static const int privacyScoreGood = 60;
  static const int privacyScoreFair = 40;

  // API Rate Limits
  static const int maxApiCallsPerMinute = 60;
  static const int maxCrimeDataPoints = 100;

  // Cache Duration (hours)
  static const int cacheExpiryHours = 24;

  // Map Settings
  static const double defaultMapZoom = 15.0;
  static const double defaultMapTilt = 0.0;
  static const double defaultMapBearing = 0.0;

  // Animation Durations (milliseconds)
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // Shared Preferences Keys
  static const String keyEmergencyContacts = 'emergency_contacts';
  static const String keyWalkingModeEnabled = 'walking_mode_enabled';
  static const String keyVoiceDetectionEnabled = 'voice_detection_enabled';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyLastScanDate = 'last_scan_date';
  static const String keyPrivacyScore = 'privacy_score';

  // Error Messages
  static const String errorLocationPermission = 'Location permission is required';
  static const String errorMicrophonePermission = 'Microphone permission is required';
  static const String errorNoInternet = 'No internet connection';
  static const String errorApiFailure = 'Failed to fetch data. Please try again.';
  static const String errorInvalidInput = 'Please enter valid information';

  // Success Messages
  static const String successEmergencyAlert = 'Emergency alert sent successfully';
  static const String successLocationShared = 'Location shared successfully';
  static const String successContactAdded = 'Emergency contact added';
  static const String successScanComplete = 'Privacy scan completed';
}

/// Safety Tips
class SafetyTips {
  static const List<String> tips = [
    'Always share your location when walking alone at night',
    'Trust your instincts - if something feels wrong, it probably is',
    'Stay in well-lit areas and avoid shortcuts through dark alleys',
    'Keep your phone charged and easily accessible',
    'Let someone know your route and expected arrival time',
    'Be aware of your surroundings and avoid distractions',
    'Walk confidently and purposefully',
    'If you feel threatened, head to a public place',
    'Keep emergency contacts updated in the app',
    'Use the fake call feature if you feel uncomfortable',
  ];

  static String getRandomTip() {
    return tips[(DateTime.now().millisecondsSinceEpoch % tips.length)];
  }
}

/// Privacy Tips
class PrivacyTips {
  static const List<String> tips = [
    'Use strong, unique passwords for each account',
    'Enable two-factor authentication wherever possible',
    'Review privacy settings on social media regularly',
    'Be cautious about sharing personal information online',
    'Use a password manager to keep track of credentials',
    'Regularly check for data breaches',
    'Limit the personal information you share publicly',
    'Use privacy-focused search engines and browsers',
    'Read privacy policies before signing up for services',
    'Opt out of data broker websites',
  ];

  static String getRandomTip() {
    return tips[(DateTime.now().millisecondsSinceEpoch % tips.length)];
  }
}
