import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  /// Request all required permissions at once
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.microphone,
      Permission.sms,
      Permission.phone,
      Permission.camera,
      Permission.contacts,
    ];

    return await permissions.request();
  }

  /// Check if all critical permissions are granted
  static Future<bool> hasAllCriticalPermissions() async {
    final location = await Permission.location.isGranted;
    final microphone = await Permission.microphone.isGranted;
    
    return location && microphone;
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Request SMS permission
  static Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Request phone permission
  static Future<bool> requestPhonePermission() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request contacts permission
  static Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// Open app settings
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Get permission status message
  static String getPermissionMessage(Permission permission, PermissionStatus status) {
    if (status.isGranted) {
      return '${_getPermissionName(permission)} permission granted';
    } else if (status.isDenied) {
      return '${_getPermissionName(permission)} permission denied';
    } else if (status.isPermanentlyDenied) {
      return '${_getPermissionName(permission)} permission permanently denied. Please enable in settings.';
    } else if (status.isRestricted) {
      return '${_getPermissionName(permission)} permission restricted';
    }
    return 'Unknown permission status';
  }

  static String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.location:
        return 'Location';
      case Permission.microphone:
        return 'Microphone';
      case Permission.sms:
        return 'SMS';
      case Permission.phone:
        return 'Phone';
      case Permission.camera:
        return 'Camera';
      case Permission.contacts:
        return 'Contacts';
      default:
        return 'Unknown';
    }
  }
}
