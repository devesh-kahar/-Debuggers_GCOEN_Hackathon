import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class VoiceDetectionService {
  static final VoiceDetectionService _instance = VoiceDetectionService._internal();
  factory VoiceDetectionService() => _instance;
  VoiceDetectionService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  Timer? _restartTimer;
  String _lastRecognizedWords = '';

  // Default emergency keywords
  List<String> _emergencyKeywords = [
    'help',
    'help me',
    'emergency',
    'bachao',
  ];

  // Callbacks
  Function(String detectedKeyword)? onEmergencyDetected;
  Function(String text)? onSpeechResult;
  Function(bool listening)? onListeningStateChanged;
  Function(String error)? onError;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onSpeechError,
        debugLogging: false,
      );

      if (_isInitialized) {
        // Load saved keywords from SharedPreferences
        await _loadSavedKeywords();
        print('✅ Speech recognition initialized');
      } else {
        print('❌ Speech recognition not available on this device');
      }

      return _isInitialized;
    } catch (e) {
      print('❌ Error initializing speech recognition: $e');
      onError?.call('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  /// Start continuous listening for keywords
  Future<void> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Speech recognition not available');
        return;
      }
    }

    if (_isListening) return;

    try {
      _isListening = true;
      onListeningStateChanged?.call(true);
      await _startListeningSession();
      print('🎤 Voice detection started - listening for keywords...');
    } catch (e) {
      _isListening = false;
      onListeningStateChanged?.call(false);
      print('Error starting listening: $e');
      onError?.call('Failed to start listening: $e');
    }
  }

  /// Internal method to start a single listening session
  Future<void> _startListeningSession() async {
    if (!_isListening) return;

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
        ),
      );
    } catch (e) {
      print('Error in listening session: $e');
      // Try to restart after a brief delay
      _scheduleRestart();
    }
  }

  /// Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    final recognizedText = result.recognizedWords.toLowerCase().trim();

    if (recognizedText.isEmpty) return;
    if (recognizedText == _lastRecognizedWords) return;

    _lastRecognizedWords = recognizedText;
    onSpeechResult?.call(recognizedText);

    // Check for emergency keywords
    final detectedKeyword = _findEmergencyKeyword(recognizedText);
    if (detectedKeyword != null) {
      print('🚨 EMERGENCY KEYWORD DETECTED: "$detectedKeyword" in "$recognizedText"');
      onEmergencyDetected?.call(detectedKeyword);
    }
  }

  /// Find if any emergency keyword is present in the text
  String? _findEmergencyKeyword(String text) {
    for (final keyword in _emergencyKeywords) {
      if (text.contains(keyword.toLowerCase())) {
        return keyword;
      }
    }
    return null;
  }

  /// Handle status changes for auto-restart
  void _onStatus(String status) {
    print('🎤 Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      // Auto-restart if we should still be listening
      if (_isListening) {
        _scheduleRestart();
      }
    }
  }

  /// Handle speech errors
  void _onSpeechError(dynamic error) {
    print('🎤 Speech error: $error');
    // Auto-restart on non-fatal errors
    if (_isListening) {
      _scheduleRestart();
    }
  }

  /// Schedule a restart of the listening session
  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 500), () {
      if (_isListening) {
        _lastRecognizedWords = '';
        _startListeningSession();
      }
    });
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      _isListening = false;
      _restartTimer?.cancel();
      _restartTimer = null;
      await _speech.stop();
      onListeningStateChanged?.call(false);
      print('🎤 Voice detection stopped');
    } catch (e) {
      print('Error stopping listening: $e');
    }
  }

  /// Toggle listening
  Future<void> toggleListening() async {
    if (_isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  // ====================
  // KEYWORD MANAGEMENT
  // ====================

  /// Add a custom emergency keyword
  Future<void> addEmergencyKeyword(String keyword) async {
    final lower = keyword.toLowerCase().trim();
    if (lower.isNotEmpty && !_emergencyKeywords.contains(lower)) {
      _emergencyKeywords.add(lower);
      await _saveKeywords();
    }
  }

  /// Remove an emergency keyword
  Future<void> removeEmergencyKeyword(String keyword) async {
    _emergencyKeywords.remove(keyword.toLowerCase().trim());
    await _saveKeywords();
  }

  /// Update the entire keywords list
  Future<void> setEmergencyKeywords(List<String> keywords) async {
    _emergencyKeywords = keywords.map((k) => k.toLowerCase().trim()).toList();
    await _saveKeywords();
  }

  /// Get all emergency keywords
  List<String> get emergencyKeywords => List.unmodifiable(_emergencyKeywords);

  /// Save keywords to SharedPreferences
  Future<void> _saveKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emergency_keywords', jsonEncode(_emergencyKeywords));
    } catch (e) {
      print('Error saving keywords: $e');
    }
  }

  /// Load saved keywords from SharedPreferences
  Future<void> _loadSavedKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('emergency_keywords');
      if (saved != null) {
        final List<dynamic> decoded = jsonDecode(saved);
        _emergencyKeywords = decoded.cast<String>();
      }
    } catch (e) {
      print('Error loading saved keywords: $e');
    }
  }

  // ====================
  // STATE GETTERS
  // ====================

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  bool get isAvailable => _isInitialized;

  /// Dispose resources
  void dispose() {
    _restartTimer?.cancel();
    _isListening = false;
    _speech.stop();
  }
}
