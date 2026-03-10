import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationShare {
  final String id;
  final String userId;
  final String userName;
  final LatLng currentLocation;
  final LatLng? destination;
  final DateTime startTime;
  final DateTime expiryTime;
  final bool isActive;
  final String? destinationName;
  final int? estimatedArrivalMinutes;

  LocationShare({
    required this.id,
    required this.userId,
    required this.userName,
    required this.currentLocation,
    this.destination,
    required this.startTime,
    required this.expiryTime,
    required this.isActive,
    this.destinationName,
    this.estimatedArrivalMinutes,
  });

  factory LocationShare.fromJson(Map<String, dynamic> json) {
    return LocationShare(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      currentLocation: LatLng(
        json['currentLocation']['latitude'],
        json['currentLocation']['longitude'],
      ),
      destination: json['destination'] != null
          ? LatLng(
              json['destination']['latitude'],
              json['destination']['longitude'],
            )
          : null,
      startTime: DateTime.parse(json['startTime']),
      expiryTime: DateTime.parse(json['expiryTime']),
      isActive: json['isActive'],
      destinationName: json['destinationName'],
      estimatedArrivalMinutes: json['estimatedArrivalMinutes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'currentLocation': {
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
      },
      'destination': destination != null
          ? {
              'latitude': destination!.latitude,
              'longitude': destination!.longitude,
            }
          : null,
      'startTime': startTime.toIso8601String(),
      'expiryTime': expiryTime.toIso8601String(),
      'isActive': isActive,
      'destinationName': destinationName,
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiryTime);

  String get shareUrl => 'https://safeguard.app/track/$id';

  LocationShare copyWith({
    String? id,
    String? userId,
    String? userName,
    LatLng? currentLocation,
    LatLng? destination,
    DateTime? startTime,
    DateTime? expiryTime,
    bool? isActive,
    String? destinationName,
    int? estimatedArrivalMinutes,
  }) {
    return LocationShare(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      currentLocation: currentLocation ?? this.currentLocation,
      destination: destination ?? this.destination,
      startTime: startTime ?? this.startTime,
      expiryTime: expiryTime ?? this.expiryTime,
      isActive: isActive ?? this.isActive,
      destinationName: destinationName ?? this.destinationName,
      estimatedArrivalMinutes: estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
    );
  }
}
