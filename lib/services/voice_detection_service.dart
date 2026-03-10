import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceDetectionService {
  static final VoiceDetectionService _instance = VoiceDetectionService._internal();
  factory VoiceDetectionService() => _instance;
  VoiceDetectionService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
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

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      print('Error initializing speech recognition: $e');
      return false;
    }
  }

  /// Start listening for emergency keywords
  Future<void> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (_isListening) return;

    try {
      await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords.toLowerCase();
          onSpeechResult?.call(text);

          // Check for emergency keywords
          if (_containsEmergencyKeyword(text)) {
            onEmergencyDetected?.call(text);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      );

      _isListening = true;
    } catch (e) {
      print('Error starting listening: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
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
    return _speech.isAvailable;
  }

  /// Get available locales
  Future<List<stt.LocaleName>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speech.locales();
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
    _speech.stop();
    _speech.cancel();
  }
}
