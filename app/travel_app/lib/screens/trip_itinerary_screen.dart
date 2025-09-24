import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip_route.dart';
import '../services/route_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/tour_raksha_logo.dart';
import 'route_display_screen.dart';

class TripItineraryScreen extends StatefulWidget {
  const TripItineraryScreen({super.key});

  @override
  State<TripItineraryScreen> createState() => _TripItineraryScreenState();
}

class _TripItineraryScreenState extends State<TripItineraryScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<WaypointFormData> _waypoints = [
    WaypointFormData(order: 0, type: WaypointType.start),
    WaypointFormData(order: 1, type: WaypointType.destination),
  ];
  
  bool _isGeneratingRoute = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Your Trip'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const TourRakshaLogo(size: 80, showText: false),
                  const SizedBox(height: 16),
                  const Text(
                    'Create Your Journey',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add destinations to plan your route',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Waypoints list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _waypoints.length + 1,
                itemBuilder: (context, index) {
                  if (index == _waypoints.length) {
                    return _buildAddWaypointButton();
                  }
                  return _buildWaypointCard(index);
                },
              ),
            ),

            // Generate route button
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CustomButton(
                    text: _isGeneratingRoute ? 'Generating Route...' : 'Generate Route',
                    onPressed: _isGeneratingRoute ? null : _generateRoute,
                    isLoading: _isGeneratingRoute,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Make sure to add at least 2 destinations',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaypointCard(int index) {
    final waypoint = _waypoints[index];
    final isFirst = index == 0;
    final isLast = index == _waypoints.length - 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and delete button
            Row(
              children: [
                Icon(
                  _getWaypointIcon(waypoint.type),
                  color: _getWaypointColor(waypoint.type),
                ),
                const SizedBox(width: 8),
                Text(
                  _getWaypointTitle(waypoint.type, index),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (!isFirst && !isLast)
                  IconButton(
                    onPressed: () => _removeWaypoint(index),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Name input
            TextFormField(
              controller: waypoint.nameController,
              decoration: InputDecoration(
                labelText: 'Location Name',
                hintText: isFirst ? 'Starting point' : 'Destination',
                prefixIcon: const Icon(Icons.place),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Location name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Coordinates input
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: waypoint.latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      prefixIcon: Icon(Icons.my_location),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^-?[0-9]*\.?[0-9]*'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Latitude required';
                      }
                      final lat = double.tryParse(value);
                      if (lat == null || lat < -90 || lat > 90) {
                        return 'Invalid latitude';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: waypoint.longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^-?[0-9]*\.?[0-9]*'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Longitude required';
                      }
                      final lng = double.tryParse(value);
                      if (lng == null || lng < -180 || lng > 180) {
                        return 'Invalid longitude';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            // Description input (optional)
            const SizedBox(height: 12),
            TextFormField(
              controller: waypoint.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add notes about this location',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              maxLines: 2,
            ),

            // Type selector (for non-start/end waypoints)
            if (!isFirst && !isLast) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<WaypointType>(
                value: waypoint.type,
                decoration: const InputDecoration(
                  labelText: 'Waypoint Type',
                  prefixIcon: Icon(Icons.flag),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: [
                  WaypointType.destination,
                  WaypointType.stopover,
                  WaypointType.poi,
                ].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getWaypointTypeDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      waypoint.type = value;
                    });
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddWaypointButton() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _addWaypoint,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.add_location_alt,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                'Add Another Stop',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addWaypoint() {
    setState(() {
      _waypoints.insert(
        _waypoints.length - 1, // Insert before the last waypoint (destination)
        WaypointFormData(
          order: _waypoints.length - 1,
          type: WaypointType.stopover,
        ),
      );
      // Update orders
      for (int i = 0; i < _waypoints.length; i++) {
        _waypoints[i].order = i;
      }
    });
  }

  void _removeWaypoint(int index) {
    setState(() {
      _waypoints[index].dispose();
      _waypoints.removeAt(index);
      // Update orders
      for (int i = 0; i < _waypoints.length; i++) {
        _waypoints[i].order = i;
      }
    });
  }

  Future<void> _generateRoute() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isGeneratingRoute = true;
    });

    try {
      // Convert form data to waypoints
      final List<RouteWaypoint> routeWaypoints = _waypoints.map((formData) {
        return RouteWaypoint(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + formData.order.toString(),
          name: formData.nameController.text.trim(),
          description: formData.descriptionController.text.trim().isEmpty
              ? null
              : formData.descriptionController.text.trim(),
          location: LatLng(
            double.parse(formData.latitudeController.text),
            double.parse(formData.longitudeController.text),
          ),
          type: formData.type,
          order: formData.order,
        );
      }).toList();

      // Generate route using route service
      final routeService = context.read<RouteService>();
      final tripId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final route = await routeService.generateRoute(
        tripId: tripId,
        waypoints: routeWaypoints,
      );

      if (route != null) {
        // Navigate to route display screen
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const RouteDisplayScreen(),
            ),
          );
        }
      } else {
        _showErrorSnackBar('Failed to generate route. Please check your waypoints.');
      }
    } catch (e) {
      _showErrorSnackBar('Error generating route: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingRoute = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  IconData _getWaypointIcon(WaypointType type) {
    switch (type) {
      case WaypointType.start:
        return Icons.play_arrow;
      case WaypointType.destination:
        return Icons.flag;
      case WaypointType.stopover:
        return Icons.stop_circle;
      case WaypointType.poi:
        return Icons.place;
      case WaypointType.emergency:
        return Icons.local_hospital;
    }
  }

  Color _getWaypointColor(WaypointType type) {
    switch (type) {
      case WaypointType.start:
        return Colors.green;
      case WaypointType.destination:
        return Colors.red;
      case WaypointType.stopover:
        return Colors.orange;
      case WaypointType.poi:
        return Colors.blue;
      case WaypointType.emergency:
        return Colors.red;
    }
  }

  String _getWaypointTitle(WaypointType type, int index) {
    switch (type) {
      case WaypointType.start:
        return 'Starting Point';
      case WaypointType.destination:
        return 'Final Destination';
      case WaypointType.stopover:
        return 'Stop ${index}';
      case WaypointType.poi:
        return 'Point of Interest ${index}';
      case WaypointType.emergency:
        return 'Emergency Point ${index}';
    }
  }

  String _getWaypointTypeDisplayName(WaypointType type) {
    switch (type) {
      case WaypointType.destination:
        return 'Destination';
      case WaypointType.stopover:
        return 'Stopover';
      case WaypointType.poi:
        return 'Point of Interest';
      case WaypointType.start:
        return 'Starting Point';
      case WaypointType.emergency:
        return 'Emergency Point';
    }
  }

  @override
  void dispose() {
    for (final waypoint in _waypoints) {
      waypoint.dispose();
    }
    super.dispose();
  }
}

class WaypointFormData {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  
  int order;
  WaypointType type;

  WaypointFormData({
    required this.order,
    required this.type,
  });

  void dispose() {
    nameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    descriptionController.dispose();
  }
}