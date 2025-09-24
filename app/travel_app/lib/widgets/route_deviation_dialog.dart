import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/trip_route.dart';

class RouteDeviationDialog extends StatelessWidget {
  final RouteDeviation deviation;
  final VoidCallback onDismiss;
  final VoidCallback onAcknowledge;

  const RouteDeviationDialog({
    super.key,
    required this.deviation,
    required this.onDismiss,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getDeviationColor().withOpacity(0.1),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Alert icon and title
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getDeviationColor().withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_rounded,
                size: 40,
                color: _getDeviationColor(),
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              'Route Deviation Detected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getDeviationColor(),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            Text(
              _getDeviationMessage(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Deviation details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    icon: Icons.straighten,
                    label: 'Distance from route',
                    value: '${deviation.deviationDistance.toStringAsFixed(0)} meters',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.access_time,
                    label: 'Detected at',
                    value: _formatTime(deviation.detectedAt),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.priority_high,
                    label: 'Severity',
                    value: deviation.type.name.toUpperCase(),
                    valueColor: _getDeviationColor(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Emergency call button (for major/critical deviations)
            if (_shouldShowEmergencyButton()) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _callEmergencyServices,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.phone),
                  label: const Text(
                    'Call Emergency Services',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onDismiss,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAcknowledge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "I'm Safe",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Additional safety message
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your location is being monitored for safety. If you need help, tap "Call Emergency Services".',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }

  Color _getDeviationColor() {
    switch (deviation.type) {
      case DeviationType.minor:
        return Colors.yellow[700]!;
      case DeviationType.moderate:
        return Colors.orange[700]!;
      case DeviationType.major:
        return Colors.red[700]!;
      case DeviationType.critical:
        return Colors.red[900]!;
    }
  }

  String _getDeviationMessage() {
    switch (deviation.type) {
      case DeviationType.minor:
        return 'You have slightly deviated from your planned route.';
      case DeviationType.moderate:
        return 'You are off your planned route. Please check your navigation.';
      case DeviationType.major:
        return 'You are significantly off your planned route. Are you safe?';
      case DeviationType.critical:
        return 'CRITICAL: You are very far from your planned route. Please contact emergency services if you need help.';
    }
  }

  bool _shouldShowEmergencyButton() {
    return deviation.type == DeviationType.major || 
           deviation.type == DeviationType.critical;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _callEmergencyServices() async {
    const phoneNumber = 'tel:112'; // European emergency number
    final uri = Uri.parse(phoneNumber);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback: show instructions
      // This would typically show a dialog with emergency numbers
    }
  }
}

/// Service to show route deviation alerts
class RouteDeviationAlertService {
  static OverlayEntry? _overlayEntry;
  static bool _isAlertShowing = false;

  static void showDeviationAlert({
    required BuildContext context,
    required RouteDeviation deviation,
    required VoidCallback onDismiss,
    required VoidCallback onAcknowledge,
  }) {
    if (_isAlertShowing) {
      return; // Don't show multiple alerts
    }

    _isAlertShowing = true;

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: RouteDeviationDialog(
            deviation: deviation,
            onDismiss: () {
              _dismissAlert();
              onDismiss();
            },
            onAcknowledge: () {
              _dismissAlert();
              onAcknowledge();
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void _dismissAlert() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isAlertShowing = false;
    }
  }

  static bool get isAlertShowing => _isAlertShowing;
}