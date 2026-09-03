import 'package:flutter/material.dart';

class TourHotelSelectionScreen extends StatefulWidget {
  const TourHotelSelectionScreen({
    super.key,
    this.destinationName = '',
    this.startDate,
    this.endDate,
    this.guests = 1,
    this.initialHotelId = '',
  });

  final String destinationName;
  final DateTime? startDate;
  final DateTime? endDate;
  final int guests;
  final String initialHotelId;

  @override
  State<TourHotelSelectionScreen> createState() =>
      _TourHotelSelectionScreenState();
}

class _TourHotelSelectionScreenState
    extends State<TourHotelSelectionScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';
  String _selectedCategory = 'All';
  String _selectedHotelId = '';
  String _selectedRoomId = '';
  bool _breakfastOnly = false;
  bool _parkingOnly = false;
  bool _wifiOnly = false;

  static const List<String> _categories = <String>[
    'All',
    'Budget',
    'Standard',
    'Deluxe',
    'Family',
    'Luxury',
    'Resort',
    'Guest House',
  ];

  static const List<Map<String, dynamic>> _hotels =
      <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'hotel_kalam_view',
      'name': 'Kalam View Hotel',
      'location': 'Kalam, Swat',
      'category': 'Standard',
      'rating': 4.4,
      'distanceKm': 1.2,
      'phone': '03001234567',
      'amenities': <String>[
        'WiFi',
        'Parking',
        'Breakfast',
        'Heater',
        'Restaurant',
      ],
      'rooms': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'kalam_standard',
          'name': 'Standard Room',
          'capacity': 2,
          'beds': 1,
          'pricePerNight': 6500.0,
          'availableQuantity': 5,
        },
        <String, dynamic>{
          'id': 'kalam_family',
          'name': 'Family Room',
          'capacity': 5,
          'beds': 3,
          'pricePerNight': 11500.0,
          'availableQuantity': 3,
        },
      ],
    },
    <String, dynamic>{
      'id': 'hotel_malam_resort',
      'name': 'Malam Jabba Mountain Resort',
      'location': 'Malam Jabba, Swat',
      'category': 'Resort',
      'rating': 4.7,
      'distanceKm': 0.8,
      'phone': '03011234567',
      'amenities': <String>[
        'WiFi',
        'Parking',
        'Breakfast',
        'Restaurant',
        'Mountain View',
        'Heater',
      ],
      'rooms': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'malam_deluxe',
          'name': 'Deluxe Room',
          'capacity': 3,
          'beds': 2,
          'pricePerNight': 13500.0,
          'availableQuantity': 4,
        },
        <String, dynamic>{
          'id': 'malam_suite',
          'name': 'Mountain Suite',
          'capacity': 4,
          'beds': 2,
          'pricePerNight': 21000.0,
          'availableQuantity': 2,
        },
      ],
    },
    <String, dynamic>{
      'id': 'hotel_bahrain_family',
      'name': 'Bahrain Family Inn',
      'location': 'Bahrain, Swat',
      'category': 'Family',
      'rating': 4.2,
      'distanceKm': 1.7,
      'phone': '03021234567',
      'amenities': <String>[
        'WiFi',
        'Parking',
        'Breakfast',
        'Family Area',
      ],
      'rooms': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'bahrain_family',
          'name': 'Family Room',
          'capacity': 6,
          'beds': 4,
          'pricePerNight': 9800.0,
          'availableQuantity': 4,
        },
      ],
    },
    <String, dynamic>{
      'id': 'hotel_mingora_budget',
      'name': 'Mingora Budget Lodge',
      'location': 'Mingora, Swat',
      'category': 'Budget',
      'rating': 3.9,
      'distanceKm': 2.4,
      'phone': '03031234567',
      'amenities': <String>[
        'WiFi',
        'Parking',
      ],
      'rooms': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'mingora_budget',
          'name': 'Budget Room',
          'capacity': 2,
          'beds': 1,
          'pricePerNight': 3800.0,
          'availableQuantity': 8,
        },
        <String, dynamic>{
          'id': 'mingora_triple',
          'name': 'Triple Room',
          'capacity': 3,
          'beds': 3,
          'pricePerNight': 5200.0,
          'availableQuantity': 4,
        },
      ],
    },
    <String, dynamic>{
      'id': 'hotel_saidu_luxury',
      'name': 'Saidu Luxury Suites',
      'location': 'Saidu Sharif, Swat',
      'category': 'Luxury',
      'rating': 4.8,
      'distanceKm': 1.1,
      'phone': '03041234567',
      'amenities': <String>[
        'WiFi',
        'Parking',
        'Breakfast',
        'Restaurant',
        'AC',
        'Heater',
        'Room Service',
      ],
      'rooms': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'saidu_executive',
          'name': 'Executive Room',
          'capacity': 2,
          'beds': 1,
          'pricePerNight': 16000.0,
          'availableQuantity': 3,
        },
        <String, dynamic>{
          'id': 'saidu_suite',
          'name': 'Luxury Suite',
          'capacity': 4,
          'beds': 2,
          'pricePerNight': 26000.0,
          'availableQuantity': 2,
        },
      ],
    },
    <String, dynamic>{
      'id': 'hotel_guest_house',
      'name': 'Swat Valley Guest House',
      'location': 'Fizagat, Swat',
      'category': 'Guest House',
      'rating': 4.1,
      'distanceKm': 0.9,
      'phone': '03051234567',
      'amenities': <String>[
        'WiFi',
        'Parking',
        'Kitchen',
        'Family Area',
      ],
      'rooms': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'guest_double',
          'name': 'Double Room',
          'capacity': 2,
          'beds': 1,
          'pricePerNight': 5000.0,
          'availableQuantity': 6,
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedHotelId = widget.initialHotelId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _nights {
    if (widget.startDate == null || widget.endDate == null) {
      return 1;
    }

    final int value =
        widget.endDate!.difference(widget.startDate!).inDays;

    return value > 0 ? value : 1;
  }

  List<Map<String, dynamic>> get _visibleHotels {
    final String query = _searchText.trim().toLowerCase();

    return _hotels.where((hotel) {
      final String name =
          hotel['name'].toString().toLowerCase();
      final String location =
          hotel['location'].toString().toLowerCase();
      final String category =
          hotel['category'].toString();
      final List<String> amenities =
          List<String>.from(hotel['amenities'] as List);

      final bool categoryMatch =
          _selectedCategory == 'All' ||
              category == _selectedCategory;

      final bool searchMatch =
          query.isEmpty ||
              name.contains(query) ||
              location.contains(query) ||
              category.toLowerCase().contains(query);

      final bool breakfastMatch =
          !_breakfastOnly ||
              amenities.contains('Breakfast');
      final bool parkingMatch =
          !_parkingOnly ||
              amenities.contains('Parking');
      final bool wifiMatch =
          !_wifiOnly || amenities.contains('WiFi');

      return categoryMatch &&
          searchMatch &&
          breakfastMatch &&
          parkingMatch &&
          wifiMatch;
    }).toList();
  }

  Map<String, dynamic>? get _selectedHotel {
    for (final Map<String, dynamic> hotel in _hotels) {
      if (hotel['id'] == _selectedHotelId) {
        return hotel;
      }
    }
    return null;
  }

  Map<String, dynamic>? get _selectedRoom {
    final Map<String, dynamic>? hotel = _selectedHotel;
    if (hotel == null) return null;

    final List<Map<String, dynamic>> rooms =
        List<Map<String, dynamic>>.from(
      hotel['rooms'] as List,
    );

    for (final Map<String, dynamic> room in rooms) {
      if (room['id'] == _selectedRoomId) {
        return room;
      }
    }
    return null;
  }

  double get _estimatedHotelTotal {
    final Map<String, dynamic>? room = _selectedRoom;
    if (room == null) return 0;

    final double price =
        (room['pricePerNight'] as num).toDouble();

    return price * _nights;
  }

  @override
  Widget build(BuildContext context) {
    final double width =
        MediaQuery.sizeOf(context).width;
    final int columns =
        width >= 1050 ? 3 : width >= 700 ? 2 : 1;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Colors.white),
        title: const Text(
          'Select Tour Hotel',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          18,
                        ),
                        sliver: SliverList(
                          delegate:
                              SliverChildListDelegate(
                            <Widget>[
                              _tripSummary(),
                              const SizedBox(height: 18),
                              _searchBox(),
                              const SizedBox(height: 12),
                              _categoryChips(),
                              const SizedBox(height: 12),
                              _amenityFilters(),
                              const SizedBox(height: 18),
                              Text(
                                '${_visibleHotels.length} hotel(s) available',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      if (_visibleHotels.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _emptyState(),
                        )
                      else
                        SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            24,
                          ),
                          sliver: SliverGrid(
                            delegate:
                                SliverChildBuilderDelegate(
                              (context, index) {
                                return _hotelCard(
                                  _visibleHotels[index],
                                );
                              },
                              childCount:
                                  _visibleHotels.length,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio:
                                  width >= 700
                                      ? 0.92
                                      : 1.05,
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          28,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _bypassCard(),
                        ),
                      ),
                    ],
                  ),
                ),
                _bottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tripSummary() {
    final String destination =
        widget.destinationName.trim().isEmpty
            ? 'Selected Swat Destination'
            : widget.destinationName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(alpha: 0.24),
        ),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 12,
        children: <Widget>[
          _summaryItem(
            Icons.location_on,
            'Destination',
            destination,
          ),
          _summaryItem(
            Icons.calendar_month,
            'Stay',
            '$_nights night(s)',
          ),
          _summaryItem(
            Icons.groups,
            'Guests',
            '${widget.guests}',
          ),
          _summaryItem(
            Icons.payments_outlined,
            'Selected Total',
            _estimatedHotelTotal <= 0
                ? 'Select room'
                : 'PKR ${_money(_estimatedHotelTotal)}',
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    IconData icon,
    String title,
    String value,
  ) {
    return SizedBox(
      width: 210,
      child: Row(
        children: <Widget>[
          Icon(icon, color: yellow),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (String value) {
        setState(() {
          _searchText = value;
        });
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText:
            'Search hotel, location or category...',
        hintStyle:
            const TextStyle(color: Colors.grey),
        prefixIcon:
            const Icon(Icons.search, color: yellow),
        suffixIcon: _searchText.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchText = '';
                  });
                },
                icon: const Icon(
                  Icons.close,
                  color: Colors.grey,
                ),
              ),
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _categoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((String item) {
          final bool selected =
              _selectedCategory == item;

          return Padding(
            padding:
                const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text(item),
              selectedColor:
                  yellow.withValues(alpha: 0.25),
              checkmarkColor: yellow,
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedCategory = item;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _amenityFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilterChip(
          selected: _breakfastOnly,
          label: const Text('Breakfast'),
          selectedColor:
              yellow.withValues(alpha: 0.25),
          onSelected: (bool value) {
            setState(() {
              _breakfastOnly = value;
            });
          },
        ),
        FilterChip(
          selected: _parkingOnly,
          label: const Text('Parking'),
          selectedColor:
              yellow.withValues(alpha: 0.25),
          onSelected: (bool value) {
            setState(() {
              _parkingOnly = value;
            });
          },
        ),
        FilterChip(
          selected: _wifiOnly,
          label: const Text('WiFi'),
          selectedColor:
              yellow.withValues(alpha: 0.25),
          onSelected: (bool value) {
            setState(() {
              _wifiOnly = value;
            });
          },
        ),
      ],
    );
  }

  Widget _hotelCard(
    Map<String, dynamic> hotel,
  ) {
    final String hotelId =
        hotel['id'].toString();
    final bool selected =
        hotelId == _selectedHotelId;
    final List<String> amenities =
        List<String>.from(hotel['amenities'] as List);
    final List<Map<String, dynamic>> rooms =
        List<Map<String, dynamic>>.from(
      hotel['rooms'] as List,
    );

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: selected
              ? yellow
              : Colors.white.withValues(alpha: 0.06),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color:
                      yellow.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.hotel,
                  color: yellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      hotel['name'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hotel['location'].toString(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: selected
                    ? yellow
                    : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Icon(
                Icons.star,
                color: yellow,
                size: 17,
              ),
              const SizedBox(width: 4),
              Text(
                hotel['rating'].toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.near_me_outlined,
                color: Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${hotel['distanceKm']} km',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                hotel['category'].toString(),
                style: const TextStyle(
                  color: yellow,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: amenities
                .take(5)
                .map(
                  (String amenity) => Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.05,
                      ),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Text(
                      amenity,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 8,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Rooms',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              physics:
                  const NeverScrollableScrollPhysics(),
              children: rooms.map(
                (Map<String, dynamic> room) {
                  final String roomId =
                      room['id'].toString();
                  final bool roomSelected =
                      selected &&
                          roomId ==
                              _selectedRoomId;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedHotelId = hotelId;
                        _selectedRoomId = roomId;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(
                        bottom: 7,
                      ),
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: roomSelected
                            ? yellow.withValues(
                                alpha: 0.12,
                              )
                            : darkBackground,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: roomSelected
                              ? yellow
                              : Colors.white.withValues(
                                  alpha: 0.04,
                                ),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            roomSelected
                                ? Icons.check_circle
                                : Icons.bed_outlined,
                            color: roomSelected
                                ? yellow
                                : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: <Widget>[
                                Text(
                                  room['name']
                                      .toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Capacity ${room['capacity']} • ${room['availableQuantity']} available',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'PKR ${_money((room['pricePerNight'] as num).toDouble())}',
                            style: const TextStyle(
                              color: yellow,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final bool ready =
        _selectedHotel != null &&
            _selectedRoom != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16,
      ),
      decoration: const BoxDecoration(
        color: darkCard,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black54,
            blurRadius: 14,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    ready
                        ? _selectedHotel!['name']
                            .toString()
                        : 'No hotel selected',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ready
                        ? '${_selectedRoom!['name']} • PKR ${_money(_estimatedHotelTotal)} total'
                        : 'Select a hotel and room',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed:
                  ready ? _confirmSelection : null,
              icon: const Icon(
                Icons.arrow_forward,
              ),
              label: const Text('Continue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSelection() {
    final Map<String, dynamic>? hotel =
        _selectedHotel;
    final Map<String, dynamic>? room =
        _selectedRoom;

    if (hotel == null || room == null) {
      _message(
        'Please select a hotel and room.',
      );
      return;
    }

    final Map<String, dynamic> result =
        <String, dynamic>{
      'hotelId': hotel['id'],
      'hotelName': hotel['name'],
      'hotelCategory': hotel['category'],
      'hotelLocation': hotel['location'],
      'hotelPhone': hotel['phone'],
      'hotelAmenities': hotel['amenities'],
      'hotelRating': hotel['rating'],
      'hotelRoomId': room['id'],
      'roomName': room['name'],
      'roomCapacity': room['capacity'],
      'roomBeds': room['beds'],
      'roomPricePerNight':
          room['pricePerNight'],
      'availableQuantity':
          room['availableQuantity'],
      'nights': _nights,
      'hotelTotalAmount':
          _estimatedHotelTotal,
      'isTestingMode': true,
      'storageUploadUsed': false,
      'realPaymentProcessed': false,
    };

    Navigator.pop(
      context,
      result,
    );

    // =======================================================
    // REAL FIREBASE + BILLING CODE - KEEP COMMENTED
    // =======================================================
    //
    // Production flow:
    //
    // final hotelsSnapshot = await FirebaseFirestore.instance
    //     .collection('hotel_partner_applications')
    //     .where('applicationStatus', isEqualTo: 'approved')
    //     .where('isCustomerAccessEnabled', isEqualTo: true)
    //     .get();
    //
    // final roomsSnapshot = await FirebaseFirestore.instance
    //     .collection('hotel_rooms')
    //     .where('hotelId', isEqualTo: selectedHotelId)
    //     .where('isActive', isEqualTo: true)
    //     .get();
    //
    // Before continuing:
    // 1. Recheck room availability for tour dates.
    // 2. Load admin-controlled room/tour rates.
    // 3. Apply seasonal and holiday pricing.
    // 4. Reserve the selected room temporarily.
    // 5. Save hotelId and hotelRoomId in tour_bookings.
    // 6. Continue to vehicle and guide assignment.
    // 7. Process advance through Wallet/JazzCash/Easypaisa.
    //
    // Firebase Storage remains bypassed by project decision.
    // Real paid Maps and payment gateway remain commented.
    // =======================================================
  }

  Widget _bypassCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color:
              Colors.orange.withValues(alpha: 0.35),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            color: Colors.orange,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Testing hotel data is active. Firebase Storage, paid Maps and real payment remain bypassed. Production Firestore availability and pricing flow is preserved in comments.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.hotel_outlined,
              color: yellow,
              size: 52,
            ),
            const SizedBox(height: 14),
            const Text(
              'No hotel found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Change category, search or amenity filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchText = '';
                  _selectedCategory = 'All';
                  _breakfastOnly = false;
                  _parkingOnly = false;
                  _wifiOnly = false;
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  String _money(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(
            r'\B(?=(\d{3})+(?!\d))',
          ),
          (Match match) => ',',
        );
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: darkCard,
        ),
      );
  }
}
