import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/location_provider.dart';
import '../providers/tourist_provider.dart';
import '../services/location_coordinates_service.dart';
import '../services/route_service.dart';
import '../utils/theme.dart';
import '../widgets/sos_timer_dialog.dart';
import '../widgets/location_feedback_dialog.dart';
import '../widgets/route_deviation_dialog.dart';
import '../screens/family_members_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  MapController? _mapController;
  bool _isTracking = false;
  LatLng? _tappedLocation; // For user-tapped pinpoint

  // Animation controllers for markers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // Default center point (can be changed to any location you prefer)
  static const LatLng _defaultCenter = LatLng(
    28.6139,
    77.2090,
  ); // New Delhi, India
  static const double _initialZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _pulseController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
      _setupRouteDeviationListener();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _initializeLocation() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    await locationProvider.initializeLocation();
    if (locationProvider.currentLocation != null && mounted) {
      _moveToCurrentLocation();
      _bounceController.reset();
      _bounceController.forward();
    }
  }

  void _moveToCurrentLocation() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    if (locationProvider.currentLocation != null && _mapController != null) {
      final location = locationProvider.currentLocation!;
      _mapController!.move(
        LatLng(location.latitude, location.longitude),
        _initialZoom,
      );
    }
  }

  void _setupRouteDeviationListener() {
    final routeService = Provider.of<RouteService>(context, listen: false);
    
    // Listen for route deviations
    routeService.addListener(() {
      if (!mounted) return;
      
      final unacknowledgedDeviations = routeService.getUnacknowledgedDeviations();
      
      for (final deviation in unacknowledgedDeviations) {
        if (deviation.type.index >= 1 && !RouteDeviationAlertService.isAlertShowing) { // moderate and above
          RouteDeviationAlertService.showDeviationAlert(
            context: context,
            deviation: deviation,
            onDismiss: () {
              // Just dismiss the alert
            },
            onAcknowledge: () {
              routeService.acknowledgeDeviation(deviation.id);
            },
          );
          break; // Show only one alert at a time
        }
      }
    });
  }

  void _toggleTracking() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    setState(() {
      _isTracking = !_isTracking;
    });

    if (_isTracking) {
      locationProvider.startLiveTracking();
    } else {
      locationProvider.stopLiveTracking();
    }
  }

  Color _getSafetyColor(double score) {
    if (score >= 80) return AppColors.safeTone;
    if (score >= 60) return AppColors.cautionTone;
    return AppColors.dangerTone;
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _tappedLocation = point;
    });
    _bounceController.reset();
    _bounceController.forward();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Map'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleTracking,
            tooltip: _isTracking ? 'Stop Tracking' : 'Start Tracking',
          ),
        ],
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          if (locationProvider.hasPermission == false) {
            return _buildLocationErrorView(locationProvider);
          }

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: locationProvider.currentLocation != null
                          ? LatLng(
                              locationProvider.currentLocation!.latitude,
                              locationProvider.currentLocation!.longitude,
                            )
                          : _defaultCenter,
                      initialZoom: _initialZoom,
                      minZoom: 5.0,
                      maxZoom: 19.0,
                      cameraConstraint: CameraConstraint.unconstrained(),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onTap: (tapPosition, point) {
                        _onMapTap(point);
                      },
                    ),
                    children: [
                      // Simple OpenStreetMap tile layer
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.travel_app',
                        maxZoom: 19,
                        subdomains: const ['a', 'b', 'c'],
                        errorTileCallback: (tile, error, stackTrace) {
                          debugPrint('Tile loading error: $error');
                        },
                        tileProvider: NetworkTileProvider(),
                      ),
                      MarkerLayer(markers: _buildMarkers(locationProvider)),
                    ],
                  ),
                ),
              ),

              // Safety score card
              if (locationProvider.currentSafetyScore != null)
                Positioned(
                  top: 16,
                  left: 16,
                  child: _buildSafetyScoreCard(
                    locationProvider.currentSafetyScore!,
                  ),
                ),

              // Location info card
              if (locationProvider.currentLocation != null)
                Positioned(
                  bottom: 100,
                  left: 16,
                  right: 16,
                  child: _buildLocationInfoCard(
                    locationProvider.currentLocation!,
                  ),
                ),

              // Tapped location info
              if (_tappedLocation != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildTappedLocationCard(_tappedLocation!),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<TouristProvider>(
        builder: (context, touristProvider, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Family Members button
              FloatingActionButton(
                heroTag: "family_members",
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FamilyMembersScreen(),
                  ),
                ),
                child: const Icon(Icons.family_restroom),
                tooltip: 'Family Members',
                backgroundColor: AppColors.primary,
              ),
              const SizedBox(height: 16),
              // Feedback button
              if (_tappedLocation != null)
                FloatingActionButton(
                  heroTag: "feedback",
                  onPressed: () => _showFeedbackDialog(_tappedLocation!),
                  child: const Icon(Icons.rate_review),
                  tooltip: 'Give Feedback',
                  backgroundColor: AppColors.cautionTone,
                ),
              if (_tappedLocation != null) const SizedBox(height: 16),
              // SOS button with timer
              FloatingActionButton(
                heroTag: "sos",
                onPressed: touristProvider.sosTimerActive ? null : _triggerSOS,
                child: touristProvider.sosTimerActive
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Icon(Icons.emergency),
                tooltip: touristProvider.sosTimerActive
                    ? 'SOS Timer Active'
                    : 'Emergency SOS',
                backgroundColor: touristProvider.sosTimerActive
                    ? Colors.grey
                    : AppColors.dangerTone,
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: "planned_locations",
                onPressed: _showAllPlannedLocations,
                child: const Icon(Icons.map),
                tooltip: 'Show Planned Locations',
                backgroundColor: const Color(0xFF2196F3),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: "clear_pin",
                onPressed: () {
                  setState(() {
                    _tappedLocation = null;
                  });
                },
                child: const Icon(Icons.clear),
                tooltip: 'Clear Pin',
                backgroundColor: AppColors.cautionTone,
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: "location",
                onPressed: _moveToCurrentLocation,
                child: const Icon(Icons.my_location),
                tooltip: 'My Location',
                backgroundColor: AppColors.primaryAccent,
              ),
            ],
          );
        },
      ),
    );
  }

  List<Marker> _buildMarkers(LocationProvider locationProvider) {
    List<Marker> markers = [];

    // Get planned locations from tourist profile
    final touristProvider = Provider.of<TouristProvider>(
      context,
      listen: false,
    );
    final plannedLocationMarkers = touristProvider.currentProfile != null
        ? LocationCoordinatesService.getPlannedLocationMarkers(
            touristProvider.currentProfile!.plannedLocations,
          )
        : <PlannedLocationMarker>[];

    // Planned location markers
    for (final plannedLocation in plannedLocationMarkers) {
      markers.add(
        Marker(
          point: plannedLocation.coordinates,
          width: 100,
          height: 120,
          child: GestureDetector(
            onTap: () {
              _showPlannedLocationDialog(plannedLocation);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Order number badge
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${plannedLocation.order}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Pin marker
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF2196F3,
                    ), // Blue color for planned locations
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.place, color: Colors.white, size: 20),
                ),
                // Location name (abbreviated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _abbreviateLocationName(plannedLocation.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Current location marker with animation
    if (locationProvider.currentLocation != null) {
      markers.add(
        Marker(
          point: LatLng(
            locationProvider.currentLocation!.latitude,
            locationProvider.currentLocation!.longitude,
          ),
          width: 120,
          height: 120,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _bounceAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _bounceAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryAccent.withOpacity(0.5),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryAccent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    // Tapped location marker
    if (_tappedLocation != null) {
      markers.add(
        Marker(
          point: _tappedLocation!,
          width: 80,
          height: 80,
          child: AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _bounceAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cautionTone,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // Geofence markers
    for (final geofence in locationProvider.geofences) {
      double safetyLevel = geofence.isRestrictedZone ? 20.0 : 80.0;

      markers.add(
        Marker(
          point: LatLng(geofence.centerLatitude, geofence.centerLongitude),
          width: 60,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              color: _getSafetyColor(safetyLevel),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              geofence.isRestrictedZone ? Icons.warning : Icons.info,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildSafetyScoreCard(dynamic safetyScore) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.security,
              color: _getSafetyColor(safetyScore.score.toDouble()),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text('Safety Score', style: Theme.of(context).textTheme.titleSmall),
            Text(
              '${safetyScore.score}%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _getSafetyColor(safetyScore.score.toDouble()),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfoCard(dynamic location) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Current Location',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${location.latitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Lng: ${location.longitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Accuracy: ${location.accuracy.toStringAsFixed(1)}m',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTappedLocationCard(LatLng location) {
    return Card(
      color: AppColors.cautionTone,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_pin, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pinned Location',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${location.latitude.toStringAsFixed(6)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
            Text(
              'Lng: ${location.longitude.toStringAsFixed(6)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationErrorView(LocationProvider locationProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: AppColors.dangerTone),
          const SizedBox(height: 16),
          Text(
            'Location Permission Required',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Please grant location permission to use the map',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => locationProvider.initializeLocation(),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  // Helper method to abbreviate location names for display
  String _abbreviateLocationName(String locationName) {
    if (locationName.length <= 12) return locationName;

    // Extract key part of the location name
    final parts = locationName.split(',');
    if (parts.isNotEmpty) {
      String mainPart = parts[0].trim();
      if (mainPart.length > 12) {
        return '${mainPart.substring(0, 9)}...';
      }
      return mainPart;
    }

    return '${locationName.substring(0, 9)}...';
  }

  // Show dialog with planned location details
  void _showPlannedLocationDialog(PlannedLocationMarker plannedLocation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '${plannedLocation.order}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Planned Location',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place, color: Color(0xFF2196F3)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plannedLocation.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Lat: ${plannedLocation.coordinates.latitude.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Lng: ${plannedLocation.coordinates.longitude.toStringAsFixed(4)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is location #${plannedLocation.order} in your planned itinerary.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _moveToLocation(plannedLocation.coordinates);
            },
            child: const Text('Go to Location'),
          ),
        ],
      ),
    );
  }

  // Helper method to move map to a specific location
  void _moveToLocation(LatLng location) {
    if (_mapController != null) {
      _mapController!.move(location, 15.0);
    }
  }

  // Show all planned locations on the map
  void _showAllPlannedLocations() {
    final touristProvider = Provider.of<TouristProvider>(
      context,
      listen: false,
    );
    if (touristProvider.currentProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No planned locations found')),
      );
      return;
    }

    final plannedLocationMarkers =
        LocationCoordinatesService.getPlannedLocationMarkers(
          touristProvider.currentProfile!.plannedLocations,
        );

    if (plannedLocationMarkers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No planned locations with coordinates found'),
        ),
      );
      return;
    }

    // Get all coordinates
    final coordinates = plannedLocationMarkers
        .map((m) => m.coordinates)
        .toList();

    // Calculate center and zoom
    final center = LocationCoordinatesService.getCenterPoint(coordinates);
    final zoom = LocationCoordinatesService.getAppropriateZoom(coordinates);

    // Move map to show all planned locations
    if (_mapController != null) {
      _mapController!.move(center, zoom);
    }

    // Show info about planned locations
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Showing ${plannedLocationMarkers.length} planned locations',
        ),
        action: SnackBarAction(
          label: 'List',
          onPressed: _showPlannedLocationsList,
        ),
      ),
    );
  }

  // Show list of all planned locations
  void _showPlannedLocationsList() {
    final touristProvider = Provider.of<TouristProvider>(
      context,
      listen: false,
    );
    if (touristProvider.currentProfile == null) return;

    final plannedLocationMarkers =
        LocationCoordinatesService.getPlannedLocationMarkers(
          touristProvider.currentProfile!.plannedLocations,
        );

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Planned Locations',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (plannedLocationMarkers.isEmpty)
              const Text('No locations with coordinates found')
            else
              ...plannedLocationMarkers
                  .map(
                    (marker) => ListTile(
                      leading: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${marker.order}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(marker.name),
                      subtitle: Text(
                        'Lat: ${marker.coordinates.latitude.toStringAsFixed(4)}, '
                        'Lng: ${marker.coordinates.longitude.toStringAsFixed(4)}',
                      ),
                      trailing: const Icon(Icons.place),
                      onTap: () {
                        Navigator.of(context).pop();
                        _moveToLocation(marker.coordinates);
                      },
                    ),
                  )
                  .toList(),
          ],
        ),
      ),
    );
  }

  // SOS functionality with timer
  void _triggerSOS() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    final touristProvider = Provider.of<TouristProvider>(
      context,
      listen: false,
    );

    if (locationProvider.currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available for SOS')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SOSTimerDialog(
        onTimeout: () {
          touristProvider.triggerSOS(
            latitude: locationProvider.currentLocation!.latitude,
            longitude: locationProvider.currentLocation!.longitude,
            customMessage: 'Emergency SOS triggered from mobile app',
          );

          // Also call emergency contact
          _callEmergencyContact(touristProvider);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'SOS sent to authorities and emergency contact called!',
              ),
              backgroundColor: AppColors.dangerTone,
            ),
          );
        },
        onDismiss: () {
          touristProvider.dismissSOS();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SOS dismissed'),
              backgroundColor: AppColors.safeTone,
            ),
          );
        },
      ),
    );
  }

  // Show feedback dialog for a location
  void _showFeedbackDialog(LatLng location) {
    showDialog(
      context: context,
      builder: (context) => LocationFeedbackDialog(
        latitude: location.latitude,
        longitude: location.longitude,
        locationName: 'Pinned Location',
      ),
    );
  }

  // Call emergency contact helper method
  Future<void> _callEmergencyContact(TouristProvider touristProvider) async {
    final profile = touristProvider.currentProfile;
    if (profile == null || profile.emergencyContactNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contact number available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final phoneNumber = profile.emergencyContactNumber;
    final cleanedNumber = phoneNumber.replaceAll(
      RegExp(r'[^\d+]'),
      '',
    ); // Remove non-digit characters except +

    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Calling ${profile.emergencyContact} at $phoneNumber',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to make phone call on this device'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error making phone call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
