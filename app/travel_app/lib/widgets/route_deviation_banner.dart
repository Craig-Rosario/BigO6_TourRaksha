import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/route_service.dart';
import '../models/trip_route.dart';
import 'route_deviation_dialog.dart';

class RouteDeviationBanner extends StatelessWidget {
  const RouteDeviationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteService>(
      builder: (context, routeService, child) {
        final unacknowledgedDeviations = routeService
            .getUnacknowledgedDeviations();

        if (unacknowledgedDeviations.isEmpty || !routeService.isTrackingRoute) {
          return const SizedBox.shrink();
        }

        // Get the most severe deviation
        final mostSevereDeviation = unacknowledgedDeviations.reduce(
          (a, b) => a.type.index > b.type.index ? a : b,
        );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getBackgroundColor(mostSevereDeviation.type),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _getAccentColor(
                  mostSevereDeviation.type,
                ).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showDeviationAlert(
                context,
                mostSevereDeviation,
                routeService,
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getAccentColor(
                          mostSevereDeviation.type,
                        ).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        color: _getAccentColor(mostSevereDeviation.type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Route Deviation Detected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _getTextColor(mostSevereDeviation.type),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${mostSevereDeviation.deviationDistance.toStringAsFixed(0)}m from planned route',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getTextColor(
                                mostSevereDeviation.type,
                              ).withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.touch_app_rounded,
                      color: _getAccentColor(mostSevereDeviation.type),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeviationAlert(
    BuildContext context,
    RouteDeviation deviation,
    RouteService routeService,
  ) {
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
  }

  Color _getBackgroundColor(DeviationType type) {
    switch (type) {
      case DeviationType.minor:
        return Colors.grey[50]!;
      case DeviationType.moderate:
        return Colors.orange[50]!;
      case DeviationType.major:
        return Colors.red[50]!;
      case DeviationType.critical:
        return Colors.red[100]!;
    }
  }

  Color _getAccentColor(DeviationType type) {
    switch (type) {
      case DeviationType.minor:
        return Colors.grey[600]!;
      case DeviationType.moderate:
        return Colors.orange[700]!;
      case DeviationType.major:
        return Colors.red[700]!;
      case DeviationType.critical:
        return Colors.red[900]!;
    }
  }

  Color _getTextColor(DeviationType type) {
    switch (type) {
      case DeviationType.minor:
        return Colors.grey[800]!;
      case DeviationType.moderate:
        return Colors.orange[900]!;
      case DeviationType.major:
        return Colors.red[900]!;
      case DeviationType.critical:
        return Colors.red[900]!;
    }
  }
}
