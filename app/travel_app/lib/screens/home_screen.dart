import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/tourist_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/safety_score_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/location_status_card.dart';
import '../widgets/digital_id_card.dart';
import '../widgets/route_deviation_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  void _initializeProviders() {
    final locationProvider = context.read<LocationProvider>();
    locationProvider.initializeLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer2<TouristProvider, LocationProvider>(
          builder: (context, touristProvider, locationProvider, child) {
            if (!touristProvider.isRegistered) {
              return _buildNotRegisteredView();
            }

            return RefreshIndicator(
              onRefresh: () async {
                await locationProvider.refreshLocation();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(touristProvider),
                    const SizedBox(height: 24),

                    // Route Deviation Banner
                    const RouteDeviationBanner(),

                    // Digital ID Card
                    const DigitalIdCard()
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideX(begin: -0.2, end: 0),
                    const SizedBox(height: 20),

                    // Safety Score Card
                    const SafetyScoreCard()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 200.ms)
                        .slideX(begin: 0.2, end: 0),
                    const SizedBox(height: 20),

                    // Location Status
                    const LocationStatusCard()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 400.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 20),

                    // Quick Actions
                    const QuickActionsGrid()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 20),

                    // Recent Alerts
                    if (touristProvider.activeAlerts.isNotEmpty)
                      _buildRecentAlerts(touristProvider)
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 800.ms)
                          .slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotRegisteredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.badge_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Digital ID Found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Please register to create your Digital Tourist ID and access safety features.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/registration'),
              icon: const Icon(Icons.person_add),
              label: const Text('Register Now'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TouristProvider touristProvider) {
    final profile = touristProvider.currentProfile!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (touristProvider.isTripActive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        'Trip Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        'Trip Starts Soon',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.go('/settings'),
          icon: const Icon(Icons.settings_outlined),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAlerts(TouristProvider touristProvider) {
    final alerts = touristProvider.activeAlerts.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Alerts',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => context.go('/alerts'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...alerts.map(
          (alert) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getAlertColor(
                  alert.priority,
                ).withOpacity(0.2),
                child: Icon(
                  _getAlertIcon(alert.type),
                  color: _getAlertColor(alert.priority),
                  size: 20,
                ),
              ),
              title: Text(
                alert.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                alert.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                _formatTime(alert.timestamp),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () => context.go('/alerts'),
            ),
          ),
        ),
      ],
    );
  }

  Color _getAlertColor(dynamic priority) {
    switch (priority.toString()) {
      case 'AlertPriority.critical':
        return Colors.red;
      case 'AlertPriority.high':
        return Colors.orange;
      case 'AlertPriority.medium':
        return Colors.yellow.shade700;
      case 'AlertPriority.low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertIcon(dynamic type) {
    switch (type.toString()) {
      case 'AlertType.sos':
        return Icons.emergency;
      case 'AlertType.geofence':
        return Icons.location_on;
      case 'AlertType.deviation':
        return Icons.route;
      case 'AlertType.inactivity':
        return Icons.access_time;
      default:
        return Icons.notification_important;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
