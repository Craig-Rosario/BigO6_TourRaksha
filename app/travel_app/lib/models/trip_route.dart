import 'package:latlong2/latlong.dart';

class TripRoute {
  final String id;
  final String tripId;
  final List<RouteWaypoint> waypoints;
  final List<LatLng> routePolyline;
  final double totalDistance; // in kilometers
  final Duration estimatedDuration;
  final DateTime createdAt;
  final bool isActive;

  const TripRoute({
    required this.id,
    required this.tripId,
    required this.waypoints,
    required this.routePolyline,
    required this.totalDistance,
    required this.estimatedDuration,
    required this.createdAt,
    this.isActive = true,
  });

  factory TripRoute.fromJson(Map<String, dynamic> json) {
    return TripRoute(
      id: json['id'],
      tripId: json['tripId'],
      waypoints: (json['waypoints'] as List)
          .map((w) => RouteWaypoint.fromJson(w))
          .toList(),
      routePolyline: (json['routePolyline'] as List)
          .map((point) => LatLng(point['lat'], point['lng']))
          .toList(),
      totalDistance: json['totalDistance']?.toDouble() ?? 0.0,
      estimatedDuration: Duration(
        seconds: json['estimatedDurationSeconds'] ?? 0,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'waypoints': waypoints.map((w) => w.toJson()).toList(),
      'routePolyline': routePolyline
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
      'totalDistance': totalDistance,
      'estimatedDurationSeconds': estimatedDuration.inSeconds,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class RouteWaypoint {
  final String id;
  final String name;
  final String? description;
  final LatLng location;
  final DateTime? estimatedArrivalTime;
  final DateTime? actualArrivalTime;
  final bool isCompleted;
  final WaypointType type;
  final int order;

  const RouteWaypoint({
    required this.id,
    required this.name,
    this.description,
    required this.location,
    this.estimatedArrivalTime,
    this.actualArrivalTime,
    this.isCompleted = false,
    this.type = WaypointType.destination,
    required this.order,
  });

  factory RouteWaypoint.fromJson(Map<String, dynamic> json) {
    return RouteWaypoint(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: LatLng(json['latitude'], json['longitude']),
      estimatedArrivalTime: json['estimatedArrivalTime'] != null
          ? DateTime.parse(json['estimatedArrivalTime'])
          : null,
      actualArrivalTime: json['actualArrivalTime'] != null
          ? DateTime.parse(json['actualArrivalTime'])
          : null,
      isCompleted: json['isCompleted'] ?? false,
      type: WaypointType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WaypointType.destination,
      ),
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'estimatedArrivalTime': estimatedArrivalTime?.toIso8601String(),
      'actualArrivalTime': actualArrivalTime?.toIso8601String(),
      'isCompleted': isCompleted,
      'type': type.name,
      'order': order,
    };
  }

  RouteWaypoint copyWith({
    String? id,
    String? name,
    String? description,
    LatLng? location,
    DateTime? estimatedArrivalTime,
    DateTime? actualArrivalTime,
    bool? isCompleted,
    WaypointType? type,
    int? order,
  }) {
    return RouteWaypoint(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      estimatedArrivalTime: estimatedArrivalTime ?? this.estimatedArrivalTime,
      actualArrivalTime: actualArrivalTime ?? this.actualArrivalTime,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
      order: order ?? this.order,
    );
  }
}

enum WaypointType {
  start,
  destination,
  stopover,
  poi, // Point of Interest
  emergency,
}

class RouteDeviation {
  final String id;
  final String tripId;
  final LatLng currentLocation;
  final LatLng expectedLocation;
  final double deviationDistance; // in meters
  final DateTime detectedAt;
  final DeviationType type;
  final bool isAcknowledged;

  const RouteDeviation({
    required this.id,
    required this.tripId,
    required this.currentLocation,
    required this.expectedLocation,
    required this.deviationDistance,
    required this.detectedAt,
    required this.type,
    this.isAcknowledged = false,
  });

  factory RouteDeviation.fromJson(Map<String, dynamic> json) {
    return RouteDeviation(
      id: json['id'],
      tripId: json['tripId'],
      currentLocation: LatLng(json['currentLat'], json['currentLng']),
      expectedLocation: LatLng(json['expectedLat'], json['expectedLng']),
      deviationDistance: json['deviationDistance']?.toDouble() ?? 0.0,
      detectedAt: DateTime.parse(json['detectedAt']),
      type: DeviationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DeviationType.minor,
      ),
      isAcknowledged: json['isAcknowledged'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'currentLat': currentLocation.latitude,
      'currentLng': currentLocation.longitude,
      'expectedLat': expectedLocation.latitude,
      'expectedLng': expectedLocation.longitude,
      'deviationDistance': deviationDistance,
      'detectedAt': detectedAt.toIso8601String(),
      'type': type.name,
      'isAcknowledged': isAcknowledged,
    };
  }
}

enum DeviationType {
  minor, // Within acceptable range but noted
  moderate, // Significant deviation, show alert
  major, // Large deviation, urgent alert
  critical, // Emergency-level deviation
}
