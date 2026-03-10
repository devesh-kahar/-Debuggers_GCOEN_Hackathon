import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────
// BACKGROUND ENTRY POINT
//
// MUST be a top-level function annotated with @pragma.
// Flutter's isolate runner calls this to start your task.
// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void startSosTaskCallback() {
  FlutterForegroundTask.setTaskHandler(SosTaskHandler());
}

// ─────────────────────────────────────────────────────────────
// TASK HANDLER — runs in background isolate
// ─────────────────────────────────────────────────────────────
class SosTaskHandler extends TaskHandler {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  Timer? _restartTimer;
  String _lastWords = '';
  List<String> _keywords = ['help', 'help me', 'emergency', 'bachao'];
  bool _emergencyTriggered = false; // prevent repeated triggers

  // ── Lifecycle ─────────────────────────────────────────────

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _loadKeywords();
    await _initSpeech();
    if (_isInitialized) _startListening();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Called every [intervalMs] — re-check that we're still listening
    if (_isInitialized && !_speech.isListening && _isListening) {
      _startListening();
    }
    // Reset the emergency lock every 3 minutes so user can re-trigger
    _emergencyTriggered = false;
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _restartTimer?.cancel();
    if (_speech.isListening) await _speech.stop();
  }

  // Handle commands sent from UI via FlutterForegroundTask.sendDataToTask()
  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      final cmd = data['cmd'] as String?;
      if (cmd == 'update_keywords') {
        final list = data['keywords'];
        if (list is List) {
          _keywords = list.cast<String>();
        }
      } else if (cmd == 'test_trigger') {
        _triggerEmergency('test');
      }
    }
  }

  // ── Speech ────────────────────────────────────────────────

  Future<void> _initSpeech() async {
    try {
      _isInitialized = await _speech.initialize(
        onStatus: _onStatus,
        onError: (_) => _scheduleRestart(),
        debugLogging: false,
      );
    } catch (_) {
      _isInitialized = false;
    }
  }

  void _startListening() {
    if (!_isInitialized) return;
    _isListening = true;

    _speech.listen(
      onResult: _onResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
      ),
    );
  }

  void _onStatus(String status) {
    if ((status == 'done' || status == 'notListening') && _isListening) {
      _scheduleRestart();
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.toLowerCase().trim();
    if (text.isEmpty || text == _lastWords) return;
    _lastWords = text;

    // Send live text to UI (so it can update the "heard" display)
    FlutterForegroundTask.sendDataToMain({'type': 'speech', 'text': text});

    // Check keywords
    for (final kw in _keywords) {
      if (text.contains(kw.toLowerCase())) {
        _triggerEmergency(kw);
        break;
      }
    }
  }

  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 600), () {
      _lastWords = '';
      _startListening();
    });
  }

  // ── Emergency call ────────────────────────────────────────

  Future<void> _triggerEmergency(String keyword) async {
    if (_emergencyTriggered) return;
    _emergencyTriggered = true;

    // Notify UI so it can show the countdown dialog
    FlutterForegroundTask.sendDataToMain({
      'type': 'emergency',
      'keyword': keyword,
    });

    // Update notification urgently
    FlutterForegroundTask.updateService(
      notificationTitle: '🚨 EMERGENCY DETECTED',
      notificationText: 'Keyword "$keyword" detected — calling now!',
    );

    // Wait 5 s for UI to possibly cancel before calling
    // UI sends 'cancel' command if user taps cancel
    await Future.delayed(const Duration(seconds: 5));

    if (!_emergencyTriggered) return; // UI cancelled

    // Fetch primary contact from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getString('emergency_contacts') ?? '[]';
    final contacts = jsonDecode(contactsJson) as List;

    String? phoneNumber;
    for (final c in contacts) {
      if (c['isPrimary'] == true) {
        phoneNumber = c['phoneNumber'] as String?;
        break;
      }
    }
    phoneNumber ??= '112';

    // Make the call
    try {
      await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    } catch (_) {
      final uri = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }

    // Reset notification back to normal
    FlutterForegroundTask.updateService(
      notificationTitle: '🛡️ SafeGuard Active',
      notificationText: 'Listening for emergency keywords…',
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Future<void> _loadKeywords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('emergency_keywords');
      if (saved != null) {
        final decoded = jsonDecode(saved) as List;
        _keywords = decoded.cast<String>();
      }
    } catch (_) {}
  }

  // Cancel the pending emergency call (called from UI)
  void cancelEmergency() {
    _emergencyTriggered = false;
    FlutterForegroundTask.updateService(
      notificationTitle: '🛡️ SafeGuard Active',
      notificationText: 'Listening for emergency keywords…',
    );
  }
}
