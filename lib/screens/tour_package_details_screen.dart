import 'package:flutter/material.dart';
import 'tour_vehicle_selection_screen.dart';

class TourPackageDetailsScreen extends StatefulWidget {
  const TourPackageDetailsScreen({
    super.key,
    this.tourType = 'Private Family Tour',
  });

  final String tourType;

  @override
  State<TourPackageDetailsScreen> createState() =>
      _TourPackageDetailsScreenState();
}

class _TourPackageDetailsScreenState
    extends State<TourPackageDetailsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  String selectedDuration = '3 Days / 2 Nights';

  String selectedDestination =
      'Complete Swat Tour';

  int guests = 4;

  final List<String> durations = [
    '2 Days / 1 Night',
    '3 Days / 2 Nights',
    '4 Days / 3 Nights',
    '5 Days / 4 Nights',
    '7 Days / 6 Nights',
  ];

  final List<String> destinations = [
    'Mingora & Fizagat',
    'Malam Jabba',
    'Bahrain & Kalam',
    'Kalam & Mahodand Lake',
    'Complete Swat Tour',
    'Swat + Kumrat Valley',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,

      appBar: AppBar(
        backgroundColor: darkBackground,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Tour Package',
          style: TextStyle(
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
              const Text(
                'Plan Your Swat Tour',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                widget.tourType,
                style: const TextStyle(
                  color: yellow,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              _sectionTitle(
                'Tour Duration',
              ),

              const SizedBox(height: 10),

              _dropdownCard(
                value: selectedDuration,
                items: durations,
                icon: Icons.calendar_month,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedDuration = value;
                  });
                },
              ),

              const SizedBox(height: 22),

              _sectionTitle(
                'Main Destination',
              ),

              const SizedBox(height: 10),

              _dropdownCard(
                value: selectedDestination,
                items: destinations,
                icon: Icons.landscape,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedDestination = value;
                  });
                },
              ),

              const SizedBox(height: 22),

              _sectionTitle(
                'Number of Guests',
              ),

              const SizedBox(height: 10),

              _guestCounter(),

              const SizedBox(height: 24),

              _sectionTitle(
                'Your Tour Plan',
              ),

              const SizedBox(height: 12),

              _planItem(
                Icons.directions_car,
                'Vehicle Selection',
                'Choose private car or group vehicle.',
              ),

              _planItem(
                Icons.hotel,
                'Hotel Selection',
                'Select Budget, Standard, Family or Luxury stay.',
              ),

              _planItem(
                Icons.terrain,
                '4x4 Jeep',
                'Required for Mahodand Lake and difficult mountain routes.',
              ),

              _planItem(
                Icons.map,
                'Destination Guide',
                'Explore routes, tourist points and travel information.',
              ),

              _planItem(
                Icons.request_quote,
                'Instant Quotation',
                'Get an estimated package price before booking.',
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius:
                      BorderRadius.circular(18),

                  border: Border.all(
                    color: yellow.withValues(
                      alpha: 0.25,
                    ),
                  ),
                ),

                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Icon(
                      Icons.info_outline,
                      color: yellow,
                      size: 28,
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Final quotation will depend on tour duration, number of guests, vehicle type, hotel category, seasonal rates and optional 4x4 jeep service.',
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

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton.icon(
                  onPressed: () {
                   Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => TourVehicleSelectionScreen(
      tourDays: int.tryParse(
      selectedDuration.split(' ').first,
    ) ??
    3,
      guests: guests,
    ),
  ),
);
                  },

                  icon: const Icon(
                    Icons.arrow_forward,
                    color: Colors.black,
                  ),

                  label: const Text(
                    'Continue to Vehicle Selection',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: yellow,

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 16,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _dropdownCard({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?>
        onChanged,
  }) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
      ),

      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(16),
      ),

      child:
          DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: darkCard,

          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: yellow,
          ),

          items: items.map(
            (item) {
              return DropdownMenuItem<String>(
                value: item,

                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: yellow,
                      size: 23,
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Text(
                      item,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ).toList(),

          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _guestCounter() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(16),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration:
                BoxDecoration(
              color:
                  yellow.withValues(
                alpha: 0.12,
              ),

              shape:
                  BoxShape.circle,
            ),

            child: const Icon(
              Icons.groups,
              color: yellow,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Text(
              'Travellers',
              style: TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          IconButton(
            onPressed: guests > 1
                ? () {
                    setState(() {
                      guests--;
                    });
                  }
                : null,

            icon: const Icon(
              Icons.remove_circle,
              color: yellow,
            ),
          ),

          Text(
            '$guests',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          IconButton(
            onPressed: guests < 20
                ? () {
                    setState(() {
                      guests++;
                    });
                  }
                : null,

            icon: const Icon(
              Icons.add_circle,
              color: yellow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planItem(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
          const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(14),
      ),

      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,

            decoration:
                BoxDecoration(
              color:
                  yellow.withValues(
                alpha: 0.12,
              ),

              shape:
                  BoxShape.circle,
            ),

            child: Icon(
              icon,
              color: yellow,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style:
                      const TextStyle(
                    color:
                        Colors.grey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.check_circle_outline,
            color: yellow,
          ),
        ],
      ),
    );
  }

}
