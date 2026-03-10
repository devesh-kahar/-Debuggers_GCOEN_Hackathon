import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/emergency_contact.dart';

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  bool _isRecording = false;
  String? _recordingPath;

  /// Trigger full emergency response
  Future<void> triggerEmergency({
    required List<EmergencyContact> contacts,
    required Position location,
    String reason = 'Emergency Alert',
  }) async {
    try {
      // Vibrate phone
      await _vibrate();

      // Send SMS to all emergency contacts
      await sendEmergencySMS(
        contacts: contacts,
        location: location,
        message: reason,
      );

      // Start recording audio
      await startRecording();

      // Share location
      await shareLocation(location);

      print('Emergency triggered successfully');
    } catch (e) {
      print('Error triggering emergency: $e');
    }
  }

  /// Send emergency SMS to contacts
  Future<void> sendEmergencySMS({
    required List<EmergencyContact> contacts,
    required Position location,
    String message = 'Emergency Alert',
  }) async {
    final locationUrl = 'https://www.google.com/maps?q=${location.latitude},${location.longitude}';
    final smsBody = Uri.encodeComponent(
      '🚨 EMERGENCY ALERT 🚨\n\n'
      '$message\n\n'
      'My location: $locationUrl\n\n'
      'Sent from SafeGuard App',
    );

    for (final contact in contacts) {
      try {
        final uri = Uri.parse('sms:${contact.phoneNumber}?body=$smsBody');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } catch (e) {
        print('Error sending SMS to ${contact.name}: $e');
      }
    }
  }

  /// Call emergency contact
  Future<void> callContact(String phoneNumber) async {
    try {
      final uri = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      print('Error calling contact: $e');
    }
  }

  /// Call emergency services (911, 112, etc.)
  Future<void> callEmergencyServices({String number = '911'}) async {
    try {
      final uri = Uri.parse('tel:$number');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      print('Error calling emergency services: $e');
    }
  }

  /// Share current location
  Future<void> shareLocation(Position location) async {
    try {
      final locationUrl = 'https://www.google.com/maps?q=${location.latitude},${location.longitude}';
      await Share.share(
        '📍 My current location:\n$locationUrl\n\nShared from SafeGuard App',
        subject: 'My Location',
      );
    } catch (e) {
      print('Error sharing location: $e');
    }
  }

  /// Start audio recording (simplified - just marks as recording)
  Future<void> startRecording() async {
    try {
      if (_isRecording) return;
      
      // TODO: Implement actual recording when package is fixed
      _isRecording = true;
      print('Recording started (placeholder)');
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  /// Stop audio recording
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;
      
      _isRecording = false;
      print('Recording stopped (placeholder)');
      return null;
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  /// Vibrate phone
  Future<void> _vibrate() async {
    try {
      await HapticFeedback.vibrate();
      // For longer vibration, you might need a plugin like vibration
    } catch (e) {
      print('Error vibrating: $e');
    }
  }

  /// Get emergency number based on country
  String getEmergencyNumber(String countryCode) {
    final emergencyNumbers = {
      'US': '911',
      'GB': '999',
      'IN': '112',
      'AU': '000',
      'CA': '911',
      'EU': '112',
    };
    return emergencyNumbers[countryCode] ?? '112';
  }

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Get recording path
  String? get recordingPath => _recordingPath;

  /// Dispose resources
  void dispose() {
    // Cleanup if needed
  }
}
