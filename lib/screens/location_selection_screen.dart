import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_model.dart';
import '../models/map_location_model.dart';
import '../services/ride_location_service.dart';
import '../help/widgets/contextual_video_guide_button.dart';
import 'open_map_selection_screen.dart';
import 'vehicle_selection_screen.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color darkCard = Color(0xFF1A1A1A);

  // =========================================================
  // LOCATION DATA
  // =========================================================

  Position? currentPosition;

  LocationModel? pickupLocation;

  LocationModel? destinationLocation;

  bool isLoadingLocation = true;

  // =========================================================
  // DEFAULT SWAT LOCATION
  // =========================================================

  static const double defaultLatitude = 34.7717;
  static const double defaultLongitude = 72.3602;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _getCurrentLocation();
  }

  // =========================================================
  // GET CURRENT LOCATION
  // =========================================================

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      isLoadingLocation = true;
    });

    try {
      // -------------------------------------------------------
      // CHECK GPS SERVICE
      // -------------------------------------------------------

      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _setDefaultPickupLocation();

        _showError('GPS is off. Testing mode: Swat default location selected.');

        return;
      }

      // -------------------------------------------------------
      // CHECK PERMISSION
      // -------------------------------------------------------

      LocationPermission permission = await Geolocator.checkPermission();

      // -------------------------------------------------------
      // REQUEST PERMISSION
      // -------------------------------------------------------

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // -------------------------------------------------------
      // PERMISSION DENIED
      // -------------------------------------------------------

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setDefaultPickupLocation();

        _showError('Location permission unavailable. Testing mode enabled.');

        return;
      }

      // -------------------------------------------------------
      // GET CURRENT GPS
      // -------------------------------------------------------

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      final LocationModel location = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        address: 'Current GPS Location',
        placeName: 'My Current Location',
      );

      setState(() {
        currentPosition = position;
        pickupLocation = location;
        isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint('GET CURRENT LOCATION ERROR: $e');

      _setDefaultPickupLocation();

      _showError('GPS unavailable. Testing mode: Swat location selected.');
    }
  }

  // =========================================================
  // DEFAULT PICKUP LOCATION
  // =========================================================

  void _setDefaultPickupLocation() {
    if (!mounted) return;

    final LocationModel location = LocationModel(
      latitude: defaultLatitude,
      longitude: defaultLongitude,
      address: 'Swat, Khyber Pakhtunkhwa',
      placeName: 'Swat Testing Location',
    );

    setState(() {
      currentPosition = null;
      pickupLocation = location;
      isLoadingLocation = false;
    });
  }

  // =========================================================
  // MAP DESTINATION
  // =========================================================

  Future<void> _selectDestinationOnMap() async {
    final LocationModel? existingDestination = destinationLocation;
    final MapLocation? selected = await Navigator.of(context).push<MapLocation>(
      MaterialPageRoute<MapLocation>(
        builder: (BuildContext context) => OpenMapSelectionScreen(
          title: 'Select Destination',
          subtitle: 'Tap or move the map to place the destination pin.',
          initialLocation: existingDestination == null
              ? null
              : MapLocation.fromCoordinates(
                  existingDestination.latitude,
                  existingDestination.longitude,
                  addressName: existingDestination.address,
                  placeName: existingDestination.placeName,
                ),
          onLocationSelected: (_) {},
        ),
      ),
    );
    if (!mounted || selected == null) return;

    setState(() {
      destinationLocation = LocationModel(
        latitude: selected.latitude,
        longitude: selected.longitude,
        address: selected.addressName ?? 'Pinned map location',
        placeName: selected.placeName ?? 'Selected Destination',
      );
    });

    _showSuccess('Destination updated.');
  }

  // =========================================================
  // SEARCH DESTINATION
  // =========================================================

  Future<void> _openDestinationSearch() async {
    final LocationModel? selected = await showModalBottomSheet<LocationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const _DestinationSearchSheet();
      },
    );

    if (!mounted || selected == null) return;

    setState(() {
      destinationLocation = selected;
    });

    _showSuccess('${selected.placeName} selected successfully.');
  }

  // =========================================================
  // CHOOSE RIDE
  // =========================================================

  void _chooseRide() {
    if (pickupLocation == null) {
      _showError('Pickup location is not available yet.');

      return;
    }

    if (destinationLocation == null) {
      _showError('Please select your destination on the testing map.');

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleSelectionScreen(
          pickupLocation: pickupLocation!,
          destinationLocation: destinationLocation!,
        ),
      ),
    );
  }

  // =========================================================
  // ERROR SNACKBAR
  // =========================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(message)),
    );
  }

  // =========================================================
  // SUCCESS SNACKBAR
  // =========================================================

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.green, content: Text(message)),
    );
  }

  // =========================================================
  // TESTING MAP
  // =========================================================

  Widget _buildTestingMap() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,

          onTapDown: null,

          child: Container(
            width: double.infinity,
            height: double.infinity,

            decoration: const BoxDecoration(color: Color(0xFF202124)),

            child: Stack(
              children: [
                // =================================================
                // FAKE MAP
                // =================================================
                Positioned.fill(
                  child: CustomPaint(painter: _TestingMapPainter()),
                ),

                // =================================================
                // MAP TITLE
                // =================================================
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: const Row(
                      children: [
                        Icon(Icons.map_outlined, color: yellow, size: 22),

                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'SWAT RIDE â€¢ Testing Map',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // =================================================
                // PICKUP MARKER
                // =================================================
                Positioned(
                  left: constraints.maxWidth * 0.42,

                  top: constraints.maxHeight * 0.34,

                  child: const Column(
                    children: [
                      Icon(Icons.location_on, color: Colors.green, size: 44),

                      Text(
                        'Pickup',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // =================================================
                // DESTINATION MARKER
                // =================================================
                if (destinationLocation != null)
                  Positioned(
                    left: constraints.maxWidth * 0.62,

                    top: constraints.maxHeight * 0.55,

                    child: const Column(
                      children: [
                        Icon(Icons.location_on, color: Colors.red, size: 44),

                        Text(
                          'Destination',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                // =================================================
                // TEST MODE BADGE
                // =================================================
                Positioned(
                  bottom: 230,
                  left: 20,
                  right: 20,

                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),

                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: const Text(
                        'Select a destination with the map button below',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // =======================================================
      // APP BAR
      // =======================================================
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Choose Location',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // =======================================================
      // BODY
      // =======================================================
      body: Stack(
        children: [
          // =====================================================
          // TESTING MAP
          // =====================================================
          Positioned.fill(child: _buildTestingMap()),

          // =====================================================
          // LOADING LOCATION
          // =====================================================
          if (isLoadingLocation)
            Positioned(
              top: 16,
              left: 16,
              right: 16,

              child: Container(
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: darkCard,

                  borderRadius: BorderRadius.circular(14),
                ),

                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,

                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: yellow,
                      ),
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Getting your current location...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // =====================================================
          // LOCATION INFORMATION CARD
          // =====================================================
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,

            child: Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: darkCard,

                borderRadius: BorderRadius.circular(20),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),

                    blurRadius: 15,

                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // =================================================
                  // PICKUP
                  // =================================================
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        color: Colors.green,
                        size: 22,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              'Pickup',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              pickupLocation?.placeName ??
                                  'Getting current location...',

                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.my_location, color: yellow),

                        onPressed: _getCurrentLocation,
                      ),
                    ],
                  ),

                  // =================================================
                  // DIVIDER
                  // =================================================
                  const Padding(
                    padding: EdgeInsets.only(left: 10),

                    child: Divider(color: Colors.white24),
                  ),

                  // =================================================
                  // DESTINATION
                  // =================================================
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 22,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              'Destination',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              destinationLocation?.placeName ??
                                  'Select your destination on the map',

                              style: TextStyle(
                                color: destinationLocation == null
                                    ? Colors.grey
                                    : Colors.white,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  ContextualVideoGuideButton(
                    module: 'ride',
                    feature: 'location_selection',
                    intents: const <String>[
                      'select_pickup',
                      'select_destination',
                      'choose_location',
                      'pickup_dropoff',
                      'location_search',
                    ],
                    label: 'Need Help? Watch Guide',
                  ),

                  const SizedBox(height: 12),

                  // =================================================
                  // SEARCH DESTINATION
                  // =================================================
                  SizedBox(
                    width: double.infinity,

                    height: 46,

                    child: ElevatedButton.icon(
                      onPressed: _openDestinationSearch,

                      icon: const Icon(Icons.search, size: 20),

                      label: const Text('Search Destination'),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,

                        foregroundColor: Colors.white,

                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // =================================================
                  // MAP DESTINATION
                  // =================================================
                  SizedBox(
                    width: double.infinity,

                    height: 42,

                    child: OutlinedButton.icon(
                      onPressed: _selectDestinationOnMap,

                      icon: const Icon(Icons.flag_outlined, size: 18),

                      label: const Text('Select Destination on Map'),

                      style: OutlinedButton.styleFrom(
                        foregroundColor: yellow,

                        side: const BorderSide(color: yellow),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =================================================
                  // CHOOSE RIDE BUTTON
                  // =================================================
                  SizedBox(
                    width: double.infinity,

                    height: 52,

                    child: ElevatedButton(
                      onPressed: isLoadingLocation ? null : _chooseRide,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: yellow,

                        foregroundColor: Colors.black,

                        disabledBackgroundColor: Colors.grey.shade700,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      child: const Text(
                        'Choose Ride',

                        style: TextStyle(
                          fontSize: 16,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // =================================================
                  // TESTING MODE INFO
                  // =================================================
                  const Center(
                    child: Text(
                      'Mapbox selection with live route fare estimates',

                      textAlign: TextAlign.center,

                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// TESTING MAP PAINTER
// =============================================================

class _TestingMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // =========================================================
    // BACKGROUND
    // =========================================================

    final Paint backgroundPaint = Paint()
      ..color = const Color(0xFF202124)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // =========================================================
    // GRID PAINT
    // =========================================================

    final Paint gridPaint = Paint()
      ..color = const Color(0xFF292A2D)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // =========================================================
    // DRAW VERTICAL GRID
    // =========================================================

    const double gridSize = 55.0;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // =========================================================
    // DRAW HORIZONTAL GRID
    // =========================================================

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // =========================================================
    // MAIN ROAD PAINT
    // =========================================================

    final Paint roadPaint = Paint()
      ..color = const Color(0xFF303134)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // =========================================================
    // ROAD CENTER PAINT
    // =========================================================

    final Paint roadCenterPaint = Paint()
      ..color = const Color(0xFF3C4043)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // =========================================================
    // HORIZONTAL MAIN ROAD
    // =========================================================

    final Path horizontalRoad = Path();

    horizontalRoad.moveTo(0, size.height * 0.42);

    horizontalRoad.cubicTo(
      size.width * 0.20,
      size.height * 0.36,
      size.width * 0.35,
      size.height * 0.48,
      size.width * 0.55,
      size.height * 0.42,
    );

    horizontalRoad.cubicTo(
      size.width * 0.72,
      size.height * 0.37,
      size.width * 0.85,
      size.height * 0.47,
      size.width,
      size.height * 0.40,
    );

    canvas.drawPath(horizontalRoad, roadPaint);

    canvas.drawPath(horizontalRoad, roadCenterPaint);

    // =========================================================
    // VERTICAL MAIN ROAD
    // =========================================================

    final Path verticalRoad = Path();

    verticalRoad.moveTo(size.width * 0.68, 0);

    verticalRoad.cubicTo(
      size.width * 0.60,
      size.height * 0.20,
      size.width * 0.75,
      size.height * 0.35,
      size.width * 0.68,
      size.height * 0.55,
    );

    verticalRoad.cubicTo(
      size.width * 0.62,
      size.height * 0.72,
      size.width * 0.74,
      size.height * 0.86,
      size.width * 0.68,
      size.height,
    );

    canvas.drawPath(verticalRoad, roadPaint);

    canvas.drawPath(verticalRoad, roadCenterPaint);

    // =========================================================
    // DIAGONAL ROAD
    // =========================================================

    final Path diagonalRoad = Path();

    diagonalRoad.moveTo(0, size.height * 0.78);

    diagonalRoad.cubicTo(
      size.width * 0.20,
      size.height * 0.70,
      size.width * 0.35,
      size.height * 0.82,
      size.width * 0.50,
      size.height * 0.74,
    );

    diagonalRoad.cubicTo(
      size.width * 0.67,
      size.height * 0.66,
      size.width * 0.82,
      size.height * 0.78,
      size.width,
      size.height * 0.70,
    );

    canvas.drawPath(diagonalRoad, roadPaint);

    canvas.drawPath(diagonalRoad, roadCenterPaint);

    // =========================================================
    // SMALL ROAD
    // =========================================================

    final Paint smallRoadPaint = Paint()
      ..color = const Color(0xFF2B2C2F)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path smallRoad = Path();

    smallRoad.moveTo(0, size.height * 0.18);

    smallRoad.cubicTo(
      size.width * 0.25,
      size.height * 0.25,
      size.width * 0.40,
      size.height * 0.10,
      size.width * 0.58,
      size.height * 0.18,
    );

    smallRoad.cubicTo(
      size.width * 0.72,
      size.height * 0.24,
      size.width * 0.85,
      size.height * 0.12,
      size.width,
      size.height * 0.20,
    );

    canvas.drawPath(smallRoad, smallRoadPaint);

    // =========================================================
    // MAP LANDMARK DOTS
    // =========================================================

    final Paint landmarkPaint = Paint()
      ..color = const Color(0xFF5F6368)
      ..style = PaintingStyle.fill;

    final List<Offset> landmarks = [
      Offset(size.width * 0.18, size.height * 0.28),
      Offset(size.width * 0.32, size.height * 0.62),
      Offset(size.width * 0.82, size.height * 0.32),
      Offset(size.width * 0.88, size.height * 0.58),
      Offset(size.width * 0.22, size.height * 0.88),
    ];

    for (final Offset point in landmarks) {
      canvas.drawCircle(point, 4, landmarkPaint);
    }
  }

  // =========================================================
  // SHOULD REPAINT
  // =========================================================

  @override
  bool shouldRepaint(covariant _TestingMapPainter oldDelegate) {
    return false;
  }
}

// =============================================================
// DESTINATION SEARCH BOTTOM SHEET
// =============================================================

class _DestinationSearchSheet extends StatefulWidget {
  const _DestinationSearchSheet();

  @override
  State<_DestinationSearchSheet> createState() =>
      _DestinationSearchSheetState();
}

class _DestinationSearchSheetState extends State<_DestinationSearchSheet> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF111111);
  static const Color darkCard = Color(0xFF1A1A1A);

  final RideLocationService _locationService = RideLocationService();

  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;

  List<LocationModel> _results = const <LocationModel>[];

  bool _isLoading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadPopularPlaces();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();

    super.dispose();
  }

  Future<void> _loadPopularPlaces() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<LocationModel> places = await _locationService
          .getPopularPlaces();

      if (!mounted) return;

      setState(() {
        _results = places;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD POPULAR PLACES ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Places could not be loaded.';
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});

    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchPlaces(value);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      await _loadPopularPlaces();

      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<LocationModel> places = await _locationService.searchPlaces(
        query,
      );

      if (!mounted) return;

      setState(() {
        _results = places;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('SEARCH PLACES ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Search failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return FractionallySizedBox(
      heightFactor: 0.88,

      child: Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + keyboardHeight),

        decoration: const BoxDecoration(
          color: background,

          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),

        child: Column(
          children: [
            Container(
              width: 44,
              height: 5,

              decoration: BoxDecoration(
                color: Colors.white24,

                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Destination',

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearchChanged,
              onSubmitted: _searchPlaces,
              textInputAction: TextInputAction.search,

              style: const TextStyle(color: Colors.white),

              decoration: InputDecoration(
                hintText: 'Search destination in Swat',

                hintStyle: const TextStyle(color: Colors.white38),

                prefixIcon: const Icon(Icons.search, color: yellow),

                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();

                          _loadPopularPlaces();
                        },

                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),

                filled: true,
                fillColor: darkCard,

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),

                  borderSide: const BorderSide(color: Colors.white12),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),

                  borderSide: const BorderSide(color: yellow, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Align(
              alignment: Alignment.centerLeft,

              child: Text(
                _searchController.text.trim().isEmpty
                    ? 'Popular places in Swat'
                    : 'Search results',

                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(child: _buildResults()),

            const SizedBox(height: 8),

            const Text(
              'Testing places active â€¢ Real Google Places code is preserved in the service',

              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: yellow));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(Icons.cloud_off, color: yellow, size: 42),

            const SizedBox(height: 12),

            Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),

            TextButton(
              onPressed: _loadPopularPlaces,

              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(Icons.search_off, color: yellow, size: 42),

            SizedBox(height: 12),

            Text(
              'No destination found.\nTry another place name.',

              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

      itemCount: _results.length,

      separatorBuilder: (BuildContext context, int index) {
        return const Divider(color: Colors.white10, height: 1, indent: 55);
      },

      itemBuilder: (BuildContext context, int index) {
        final LocationModel place = _results[index];

        return ListTile(
          onTap: () {
            Navigator.pop(context, place);
          },

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 3,
          ),

          leading: const CircleAvatar(
            backgroundColor: Colors.white10,

            child: Icon(Icons.location_on, color: yellow),
          ),

          title: Text(
            place.placeName,

            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),

          subtitle: Text(
            place.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(color: Colors.white54),
          ),

          trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        );
      },
    );
  }
}
