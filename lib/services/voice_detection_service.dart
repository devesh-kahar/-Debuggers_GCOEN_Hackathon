class VoiceDetectionService {
  static final VoiceDetectionService _instance = VoiceDetectionService._internal();
  factory VoiceDetectionService() => _instance;
  VoiceDetectionService._internal();

  bool _isListening = false;
  bool _isInitialized = false;

  // Emergency keywords to detect
  final List<String> _emergencyKeywords = [
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

  Function(String)? onEmergencyDetected;
  Function(String)? onSpeechResult;

  /// Initialize speech recognition (placeholder)
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // TODO: Implement when speech_to_text package is fixed
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing speech recognition: $e');
      return false;
    }
  }

  /// Start listening for emergency keywords (placeholder)
  Future<void> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (_isListening) return;

    try {
      // TODO: Implement actual voice detection when package is fixed
      _isListening = true;
      print('Voice detection started (placeholder)');
    } catch (e) {
      print('Error starting listening: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      _isListening = false;
      print('Voice detection stopped');
    } catch (e) {
      print('Error stopping listening: $e');
    }
  }

  /// Check if text contains emergency keywords
  bool _containsEmergencyKeyword(String text) {
    return _emergencyKeywords.any((keyword) => text.contains(keyword));
  }

  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return true; // Placeholder
  }

  /// Add custom emergency keyword
  void addEmergencyKeyword(String keyword) {
    if (!_emergencyKeywords.contains(keyword.toLowerCase())) {
      _emergencyKeywords.add(keyword.toLowerCase());
    }
  }

  /// Remove emergency keyword
  void removeEmergencyKeyword(String keyword) {
    _emergencyKeywords.remove(keyword.toLowerCase());
  }

  /// Get all emergency keywords
  List<String> get emergencyKeywords => List.unmodifiable(_emergencyKeywords);

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _isListening = false;
  }
}
