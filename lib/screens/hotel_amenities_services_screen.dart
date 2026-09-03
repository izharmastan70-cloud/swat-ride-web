import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HotelAmenitiesServicesScreen extends StatefulWidget {
  const HotelAmenitiesServicesScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelAmenitiesServicesScreen> createState() =>
      _HotelAmenitiesServicesScreenState();
}

class _HotelAmenitiesServicesScreenState
    extends State<HotelAmenitiesServicesScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _searchText = '';
  String _selectedFilter = 'all';

  final Map<String, bool> _amenities = <String, bool>{
    'wifi': false,
    'parking': false,
    'hotWater': false,
    'heating': false,
    'airConditioning': false,
    'generator': false,
    'cctvSecurity': false,
    'lift': false,
    'wheelchairAccess': false,
    'familyRooms': false,
    'prayerArea': false,
    'fireSafety': false,
    'reception24Hours': false,
    'nonSmokingRooms': false,
    'petsAllowed': false,
    'swimmingPool': false,
    'gym': false,
  };

  final Map<String, bool> _services = <String, bool>{
    'breakfast': false,
    'lunch': false,
    'dinner': false,
    'roomService': false,
    'laundry': false,
    'airportPickup': false,
    'tourDesk': false,
    'carRental': false,
    'spa': false,
    'conferenceHall': false,
  };

  final Map<String, TextEditingController> _servicePrices =
      <String, TextEditingController>{};

  final Map<String, String> _amenityLabels = const <String, String>{
    'wifi': 'WiFi',
    'parking': 'Parking',
    'hotWater': 'Hot Water',
    'heating': 'Heating',
    'airConditioning': 'Air Conditioning',
    'generator': 'Generator / Backup Power',
    'cctvSecurity': 'CCTV Security',
    'lift': 'Lift',
    'wheelchairAccess': 'Wheelchair Access',
    'familyRooms': 'Family Rooms',
    'prayerArea': 'Prayer Area',
    'fireSafety': 'Fire Safety',
    'reception24Hours': '24/7 Reception',
    'nonSmokingRooms': 'Non-Smoking Rooms',
    'petsAllowed': 'Pets Allowed',
    'swimmingPool': 'Swimming Pool',
    'gym': 'Gym',
  };

  final Map<String, String> _serviceLabels = const <String, String>{
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'roomService': 'Room Service',
    'laundry': 'Laundry',
    'airportPickup': 'Airport Pickup',
    'tourDesk': 'Tour Desk',
    'carRental': 'Car Rental',
    'spa': 'Spa',
    'conferenceHall': 'Conference Hall',
  };

  final Map<String, String> _serviceUnits = const <String, String>{
    'breakfast': 'per person',
    'lunch': 'per person',
    'dinner': 'per person',
    'roomService': 'per order',
    'laundry': 'per item',
    'airportPickup': 'per trip',
    'tourDesk': 'per booking',
    'carRental': 'per day',
    'spa': 'per session',
    'conferenceHall': 'per event',
  };

  final Map<String, String> _categories = const <String, String>{
    'wifi': 'basic',
    'parking': 'basic',
    'hotWater': 'basic',
    'heating': 'basic',
    'airConditioning': 'premium',
    'generator': 'basic',
    'cctvSecurity': 'basic',
    'lift': 'premium',
    'wheelchairAccess': 'basic',
    'familyRooms': 'basic',
    'prayerArea': 'basic',
    'fireSafety': 'basic',
    'reception24Hours': 'premium',
    'nonSmokingRooms': 'basic',
    'petsAllowed': 'premium',
    'swimmingPool': 'luxury',
    'gym': 'luxury',
    'breakfast': 'basic',
    'lunch': 'premium',
    'dinner': 'premium',
    'roomService': 'premium',
    'laundry': 'premium',
    'airportPickup': 'luxury',
    'tourDesk': 'premium',
    'carRental': 'luxury',
    'spa': 'luxury',
    'conferenceHall': 'luxury',
  };

  final Map<String, IconData> _icons = const <String, IconData>{
    'wifi': Icons.wifi,
    'parking': Icons.local_parking,
    'hotWater': Icons.hot_tub_outlined,
    'heating': Icons.local_fire_department_outlined,
    'airConditioning': Icons.ac_unit,
    'generator': Icons.electrical_services_outlined,
    'cctvSecurity': Icons.videocam_outlined,
    'lift': Icons.elevator_outlined,
    'wheelchairAccess': Icons.accessible,
    'familyRooms': Icons.family_restroom,
    'prayerArea': Icons.mosque_outlined,
    'fireSafety': Icons.fire_extinguisher,
    'reception24Hours': Icons.support_agent,
    'nonSmokingRooms': Icons.smoke_free,
    'petsAllowed': Icons.pets_outlined,
    'swimmingPool': Icons.pool_outlined,
    'gym': Icons.fitness_center,
    'breakfast': Icons.breakfast_dining_outlined,
    'lunch': Icons.lunch_dining_outlined,
    'dinner': Icons.dinner_dining_outlined,
    'roomService': Icons.room_service_outlined,
    'laundry': Icons.local_laundry_service_outlined,
    'airportPickup': Icons.airport_shuttle_outlined,
    'tourDesk': Icons.travel_explore_outlined,
    'carRental': Icons.directions_car_filled_outlined,
    'spa': Icons.spa_outlined,
    'conferenceHall': Icons.meeting_room_outlined,
  };

  @override
  void initState() {
    super.initState();

    for (final String key in _services.keys) {
      _servicePrices[key] = TextEditingController();
    }

    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();

    for (final TextEditingController controller in _servicePrices.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> amenityKeys = _filteredAmenityKeys();
    final List<String> serviceKeys = _filteredServiceKeys();

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Amenities & Services',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: yellow,
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  28,
                ),
                children: [
                  _infoCard(),
                  const SizedBox(height: 16),
                  _searchBox(),
                  const SizedBox(height: 10),
                  _filterChips(),
                  const SizedBox(height: 20),
                  _summaryCard(),
                  const SizedBox(height: 22),
                  _sectionTitle(
                    title: 'Hotel Amenities',
                    subtitle:
                        'Free or built-in facilities shown on the hotel detail page.',
                  ),
                  const SizedBox(height: 12),
                  if (amenityKeys.isEmpty)
                    _emptySection('No amenities match your search.')
                  else
                    ...amenityKeys.map(_amenityTile),
                  const SizedBox(height: 22),
                  _sectionTitle(
                    title: 'Guest Services',
                    subtitle:
                        'Enable services and set an optional price. Empty price means free.',
                  ),
                  const SizedBox(height: 12),
                  if (serviceKeys.isEmpty)
                    _emptySection('No services match your search.')
                  else
                    ...serviceKeys.map(_serviceCard),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(
                              Icons.save_outlined,
                            ),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : 'Save Amenities & Services',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.09,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: yellow,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Only enabled items appear to customers. Prices are stored in Firestore, so the hotel can update them without a new app release.',
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

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (String value) {
        setState(() {
          _searchText = value;
        });
      },
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: 'Search amenity or service...',
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: yellow,
        ),
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
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _filterChips() {
    const List<String> filters = <String>[
      'all',
      'enabled',
      'basic',
      'premium',
      'luxury',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map(
          (String filter) {
            final bool selected = _selectedFilter == filter;

            return Padding(
              padding: const EdgeInsets.only(
                right: 8,
              ),
              child: ChoiceChip(
                selected: selected,
                label: Text(
                  _filterLabel(filter),
                ),
                selectedColor: yellow.withValues(
                  alpha: 0.25,
                ),
                checkmarkColor: yellow,
                labelStyle: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide(
                  color: selected
                      ? yellow
                      : Colors.white.withValues(
                          alpha: 0.06,
                        ),
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _summaryCard() {
    final int enabledAmenities = _amenities.values
        .where((bool value) => value)
        .length;

    final int enabledServices = _services.values
        .where((bool value) => value)
        .length;

    final int paidServices = _services.entries
        .where(
          (MapEntry<String, bool> entry) =>
              entry.value &&
              (_servicePrices[entry.key]?.text.trim().isNotEmpty ?? false),
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              icon: Icons.check_circle_outline,
              title: 'Amenities',
              value: '$enabledAmenities',
            ),
          ),
          Expanded(
            child: _summaryItem(
              icon: Icons.room_service_outlined,
              title: 'Services',
              value: '$enabledServices',
            ),
          ),
          Expanded(
            child: _summaryItem(
              icon: Icons.payments_outlined,
              title: 'Paid',
              value: '$paidServices',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: yellow,
          size: 23,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _amenityTile(
    String key,
  ) {
    final bool enabled = _amenities[key] ?? false;
    final String category = _categories[key] ?? 'basic';

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: enabled
              ? yellow.withValues(
                  alpha: 0.25,
                )
              : Colors.white.withValues(
                  alpha: 0.05,
                ),
        ),
      ),
      child: SwitchListTile(
        value: enabled,
        onChanged: (bool value) {
          setState(() {
            _amenities[key] = value;
          });
        },
        activeThumbColor: yellow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        secondary: Icon(
          _icons[key] ?? Icons.check_circle_outline,
          color: enabled ? yellow : Colors.grey,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _amenityLabels[key] ?? key,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _categoryBadge(category),
          ],
        ),
        subtitle: Text(
          enabled
              ? 'Visible to customers'
              : 'Hidden from customers',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _serviceCard(
    String key,
  ) {
    final bool enabled = _services[key] ?? false;
    final String category = _categories[key] ?? 'basic';
    final bool hasPrice =
        _servicePrices[key]?.text.trim().isNotEmpty ?? false;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? yellow.withValues(
                  alpha: 0.28,
                )
              : Colors.white.withValues(
                  alpha: 0.05,
                ),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: enabled,
            onChanged: (bool value) {
              setState(() {
                _services[key] = value;

                if (!value) {
                  _servicePrices[key]?.clear();
                }
              });
            },
            activeThumbColor: yellow,
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              _icons[key] ?? Icons.room_service_outlined,
              color: enabled ? yellow : Colors.grey,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    _serviceLabels[key] ?? key,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _categoryBadge(category),
              ],
            ),
            subtitle: Row(
              children: [
                Text(
                  enabled
                      ? 'Service available'
                      : 'Service unavailable',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
                if (enabled) ...[
                  const SizedBox(width: 8),
                  _priceBadge(hasPrice),
                ],
              ],
            ),
          ),
          if (enabled) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _servicePrices[key],
              onChanged: (_) {
                setState(() {});
              },
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                labelText: 'Price (optional)',
                hintText: 'Leave empty if free',
                prefixIcon: const Icon(
                  Icons.payments_outlined,
                  color: yellow,
                ),
                suffixText: _serviceUnits[key] ?? '',
                filled: true,
                fillColor: darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _categoryBadge(
    String category,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.11,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        _filterLabel(category),
        style: const TextStyle(
          color: yellow,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _priceBadge(
    bool hasPrice,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: hasPrice
            ? Colors.orange.withValues(alpha: 0.14)
            : Colors.green.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        hasPrice ? 'Paid' : 'Free',
        style: TextStyle(
          color: hasPrice ? Colors.orange : Colors.green,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _emptySection(
    String message,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.grey,
        ),
      ),
    );
  }

  List<String> _filteredAmenityKeys() {
    return _amenities.keys.where((String key) {
      return _matchesFilter(
        key: key,
        label: _amenityLabels[key] ?? key,
        enabled: _amenities[key] ?? false,
      );
    }).toList();
  }

  List<String> _filteredServiceKeys() {
    return _services.keys.where((String key) {
      return _matchesFilter(
        key: key,
        label: _serviceLabels[key] ?? key,
        enabled: _services[key] ?? false,
      );
    }).toList();
  }

  bool _matchesFilter({
    required String key,
    required String label,
    required bool enabled,
  }) {
    final String search = _searchText.trim().toLowerCase();

    final bool searchMatches =
        search.isEmpty || label.toLowerCase().contains(search);

    if (!searchMatches) {
      return false;
    }

    if (_selectedFilter == 'all') {
      return true;
    }

    if (_selectedFilter == 'enabled') {
      return enabled;
    }

    return _categories[key] == _selectedFilter;
  }

  Future<void> _loadData() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection('hotels')
              .doc(widget.hotelId)
              .get();

      final Map<String, dynamic> data =
          snapshot.data() ?? <String, dynamic>{};

      final Map<String, dynamic> amenitiesData =
          data['amenities'] is Map
              ? Map<String, dynamic>.from(
                  data['amenities'] as Map,
                )
              : <String, dynamic>{};

      for (final String key in _amenities.keys) {
        _amenities[key] = amenitiesData[key] == true;
      }

      final Map<String, dynamic> servicesData =
          data['services'] is Map
              ? Map<String, dynamic>.from(
                  data['services'] as Map,
                )
              : <String, dynamic>{};

      for (final String key in _services.keys) {
        final dynamic serviceValue = servicesData[key];

        if (serviceValue is Map) {
          final Map<String, dynamic> item =
              Map<String, dynamic>.from(
            serviceValue,
          );

          _services[key] = item['enabled'] == true;

          final dynamic price = item['price'];

          if (price is num) {
            _servicePrices[key]?.text =
                price.toDouble().toStringAsFixed(
                      price.toDouble() ==
                              price.toDouble().roundToDouble()
                          ? 0
                          : 2,
                    );
          }
        } else {
          _services[key] = serviceValue == true;
        }
      }
    } catch (error) {
      _showMessage(
        'Unable to load amenities and services: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveData() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in first.',
        isError: true,
      );
      return;
    }

    final Map<String, dynamic> servicesPayload =
        <String, dynamic>{};

    for (final String key in _services.keys) {
      final String priceText =
          _servicePrices[key]?.text.trim() ?? '';

      final double? price = priceText.isEmpty
          ? null
          : double.tryParse(priceText);

      if (priceText.isNotEmpty && price == null) {
        _showMessage(
          'Enter a valid price for ${_serviceLabels[key]}.',
          isError: true,
        );
        return;
      }

      if (price != null && price < 0) {
        _showMessage(
          'Price cannot be negative for ${_serviceLabels[key]}.',
          isError: true,
        );
        return;
      }

      servicesPayload[key] = <String, dynamic>{
        'enabled': _services[key] == true,
        'price': price,
        'unit': _serviceUnits[key],
        'category': _categories[key],
      };
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final List<String> enabledAmenities =
          _amenities.entries
              .where(
                (MapEntry<String, bool> entry) => entry.value,
              )
              .map(
                (MapEntry<String, bool> entry) =>
                    _amenityLabels[entry.key] ?? entry.key,
              )
              .toList();

      final List<Map<String, dynamic>> enabledServices =
          _services.entries
              .where(
                (MapEntry<String, bool> entry) => entry.value,
              )
              .map(
                (MapEntry<String, bool> entry) {
                  final String key = entry.key;
                  final String priceText =
                      _servicePrices[key]?.text.trim() ?? '';

                  return <String, dynamic>{
                    'key': key,
                    'name': _serviceLabels[key] ?? key,
                    'price': priceText.isEmpty
                        ? null
                        : double.tryParse(priceText),
                    'unit': _serviceUnits[key],
                    'category': _categories[key],
                  };
                },
              )
              .toList();

      await _firestore
          .collection('hotels')
          .doc(widget.hotelId)
          .set(
        <String, dynamic>{
          'amenities': Map<String, bool>.from(
            _amenities,
          ),
          'services': servicesPayload,
          'enabledAmenityLabels': enabledAmenities,
          'enabledServices': enabledServices,
          'lastUpdatedBy': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _showMessage(
        'Amenities and services updated successfully.',
      );
    } catch (error) {
      _showMessage(
        'Unable to save amenities and services: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _filterLabel(
    String filter,
  ) {
    switch (filter) {
      case 'all':
        return 'All';
      case 'enabled':
        return 'Enabled';
      case 'basic':
        return 'Basic';
      case 'premium':
        return 'Premium';
      case 'luxury':
        return 'Luxury';
      default:
        return filter;
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : darkCard,
        ),
      );
  }
}
