import 'package:flutter/material.dart';

import 'group_tour_screen.dart';
import 'private_family_tour_screen.dart';

class TourDestinationsScreen extends StatelessWidget {
  const TourDestinationsScreen({
    super.key,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> destinations = [
      {
        'title': 'Mingora & Fizagat',
        'subtitle':
            'Explore the main city of Swat, Swat River views, Fizagat Park and local attractions.',
        'icon': Icons.location_city,
        'category': 'City & Nature',
      },
      {
        'title': 'Malam Jabba',
        'subtitle':
            'Famous mountain destination for skiing, chairlift, adventure activities and beautiful views.',
        'icon': Icons.downhill_skiing,
        'category': 'Adventure',
      },
      {
        'title': 'Bahrain',
        'subtitle':
            'A beautiful riverside town with local markets, river views and a peaceful mountain atmosphere.',
        'icon': Icons.water,
        'category': 'Riverside',
      },
      {
        'title': 'Kalam',
        'subtitle':
            'One of the most popular Swat destinations with mountains, rivers, forests and scenic valleys.',
        'icon': Icons.landscape,
        'category': 'Valley',
      },
      {
        'title': 'Mahodand Lake',
        'subtitle':
            'A spectacular alpine lake near Kalam, usually requiring a 4x4 jeep for the mountain route.',
        'icon': Icons.water_drop,
        'category': 'Lake & Adventure',
      },
      {
        'title': 'Ushu Forest',
        'subtitle':
            'Beautiful forest area near Kalam, ideal for nature lovers, photography and peaceful trips.',
        'icon': Icons.forest,
        'category': 'Nature',
      },
      {
        'title': 'Mataltan',
        'subtitle':
            'A scenic mountain area near Kalam known for waterfalls, forests and impressive natural landscapes.',
        'icon': Icons.terrain,
        'category': 'Nature & Waterfall',
      },
      {
        'title': 'Gabral Valley',
        'subtitle':
            'A peaceful valley with natural beauty, rivers and mountain scenery away from busy tourist areas.',
        'icon': Icons.nature_people,
        'category': 'Valley',
      },
      {
        'title': 'Miandam',
        'subtitle':
            'A beautiful hill station surrounded by green mountains and peaceful natural surroundings.',
        'icon': Icons.hiking,
        'category': 'Hill Station',
      },
      {
        'title': 'Marghazar & White Palace',
        'subtitle':
            'Visit the historic White Palace and enjoy the beautiful surroundings of Marghazar Valley.',
        'icon': Icons.castle,
        'category': 'History & Nature',
      },
      {
        'title': 'Saidu Sharif',
        'subtitle':
            'Explore the cultural and historical heart of Swat with important local heritage sites.',
        'icon': Icons.museum,
        'category': 'History & Culture',
      },
      {
        'title': 'Jarogo Waterfall',
        'subtitle':
            'A beautiful waterfall destination surrounded by mountains and natural scenery.',
        'icon': Icons.waterfall_chart,
        'category': 'Waterfall',
      },
      {
        'title': 'Blue Water',
        'subtitle':
            'Enjoy clear blue water, mountain scenery and a refreshing natural environment.',
        'icon': Icons.waves,
        'category': 'Nature',
      },
      {
        'title': 'Madyan',
        'subtitle':
            'A popular riverside town with beautiful surroundings, local markets and access toward upper Swat.',
        'icon': Icons.waves,
        'category': 'Riverside',
      },
      {
        'title': 'Khwazakhela',
        'subtitle':
            'A scenic area of Swat offering access to beautiful mountain routes and local attractions.',
        'icon': Icons.route,
        'category': 'Travel Route',
      },
      {
        'title': 'Shingrai Waterfall',
        'subtitle':
            'A natural waterfall destination suitable for visitors looking for a peaceful outdoor experience.',
        'icon': Icons.waterfall_chart,
        'category': 'Waterfall',
      },
      {
        'title': 'Kundol Lake',
        'subtitle':
            'A beautiful high-altitude lake surrounded by mountains and wilderness near upper Swat.',
        'icon': Icons.water,
        'category': 'Lake & Trekking',
      },
      {
        'title': 'Izmis Lake',
        'subtitle':
            'A remote scenic lake destination for adventurous travellers and nature exploration.',
        'icon': Icons.landscape,
        'category': 'Adventure & Trekking',
      },
      {
        'title': 'Boyun Village',
        'subtitle':
            'Enjoy panoramic mountain views and peaceful village scenery around upper Swat.',
        'icon': Icons.villa,
        'category': 'Village & Views',
      },
      {
        'title': 'Mankial',
        'subtitle':
            'A scenic mountain area with beautiful landscapes and routes for nature-focused travellers.',
        'icon': Icons.terrain,
        'category': 'Mountain',
      },
      {
        'title': 'Shangla Top Route',
        'subtitle':
            'A scenic mountain route connecting travellers toward the beautiful Shangla region.',
        'icon': Icons.alt_route,
        'category': 'Mountain Route',
      },
    ];

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'SWAT Tour Destinations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // HEADER
              // =================================================
              const Text(
                'Explore All Swat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Discover the beautiful valleys, lakes, waterfalls, mountains and tourist destinations of Swat.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // =================================================
              // COMPLETE ALL SWAT TOUR
              // =================================================
              GestureDetector(
                onTap: () {
                  _openTourTypeSelector(
                    context,
                    isAllSwatTour: true,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: yellow,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: yellow.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.tour,
                        color: Colors.black,
                        size: 36,
                      ),

                      SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete All Swat Tour',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 6),

                            Text(
                              'Plan a complete multi-day tour across the beautiful Swat Valley.',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.arrow_forward,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // DESTINATIONS HEADING
              // =================================================
              const Text(
                'Popular & Recommended Places',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              // =================================================
              // DESTINATION LIST
              // =================================================
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: destinations.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 12);
                },
                itemBuilder: (context, index) {
                  final Map<String, dynamic> destination =
                      destinations[index];

                  return _destinationCard(
                    context: context,
                    icon: destination['icon'] as IconData,
                    title: destination['title'] as String,
                    subtitle: destination['subtitle'] as String,
                    category: destination['category'] as String,
                  );
                },
              ),

              const SizedBox(height: 28),

              // =================================================
              // TOUR BOOKING FLOW
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tour Booking Flow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 12),

                    Text(
                      'Destination â†’ Tour Type â†’ Days â†’ Guests â†’ Vehicle â†’ Hotel â†’ Jeep/4x4 â†’ Quotation â†’ Booking',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),

                    SizedBox(height: 12),

                    Text(
                      'Private Family Tours and Group / Sharing Tours are supported.',
                      style: TextStyle(
                        color: yellow,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DESTINATION CARD
  // =========================================================
  Widget _destinationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String category,
  }) {
    return GestureDetector(
      onTap: () {
        _openTourTypeSelector(
          context,
          isAllSwatTour: false,
          destinationName: title,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: yellow.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: yellow,
                size: 29,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: yellow.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: yellow,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.arrow_forward_ios,
              color: yellow,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TOUR TYPE SELECTOR
  // =========================================================
  void _openTourTypeSelector(
    BuildContext context, {
    required bool isAllSwatTour,
    String? destinationName,
  }) {
    final String selectedDestination = isAllSwatTour
        ? 'Complete All Swat Tour'
        : destinationName ?? 'Swat Tour';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: darkBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(
                    bottom: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                Text(
                  selectedDestination,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Select your preferred tour type.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // PRIVATE FAMILY TOUR
                // =================================================
                _tourTypeButton(
                  icon: Icons.family_restroom,
                  title: 'Private Family Tour',
                  subtitle:
                      'Private vehicle, driver and customised family trip.',
                  onTap: () {
                    Navigator.pop(sheetContext);

                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) {
                          return PrivateFamilyTourScreen(
                            destinationName: selectedDestination,
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // =================================================
                // GROUP / SHARING TOUR
                // =================================================
                _tourTypeButton(
                  icon: Icons.groups,
                  title: 'Group / Sharing Tour',
                  subtitle:
                      'Affordable shared tour for individuals and groups.',
                  onTap: () {
                    Navigator.pop(sheetContext);

                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) {
                          return GroupTourScreen(
                            destinationName: selectedDestination,
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // TOUR TYPE BUTTON
  // =========================================================
  Widget _tourTypeButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: yellow.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: yellow,
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
