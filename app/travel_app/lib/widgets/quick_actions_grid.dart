import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/tourist_provider.dart';
import '../providers/location_provider.dart';
import '../screens/family_members_screen.dart';
import '../screens/feedback_list_screen.dart';
import '../screens/trip_itinerary_screen.dart';
import '../widgets/sos_timer_dialog.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [
            _SOSButton(),
            _QuickActionCard(
              title: 'View Map',
              subtitle: 'Live location & zones',
              icon: Icons.map_outlined,
              color: Colors.blue,
              onTap: () => context.go('/map'),
            ),
            _QuickActionCard(
              title: 'Plan Route',
              subtitle: 'Create trip itinerary',
              icon: Icons.route_outlined,
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TripItineraryScreen(),
                ),
              ),
            ),
            _QuickActionCard(
              title: 'Family Members',
              subtitle: 'Manage family travel',
              icon: Icons.family_restroom,
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FamilyMembersScreen(),
                ),
              ),
            ),
            _QuickActionCard(
              title: 'My Feedbacks',
              subtitle: 'Location safety reviews',
              icon: Icons.rate_review,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeedbackListScreen(),
                ),
              ),
            ),
            _QuickActionCard(
              title: 'Settings',
              subtitle: 'App preferences',
              icon: Icons.settings_outlined,
              color: Colors.grey,
              onTap: () => context.go('/settings'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SOSButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<TouristProvider, LocationProvider>(
      builder: (context, touristProvider, locationProvider, child) {
        final sosActive = touristProvider.sosActive;
        final sosTimerActive = touristProvider.sosTimerActive;

        return GestureDetector(
          onTap: () =>
              _handleSOSPress(context, touristProvider, locationProvider),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: sosActive
                    ? [Colors.red.shade700, Colors.red.shade900]
                    : sosTimerActive
                    ? [Colors.orange.shade600, Colors.orange.shade800]
                    : [Colors.red, Colors.red.shade700],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color:
                      (sosActive
                              ? Colors.red
                              : sosTimerActive
                              ? Colors.orange
                              : Colors.red)
                          .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Pulse animation when SOS is active or timer is running
                if (sosActive || sosTimerActive) ...[
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sosActive ? Colors.red : Colors.orange,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        sosActive
                            ? Icons.emergency
                            : sosTimerActive
                            ? Icons.timer
                            : Icons.emergency_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        sosActive
                            ? 'SOS ACTIVE'
                            : sosTimerActive
                            ? 'SOS TIMER'
                            : 'Emergency SOS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sosActive
                            ? 'Help is on the way'
                            : sosTimerActive
                            ? 'Timer running...'
                            : 'Tap for emergency',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSOSPress(
    BuildContext context,
    TouristProvider touristProvider,
    LocationProvider locationProvider,
  ) async {
    if (touristProvider.sosActive) {
      // Show resolve SOS dialog
      _showResolveSOSDialog(context, touristProvider);
      return;
    }

    if (touristProvider.sosTimerActive) {
      // SOS timer already active, show dismiss option
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('SOS Timer Active'),
          content: const Text(
            'SOS timer is already running. Do you want to dismiss it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                touristProvider.dismissSOS();
                Navigator.pop(context);
              },
              child: const Text('Dismiss SOS'),
            ),
          ],
        ),
      );
      return;
    }

    // Trigger haptic feedback
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      // Haptic feedback not supported on this device
    }

    final location = locationProvider.currentLocation;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available for SOS')),
      );
      return;
    }

    // Show SOS timer dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SOSTimerDialog(
        onTimeout: () async {
          await touristProvider.triggerSOS(
            latitude: location.latitude,
            longitude: location.longitude,
            customMessage: 'Emergency SOS triggered from home screen',
          );

          // Also call emergency contact
          await _callEmergencyContact(context, touristProvider);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'SOS sent to authorities and emergency contact called!',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        onDismiss: () {
          touristProvider.dismissSOS();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('SOS dismissed'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _showResolveSOSDialog(
    BuildContext context,
    TouristProvider touristProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text('Resolve SOS'),
          ],
        ),
        content: const Text(
          'Are you safe now? This will mark the emergency as resolved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              touristProvider.resolveSOS('Tourist - Self Resolved');
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency resolved successfully!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Safe'),
          ),
        ],
      ),
    );
  }

  Future<void> _callEmergencyContact(
    BuildContext context,
    TouristProvider touristProvider,
  ) async {
    final profile = touristProvider.currentProfile;
    if (profile == null || profile.emergencyContactNumber.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No emergency contact number available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Calling ${profile.emergencyContact} at $phoneNumber',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to make phone call on this device'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making phone call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16), // Reduced from 20 to 16
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44, // Slightly reduced icon container size
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ), // Slightly reduced icon size
              ),
              const SizedBox(height: 10), // Reduced spacing
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ), // Changed from titleMedium to titleSmall
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2), // Reduced from 4 to 2
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
