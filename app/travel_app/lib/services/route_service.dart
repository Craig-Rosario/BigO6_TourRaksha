import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip_route.dart';

class RouteService extends ChangeNotifier {
  TripRoute? _currentRoute;
  List<RouteDeviation> _deviations = [];
  bool _isTrackingRoute = false;
  Timer? _routeTrackingTimer;
  StreamSubscription<Position>? _positionStream;

  // Deviation thresholds in meters
  static const double _minorDeviationThreshold = 100.0; // 100m
  static const double _moderateDeviationThreshold = 500.0; // 500m
  static const double _majorDeviationThreshold = 1000.0; // 1km
  static const double _criticalDeviationThreshold = 5000.0; // 5km

  // Getters
  TripRoute? get currentRoute => _currentRoute;
  List<RouteDeviation> get deviations => _deviations;
  bool get isTrackingRoute => _isTrackingRoute;

  /// Generate route from waypoints using OpenRouteService
  Future<TripRoute?> generateRoute({
    required String tripId,
    required List<RouteWaypoint> waypoints,
  }) async {
    try {
      if (waypoints.length < 2) {
        throw Exception(
          'At least 2 waypoints are required to generate a route',
        );
      }

      // Sort waypoints by order
      waypoints.sort((a, b) => a.order.compareTo(b.order));

      // Prepare coordinates for API call
      List<List<double>> coordinates = waypoints
          .map((wp) => [wp.location.longitude, wp.location.latitude])
          .toList();

      // For demo purposes, we'll use a simple route calculation
      // In production, you would use the OpenRouteService API
      final routePolyline = await _calculateRoutePolyline(coordinates);
      final totalDistance = _calculateTotalDistance(routePolyline);
      final estimatedDuration = _calculateEstimatedDuration(totalDistance);

      final route = TripRoute(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tripId: tripId,
        waypoints: waypoints,
        routePolyline: routePolyline,
        totalDistance: totalDistance,
        estimatedDuration: estimatedDuration,
        createdAt: DateTime.now(),
      );

      _currentRoute = route;
      notifyListeners();

      return route;
    } catch (e) {
      debugPrint('Error generating route: $e');
      return null;
    }
  }

  /// Start tracking the current route for deviations
  Future<void> startRouteTracking() async {
    if (_currentRoute == null) {
      throw Exception('No active route to track');
    }

    _isTrackingRoute = true;
    notifyListeners();

    // Start location tracking
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
          ),
        ).listen((Position position) {
          _checkForRouteDeviation(
            LatLng(position.latitude, position.longitude),
          );
        });

    debugPrint('Route tracking started');
  }

  /// Stop route tracking
  void stopRouteTracking() {
    _isTrackingRoute = false;
    _positionStream?.cancel();
    _routeTrackingTimer?.cancel();
    notifyListeners();
    debugPrint('Route tracking stopped');
  }

  /// Check if current location deviates from planned route
  void _checkForRouteDeviation(LatLng currentLocation) {
    if (_currentRoute == null) return;

    final expectedLocation = _getExpectedLocationOnRoute(currentLocation);
    final deviationDistance = _calculateDistance(
      currentLocation,
      expectedLocation,
    );

    DeviationType? deviationType;

    if (deviationDistance > _criticalDeviationThreshold) {
      deviationType = DeviationType.critical;
    } else if (deviationDistance > _majorDeviationThreshold) {
      deviationType = DeviationType.major;
    } else if (deviationDistance > _moderateDeviationThreshold) {
      deviationType = DeviationType.moderate;
    } else if (deviationDistance > _minorDeviationThreshold) {
      deviationType = DeviationType.minor;
    }

    if (deviationType != null) {
      final deviation = RouteDeviation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tripId: _currentRoute!.tripId,
        currentLocation: currentLocation,
        expectedLocation: expectedLocation,
        deviationDistance: deviationDistance,
        detectedAt: DateTime.now(),
        type: deviationType,
      );

      _deviations.add(deviation);
      notifyListeners();

      // Trigger alert for moderate and above deviations
      if (deviationType.index >= DeviationType.moderate.index) {
        _triggerDeviationAlert(deviation);
      }
    }
  }

  /// Get the expected location on the route closest to current position
  LatLng _getExpectedLocationOnRoute(LatLng currentLocation) {
    if (_currentRoute == null || _currentRoute!.routePolyline.isEmpty) {
      return currentLocation;
    }

    double minDistance = double.infinity;
    LatLng closestPoint = _currentRoute!.routePolyline.first;

    for (final point in _currentRoute!.routePolyline) {
      final distance = _calculateDistance(currentLocation, point);
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = point;
      }
    }

    return closestPoint;
  }

  /// Trigger deviation alert
  void _triggerDeviationAlert(RouteDeviation deviation) {
    // This will be handled by the UI to show popup
    debugPrint(
      'Route deviation detected: ${deviation.type.name} - ${deviation.deviationDistance.toStringAsFixed(0)}m',
    );

    // Trigger notification for listeners
    notifyListeners();
  }

  /// Calculate route polyline (simplified version)
  Future<List<LatLng>> _calculateRoutePolyline(
    List<List<double>> coordinates,
  ) async {
    // In a real implementation, you would call the routing API here
    // For demo, we'll create a simple straight-line route between points
    List<LatLng> polyline = [];

    for (int i = 0; i < coordinates.length - 1; i++) {
      final start = LatLng(coordinates[i][1], coordinates[i][0]);
      final end = LatLng(coordinates[i + 1][1], coordinates[i + 1][0]);

      polyline.add(start);

      // Add intermediate points for a more realistic route
      const int intermediatePoints = 10;
      for (int j = 1; j < intermediatePoints; j++) {
        final ratio = j / intermediatePoints;
        final lat = start.latitude + (end.latitude - start.latitude) * ratio;
        final lng = start.longitude + (end.longitude - start.longitude) * ratio;
        polyline.add(LatLng(lat, lng));
      }
    }

    polyline.add(LatLng(coordinates.last[1], coordinates.last[0]));
    return polyline;
  }

  /// Calculate total distance of route
  double _calculateTotalDistance(List<LatLng> polyline) {
    double totalDistance = 0.0;
    for (int i = 0; i < polyline.length - 1; i++) {
      totalDistance += _calculateDistance(polyline[i], polyline[i + 1]);
    }
    return totalDistance / 1000; // Convert to kilometers
  }

  /// Calculate estimated duration based on distance
  Duration _calculateEstimatedDuration(double distanceKm) {
    // Assume average speed of 50 km/h
    const double averageSpeedKmh = 50.0;
    final hours = distanceKm / averageSpeedKmh;
    return Duration(minutes: (hours * 60).round());
  }

  /// Calculate distance between two points in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Acknowledge a deviation (mark as handled)
  void acknowledgeDeviation(String deviationId) {
    final index = _deviations.indexWhere((d) => d.id == deviationId);
    if (index != -1) {
      _deviations[index] = RouteDeviation(
        id: _deviations[index].id,
        tripId: _deviations[index].tripId,
        currentLocation: _deviations[index].currentLocation,
        expectedLocation: _deviations[index].expectedLocation,
        deviationDistance: _deviations[index].deviationDistance,
        detectedAt: _deviations[index].detectedAt,
        type: _deviations[index].type,
        isAcknowledged: true,
      );
      notifyListeners();
    }
  }

  /// Clear all acknowledged deviations
  void clearAcknowledgedDeviations() {
    _deviations.removeWhere((d) => d.isAcknowledged);
    notifyListeners();
  }

  /// Get unacknowledged deviations
  List<RouteDeviation> getUnacknowledgedDeviations() {
    return _deviations.where((d) => !d.isAcknowledged).toList();
  }

  /// Clear current route and stop tracking
  void clearRoute() {
    stopRouteTracking();
    _currentRoute = null;
    _deviations.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stopRouteTracking();
    super.dispose();
  }
}
