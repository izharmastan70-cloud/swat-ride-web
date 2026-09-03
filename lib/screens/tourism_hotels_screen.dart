import 'package:flutter/material.dart';

import 'hotel_list_screen.dart';
import 'tour_destinations_screen.dart';

class TourismHotelsScreen extends StatelessWidget {
  const TourismHotelsScreen({
    super.key,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Tourism & Hotels',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // HEADER
              // =================================================
              const Text(
                'Explore Swat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Discover the beauty of Swat, plan your complete tour and find the right hotel for your stay.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              // =================================================
              // SWAT TOURS OPTION
              // =================================================
              _optionCard(
                icon: Icons.landscape,
                title: 'SWAT Tours',
                subtitle:
                    'Explore major tourist destinations across Swat with private family tours, group tours and customised packages.',
                buttonText: 'Explore SWAT Tours',
                onTap: () {
                  // =================================================
                  // REAL FIREBASE CODE
                  // =================================================
                  //
                  // Real tour data later Firestore se load hoga.
                  // Abhi testing ke liye local screen open ho rahi hai.
                  //
                  // Billing issue solve hone ke baad image upload,
                  // payment aur booking confirmation connect honge.
                  //
                  // =================================================

                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          const TourDestinationsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // =================================================
              // HOTELS OPTION
              // =================================================
              _optionCard(
                icon: Icons.hotel,
                title: 'Hotels',
                subtitle:
                    'Find Budget, Standard, Family and Luxury hotels in Mingora, Fizagat, Bahrain, Kalam and other Swat destinations.',
                buttonText: 'Explore Hotels',
                onTap: () {
                  // =================================================
                  // REAL FIREBASE CODE
                  // =================================================
                  //
                  // Real hotel inventory later Firestore se load hoga.
                  // Abhi testing ke liye local hotel list open hogi.
                  //
                  // Billing issue solve hone ke baad hotel images,
                  // room availability aur payment connect honge.
                  //
                  // =================================================

                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          const HotelListScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 26),

              // =================================================
              // TOURISM SERVICES
              // =================================================
              const Text(
                'Tourism Services',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              _featureCard(
                icon: Icons.directions_car,
                title: 'Private Family Tour',
                subtitle:
                    'Choose a destination, then book a private vehicle and driver for your family.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          const TourDestinationsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              _featureCard(
                icon: Icons.groups,
                title: 'Group / Sharing Tour',
                subtitle:
                    'Choose a destination, then join an affordable per-person group tour.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          const TourDestinationsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              _featureCard(
                icon: Icons.hotel,
                title: 'Hotel Booking',
                subtitle:
                    'Choose from Budget, Standard, Family and Luxury stay options.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          const HotelListScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              _featureCard(
                icon: Icons.terrain,
                title: '4x4 Jeep & Adventure',
                subtitle:
                    'Book a 4x4 jeep for Mahodand Lake and difficult mountain routes.',
                onTap: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          '4x4 Jeep booking will be connected in the Adventure phase.',
                        ),
                        backgroundColor: darkCard,
                      ),
                    );

                  // REAL FIREBASE / ADMIN CODE - KEEP FOR LATER
                  //
                  // Admin will control jeep availability, routes,
                  // assigned driver, pricing and service status.
                },
              ),

              const SizedBox(height: 10),

              _featureCard(
                icon: Icons.map,
                title: 'Swat Destination Guide',
                subtitle:
                    'Discover tourist places, routes, food spots and important travel information.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          const TourDestinationsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // =================================================
              // INFORMATION CARD
              // =================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: yellow,
                      size: 28,
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'SWAT RIDE Tourism provides complete Swat tour planning, private and group tours, hotel selection, vehicle booking, 4x4 jeep services and destination information.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // MAIN OPTION CARD
  // =========================================================
  Widget _optionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: yellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: yellow,
              size: 30,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Icon(
                    Icons.arrow_forward,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TOURISM FEATURE CARD
  // =========================================================
  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    // REAL ADMIN CONTROL - KEEP FOR LATER
    //
    // Firestore/Admin Panel will control:
    // - service visibility
    // - card order
    // - title and subtitle
    // - badge and starting price
    // - active/inactive status
    //
    // Local cards remain available for safe testing.

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: yellow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: yellow,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_ios,
              color: yellow,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

