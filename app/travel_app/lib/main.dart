import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/location_provider.dart';
import 'providers/tourist_provider.dart';
import 'services/route_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TravelApp());
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => TouristProvider()),
        ChangeNotifierProvider(create: (_) => RouteService()),
      ],
      child: MaterialApp.router(
        title: 'TourRaksha - Tourist Safety App',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
