import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/tourism_hotels_screen.dart';
import 'ride_admin/screens/ride_admin_access_guard_screen.dart';
import 'services/app_integrity_service.dart';
import 'widgets/floating_social_media_bar.dart';

// ===============================
// FOOD MODULE
// ===============================
import 'food/food_routes.dart';
import 'rewards/reward_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppIntegrityService.activate();

  runApp(const SwatRideApp());
}

class SwatRideApp extends StatelessWidget {
  const SwatRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SWAT RIDE',

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD60A),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      builder: (context, child) => FloatingSocialMediaShell(
        child: child ?? const SizedBox.shrink(),
      ),

      // =====================================================
      // EXISTING APP ROUTES
      // =====================================================
      routes: {
        '/login': (context) => const LoginScreen(),

        '/tourHotelSelection': (context) => const TourismHotelsScreen(),
        '/rideAdmin': (context) => const RideAdminAccessGuardScreen(),

        '/home': (context) => const SwatRideHomePage(),
      },

      // =====================================================
      // FOOD ROUTES
      // =====================================================
      onGenerateRoute: (settings) {
        // Food module routes
        final Route<dynamic>? route = FoodRoutes.onGenerateRoute(settings);

        if (route != null) {
          return route;
        }

        // Global Rewards module routes
        final Route<dynamic>? rewardRoute = RewardRoutes.onGenerateRoute(
          settings,
        );

        if (rewardRoute != null) {
          return rewardRoute;
        }

        // Unknown route fallback
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('SWAT RIDE')),
            body: Center(
              child: Text(
                'Route not found:\n${settings.name}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },

      // =====================================================
      // FIRST SCREEN
      // =====================================================
      home: const LoginScreen(),
    );
  }
}
