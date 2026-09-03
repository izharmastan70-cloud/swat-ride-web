import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/hotel_recommendation.dart';
import '../services/hotel_recommendation_service.dart';
import 'hotel_detail_screen.dart';

class HotelRecommendationScreen extends StatefulWidget {
  const HotelRecommendationScreen({
    super.key,
  });

  @override
  State<HotelRecommendationScreen> createState() =>
      _HotelRecommendationScreenState();
}

class _HotelRecommendationScreenState
    extends State<HotelRecommendationScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final HotelRecommendationService _service =
      HotelRecommendationService();

  final TextEditingController _destinationController =
      TextEditingController(text: 'Kalam');

  final TextEditingController _budgetController =
      TextEditingController(text: '8000');

  DateTime _checkInDate =
      DateTime.now().add(const Duration(days: 1));

  DateTime _checkOutDate =
      DateTime.now().add(const Duration(days: 3));

  int _adults = 2;
  int _children = 0;
  int _rooms = 1;

  String _tripType = 'family';

  bool _needsParking = true;
  bool _needsHotWater = true;
  bool _needsFamilyRoom = true;
  bool _needsWiFi = false;
  bool _needsRestaurant = false;
  bool _needsMountainView = false;
  bool _needsRiverView = false;

  bool _isLoading = false;
  String _errorMessage = '';

  HotelRecommendationResponse? _response;

  final List<String> _tripTypes =
      const <String>[
    'family',
    'couple',
    'solo',
    'business',
    'group',
  ];

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

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
          'Smart Hotel Recommendation',
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
            12,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _introCard(),
              const SizedBox(height: 18),
              _searchForm(),
              const SizedBox(height: 18),
              if (_errorMessage.isNotEmpty)
                _errorCard(),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 28,
                  ),
                  child: Center(
                    child:
                        CircularProgressIndicator(
                      color: yellow,
                    ),
                  ),
                ),
              if (!_isLoading &&
                  _response != null)
                _resultsSection(
                  _response!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _introCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome,
            color: yellow,
            size: 28,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Enter your budget, dates, guests and required facilities. The safe recommendation engine will rank available hotels and explain every match.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Stay Preferences',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _textField(
            controller:
                _destinationController,
            label: 'Destination',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 12),
          _textField(
            controller:
                _budgetController,
            label:
                'Maximum Budget Per Night (PKR)',
            icon: Icons.payments_outlined,
            keyboardType:
                TextInputType.number,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _dateCard(
                  title: 'Check-in',
                  date: _checkInDate,
                  onTap: () =>
                      _pickCheckInDate(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateCard(
                  title: 'Check-out',
                  date: _checkOutDate,
                  onTap: () =>
                      _pickCheckOutDate(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _counterRow(
            title: 'Adults',
            icon: Icons.person_outline,
            value: _adults,
            min: 1,
            max: 20,
            onChanged: (value) {
              setState(() {
                _adults = value;
              });
            },
          ),
          const SizedBox(height: 10),
          _counterRow(
            title: 'Children',
            icon: Icons.child_care,
            value: _children,
            min: 0,
            max: 20,
            onChanged: (value) {
              setState(() {
                _children = value;
              });
            },
          ),
          const SizedBox(height: 10),
          _counterRow(
            title: 'Rooms',
            icon: Icons.meeting_room_outlined,
            value: _rooms,
            min: 1,
            max: 10,
            onChanged: (value) {
              setState(() {
                _rooms = value;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Trip Type',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tripTypes.map(
              (String type) {
                final bool selected =
                    _tripType == type;

                return ChoiceChip(
                  selected: selected,
                  label: Text(
                    _capitalize(type),
                  ),
                  selectedColor:
                      yellow.withValues(
                    alpha: 0.25,
                  ),
                  checkmarkColor: yellow,
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.grey,
                    fontWeight:
                        FontWeight.bold,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _tripType = type;
                    });
                  },
                );
              },
            ).toList(),
          ),
          const SizedBox(height: 18),
          const Text(
            'Required Facilities',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _switchTile(
            title: 'Parking',
            value: _needsParking,
            onChanged: (value) {
              setState(() {
                _needsParking = value;
              });
            },
          ),
          _switchTile(
            title: 'Hot Water',
            value: _needsHotWater,
            onChanged: (value) {
              setState(() {
                _needsHotWater = value;
              });
            },
          ),
          _switchTile(
            title: 'Family Room',
            value: _needsFamilyRoom,
            onChanged: (value) {
              setState(() {
                _needsFamilyRoom =
                    value;
              });
            },
          ),
          _switchTile(
            title: 'Wi-Fi',
            value: _needsWiFi,
            onChanged: (value) {
              setState(() {
                _needsWiFi = value;
              });
            },
          ),
          _switchTile(
            title: 'Restaurant',
            value: _needsRestaurant,
            onChanged: (value) {
              setState(() {
                _needsRestaurant =
                    value;
              });
            },
          ),
          _switchTile(
            title: 'Mountain View',
            value:
                _needsMountainView,
            onChanged: (value) {
              setState(() {
                _needsMountainView =
                    value;
              });
            },
          ),
          _switchTile(
            title: 'River View',
            value: _needsRiverView,
            onChanged: (value) {
              setState(() {
                _needsRiverView = value;
              });
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : _findRecommendations,
              icon: const Icon(
                Icons.auto_awesome,
              ),
              label: const Text(
                'Find Best Hotels',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor:
                    Colors.black,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsSection(
    HotelRecommendationResponse response,
  ) {
    if (response.results.isEmpty) {
      return _messageCard(
        icon:
            Icons.search_off_outlined,
        title: 'No Matching Hotels',
        message:
            'No active hotel matched the selected dates and preferences. Try another destination, budget or fewer required facilities.',
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recommended Hotels',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${response.results.length} result(s)',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Engine: ${response.engineVersion} • AI Agent not required for ranking',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 14),
        ...response.results.map(
          _resultCard,
        ),
      ],
    );
  }

  Widget _resultCard(
    HotelRecommendationResult result,
  ) {
    final Color matchColor =
        result.matchPercentage >= 80
            ? Colors.green
            : result.matchPercentage >= 60
                ? Colors.orange
                : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: result.rank == 1
              ? yellow
              : matchColor.withValues(
                  alpha: 0.30,
                ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                alignment:
                    Alignment.center,
                decoration: BoxDecoration(
                  color: yellow.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Text(
                  '#${result.rank}',
                  style: const TextStyle(
                    color: yellow,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.hotelName,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.location,
                      style:
                          const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color:
                      matchColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: Text(
                  '${result.matchPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: matchColor,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(
            'Category',
            result.category,
          ),
          _infoRow(
            'Night Price',
            result.pricePerNight > 0
                ? 'PKR ${_money(result.pricePerNight)}'
                : 'Price on request',
          ),
          _infoRow(
            'Estimated Total',
            result.totalStayPrice > 0
                ? 'PKR ${_money(result.totalStayPrice)}'
                : 'Not available',
          ),
          _infoRow(
            'Available Rooms',
            '${result.availableRooms}',
          ),
          _infoRow(
            'Rating',
            result.rating > 0
                ? '${result.rating.toStringAsFixed(1)} (${result.reviewCount} reviews)'
                : 'New hotel',
          ),
          const SizedBox(height: 10),
          if (result.matchedReasons.isNotEmpty)
            _reasonSection(
              title: 'Why it matches',
              items:
                  result.matchedReasons,
              icon:
                  Icons.check_circle_outline,
              color: Colors.green,
            ),
          if (result.missingRequirements
              .isNotEmpty) ...[
            const SizedBox(height: 8),
            _reasonSection(
              title: 'Warnings',
              items: result
                  .missingRequirements,
              icon:
                  Icons.warning_amber_outlined,
              color: Colors.orange,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            result.summary,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: () {
                    _showFullExplanation(
                      result,
                    );
                  },
                  icon: const Icon(
                    Icons.info_outline,
                  ),
                  label: const Text(
                    'Why This Hotel',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor: yellow,
                    side: const BorderSide(
                      color: yellow,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child:
                    ElevatedButton.icon(
                  onPressed:
                      result.isAvailable &&
                              result
                                  .isAdminEnabled
                          ? () =>
                              _openHotel(
                                result,
                              )
                          : null,
                  icon: const Icon(
                    Icons.hotel_outlined,
                  ),
                  label: const Text(
                    'View Hotel',
                  ),
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        yellow,
                    foregroundColor:
                        Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reasonSection({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.take(5).map(
                (String item) =>
                    Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 3,
                  ),
                  child: Text(
                    '• $item',
                    style:
                        const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.grey,
        ),
        prefixIcon: Icon(
          icon,
          color: yellow,
        ),
        filled: true,
        fillColor: darkBackground,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dateCard({
    required String title,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: darkBackground,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: yellow,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatDate(date),
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterRow({
    required String title,
    required IconData icon,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int>
        onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkBackground,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: yellow,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: value > min
                ? () =>
                    onChanged(value - 1)
                : null,
            icon: const Icon(
              Icons.remove_circle,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: value < max
                ? () =>
                    onChanged(value + 1)
                : null,
            icon: const Icon(
              Icons.add_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool>
        onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      value: value,
      activeThumbColor: yellow,
      onChanged: onChanged,
    );
  }

  Widget _infoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _findRecommendations() async {
    final double? budget =
        double.tryParse(
      _budgetController.text.trim(),
    );

    if (_destinationController.text
        .trim()
        .isEmpty) {
      _setError(
        'Please enter a destination.',
      );
      return;
    }

    if (budget == null || budget < 0) {
      _setError(
        'Please enter a valid nightly budget.',
      );
      return;
    }

    if (!_checkOutDate
        .isAfter(_checkInDate)) {
      _setError(
        'Check-out date must be after check-in date.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _response = null;
    });

    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      final HotelRecommendationRequest request =
          HotelRecommendationRequest(
        userId: user?.uid ?? '',
        destination:
            _destinationController.text.trim(),
        checkInDate: _checkInDate,
        checkOutDate: _checkOutDate,
        adults: _adults,
        children: _children,
        rooms: _rooms,
        maxBudgetPerNight: budget,
        tripType: _tripType,
        needsParking: _needsParking,
        needsHotWater:
            _needsHotWater,
        needsFamilyRoom:
            _needsFamilyRoom,
        needsWiFi: _needsWiFi,
        needsRestaurant:
            _needsRestaurant,
        needsMountainView:
            _needsMountainView,
        needsRiverView:
            _needsRiverView,
      );

      final HotelRecommendationResponse response =
          await _service.recommendHotels(
        request: request,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _response = response;
      });
    } catch (error) {
      _setError(
        'Unable to load recommendations: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickCheckInDate() async {
    final DateTime today = DateTime.now();

    final DateTime? selected =
        await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime(
        today.year,
        today.month,
        today.day,
      ),
      lastDate: today.add(
        const Duration(days: 730),
      ),
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    setState(() {
      _checkInDate = selected;

      if (!_checkOutDate
          .isAfter(_checkInDate)) {
        _checkOutDate =
            _checkInDate.add(
          const Duration(days: 1),
        );
      }
    });
  }

  Future<void> _pickCheckOutDate() async {
    final DateTime firstDate =
        _checkInDate.add(
      const Duration(days: 1),
    );

    final DateTime? selected =
        await showDatePicker(
      context: context,
      initialDate:
          _checkOutDate.isAfter(
        _checkInDate,
      )
              ? _checkOutDate
              : firstDate,
      firstDate: firstDate,
      lastDate: _checkInDate.add(
        const Duration(days: 730),
      ),
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    setState(() {
      _checkOutDate = selected;
    });
  }

  void _showFullExplanation(
    HotelRecommendationResult result,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          darkBackground,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              18,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  result.hotelName,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${result.matchPercentage.toStringAsFixed(0)}% match',
                  style:
                      const TextStyle(
                    color: yellow,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _reasonSection(
                  title: 'Matched Reasons',
                  items:
                      result.matchedReasons,
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                if (result
                    .missingRequirements
                    .isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _reasonSection(
                    title:
                        'Missing or Warning',
                    items: result
                        .missingRequirements,
                    icon:
                        Icons.warning_amber,
                    color: Colors.orange,
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  result.summary,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width:
                      double.infinity,
                  child:
                      ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        sheetContext,
                      );
                    },
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          yellow,
                      foregroundColor:
                          Colors.black,
                    ),
                    child:
                        const Text(
                      'Close',
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

  void _openHotel(
    HotelRecommendationResult result,
  ) {
    final Map<String, dynamic> hotel =
        <String, dynamic>{
      'id': result.hotelId,
      'hotelId': result.hotelId,
      'name': result.hotelName,
      'hotelName': result.hotelName,
      'location': result.location,
      'category': result.category,
      'price': result.pricePerNight,
      'startingPrice':
          result.pricePerNight,
      'rating': result.rating,
      'averageRating':
          result.rating,
      'reviewCount':
          result.reviewCount,
      'rooms': result.availableRooms,
      'availableRooms':
          result.availableRooms,
      'amenities':
          result.amenities,
      'imageUrl': result.imageUrl,
      'coverImageUrl':
          result.imageUrl,
      'isActive':
          result.isAdminEnabled,
      'description': result.summary,
    };

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            HotelDetailScreen(
          hotel: hotel,
        ),
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:
            Colors.red.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              Colors.red.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _errorMessage,
              style:
                  const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: yellow,
            size: 46,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _setError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  String _formatDate(
    DateTime date,
  ) {
    final String day =
        date.day
            .toString()
            .padLeft(2, '0');

    final String month =
        date.month
            .toString()
            .padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _capitalize(
    String value,
  ) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() +
        value.substring(1);
  }

  String _money(
    num amount,
  ) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(
            r'\B(?=(\d{3})+(?!\d))',
          ),
          (Match match) => ',',
        );
  }
}
