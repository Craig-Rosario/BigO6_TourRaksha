import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip_route.dart';
import '../services/route_service.dart';
import '../widgets/custom_button.dart';

class RouteDisplayScreen extends StatefulWidget {
  const RouteDisplayScreen({super.key});

  @override
  State<RouteDisplayScreen> createState() => _RouteDisplayScreenState();
}

class _RouteDisplayScreenState extends State<RouteDisplayScreen> {
  MapController? _mapController;
  bool _isTrackingStarted = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Route'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showRouteDetails,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Consumer<RouteService>(
        builder: (context, routeService, child) {
          final route = routeService.currentRoute;
          
          if (route == null) {
            return const Center(
              child: Text('No route available'),
            );
          }

          return Column(
            children: [
              // Route summary card
              _buildRouteSummaryCard(route),
              
              // Map
              Expanded(
                child: _buildRouteMap(route, routeService),
              ),
              
              // Control buttons
              _buildControlButtons(routeService, route),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRouteSummaryCard(TripRoute route) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.route,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Route Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: '${route.totalDistance.toStringAsFixed(1)} km',
                ),
                _buildSummaryItem(
                  icon: Icons.access_time,
                  label: 'Duration',
                  value: _formatDuration(route.estimatedDuration),
                ),
                _buildSummaryItem(
                  icon: Icons.place,
                  label: 'Stops',
                  value: '${route.waypoints.length}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteMap(TripRoute route, RouteService routeService) {
    // Calculate bounds for the route
    final bounds = _calculateRouteBounds(route);
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: bounds.center,
        initialZoom: 12,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // Tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.tourraksha.app',
        ),
        
        // Route polyline
        PolylineLayer(
          polylines: [
            Polyline(
              points: route.routePolyline,
              strokeWidth: 4.0,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
        
        // Waypoint markers
        MarkerLayer(
          markers: route.waypoints.map((waypoint) {
            return Marker(
              point: waypoint.location,
              child: _buildWaypointMarker(waypoint),
            );
          }).toList(),
        ),
        
        // Deviation alerts
        if (routeService.getUnacknowledgedDeviations().isNotEmpty)
          MarkerLayer(
            markers: routeService.getUnacknowledgedDeviations().map((deviation) {
              return Marker(
                point: deviation.currentLocation,
                child: _buildDeviationMarker(deviation),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildWaypointMarker(RouteWaypoint waypoint) {
    Color markerColor;
    IconData markerIcon;
    
    switch (waypoint.type) {
      case WaypointType.start:
        markerColor = Colors.green;
        markerIcon = Icons.play_arrow;
        break;
      case WaypointType.destination:
        markerColor = Colors.red;
        markerIcon = Icons.flag;
        break;
      case WaypointType.stopover:
        markerColor = Colors.orange;
        markerIcon = Icons.stop_circle;
        break;
      case WaypointType.poi:
        markerColor = Colors.blue;
        markerIcon = Icons.place;
        break;
      case WaypointType.emergency:
        markerColor = Colors.red;
        markerIcon = Icons.local_hospital;
        break;
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: markerColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        markerIcon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildDeviationMarker(RouteDeviation deviation) {
    Color alertColor;
    switch (deviation.type) {
      case DeviationType.moderate:
        alertColor = Colors.yellow;
        break;
      case DeviationType.major:
        alertColor = Colors.orange;
        break;
      case DeviationType.critical:
        alertColor = Colors.red;
        break;
      default:
        alertColor = Colors.grey;
    }
    
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: alertColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(
        Icons.warning,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildControlButtons(RouteService routeService, TripRoute route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isTrackingStarted) ...[
            CustomButton(
              text: 'Start Route Tracking',
              onPressed: () => _startRouteTracking(routeService),
              backgroundColor: Colors.green,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Stop Tracking',
                    onPressed: () => _stopRouteTracking(routeService),
                    backgroundColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'View Waypoints',
                    onPressed: _showWaypointsList,
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
          
          // Show deviation alerts
          Consumer<RouteService>(
            builder: (context, routeService, child) {
              final unacknowledgedDeviations = routeService.getUnacknowledgedDeviations();
              if (unacknowledgedDeviations.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${unacknowledgedDeviations.length} route deviation(s) detected',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _showDeviationAlerts,
                        child: const Text('View'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  void _startRouteTracking(RouteService routeService) async {
    try {
      await routeService.startRouteTracking();
      setState(() {
        _isTrackingStarted = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route tracking started'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start tracking: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopRouteTracking(RouteService routeService) {
    routeService.stopRouteTracking();
    setState(() {
      _isTrackingStarted = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Route tracking stopped'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showRouteDetails() {
    final routeService = context.read<RouteService>();
    final route = routeService.currentRoute;
    
    if (route == null) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('Trip ID: ${route.tripId}'),
            Text('Total Distance: ${route.totalDistance.toStringAsFixed(2)} km'),
            Text('Estimated Duration: ${_formatDuration(route.estimatedDuration)}'),
            Text('Waypoints: ${route.waypoints.length}'),
            Text('Created: ${route.createdAt.toString().split('.')[0]}'),
          ],
        ),
      ),
    );
  }

  void _showWaypointsList() {
    final routeService = context.read<RouteService>();
    final route = routeService.currentRoute;
    
    if (route == null) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Waypoints',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: route.waypoints.length,
                itemBuilder: (context, index) {
                  final waypoint = route.waypoints[index];
                  return ListTile(
                    leading: _buildWaypointMarker(waypoint),
                    title: Text(waypoint.name),
                    subtitle: waypoint.description != null
                        ? Text(waypoint.description!)
                        : null,
                    trailing: waypoint.isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeviationAlerts() {
    final routeService = context.read<RouteService>();
    final deviations = routeService.getUnacknowledgedDeviations();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route Deviation Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: deviations.map((deviation) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: _getDeviationColor(deviation.type),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          deviation.type.name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getDeviationColor(deviation.type),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Distance from route: ${deviation.deviationDistance.toStringAsFixed(0)}m'),
                    Text('Detected: ${deviation.detectedAt.toString().split('.')[0]}'),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Dismiss'),
          ),
          TextButton(
            onPressed: () {
              _callEmergencyNumber();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Call Emergency',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Acknowledge all deviations
              for (final deviation in deviations) {
                routeService.acknowledgeDeviation(deviation.id);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Acknowledge All'),
          ),
        ],
      ),
    );
  }

  void _callEmergencyNumber() {
    // In a real app, this would use url_launcher to call emergency services
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency services contacted'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Color _getDeviationColor(DeviationType type) {
    switch (type) {
      case DeviationType.minor:
        return Colors.grey;
      case DeviationType.moderate:
        return Colors.yellow;
      case DeviationType.major:
        return Colors.orange;
      case DeviationType.critical:
        return Colors.red;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  LatLngBounds _calculateRouteBounds(TripRoute route) {
    if (route.routePolyline.isEmpty) {
      return LatLngBounds(
        const LatLng(0, 0),
        const LatLng(0, 0),
      );
    }
    
    double minLat = route.routePolyline.first.latitude;
    double maxLat = route.routePolyline.first.latitude;
    double minLng = route.routePolyline.first.longitude;
    double maxLng = route.routePolyline.first.longitude;
    
    for (final point in route.routePolyline) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }
    
    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}