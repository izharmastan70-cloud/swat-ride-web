import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HotelAdminRoomsScreen extends StatefulWidget {
  const HotelAdminRoomsScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelAdminRoomsScreen> createState() =>
      _HotelAdminRoomsScreenState();
}

class _HotelAdminRoomsScreenState
    extends State<HotelAdminRoomsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color background = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _filter = 'all';
  String _search = '';
  bool _working = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Hotel Room Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        onPressed: _working ? null : () => _openRoomForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Room'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('hotel_rooms')
            .where('hotelId', isEqualTo: widget.hotelId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: yellow),
            );
          }

          if (snapshot.hasError) {
            return _stateMessage(
              Icons.error_outline,
              'Unable to load rooms',
              snapshot.error.toString(),
            );
          }

          final rooms = snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          rooms.sort((a, b) {
            final aNo = a.data()['roomNumber']?.toString() ?? a.id;
            final bNo = b.data()['roomNumber']?.toString() ?? b.id;
            return aNo.compareTo(bNo);
          });

          final filtered = rooms.where((room) {
            final data = room.data();
            if (data['isActive'] == false) return false;

            final roomNumber =
                data['roomNumber']?.toString().toLowerCase() ?? '';
            final roomType =
                (data['roomType'] ?? data['roomName'] ?? data['name'] ?? '')
                    .toString()
                    .toLowerCase();
            final status = _status(data);

            final searchMatch = _search.isEmpty ||
                roomNumber.contains(_search.toLowerCase()) ||
                roomType.contains(_search.toLowerCase());

            final filterMatch = _filter == 'all' ||
                status == _filter ||
                (_filter == 'maintenance' && status == 'blocked');

            return searchMatch && filterMatch;
          }).toList();

          return RefreshIndicator(
            color: yellow,
            onRefresh: () async {
              await _firestore
                  .collection('hotel_rooms')
                  .where('hotelId', isEqualTo: widget.hotelId)
                  .get();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _summary(rooms),
                const SizedBox(height: 16),
                _searchBox(),
                const SizedBox(height: 12),
                _filters(),
                const SizedBox(height: 18),
                if (filtered.isEmpty)
                  _stateMessage(
                    Icons.meeting_room_outlined,
                    'No rooms found',
                    'Add a room or change the selected filter.',
                  )
                else
                  ...filtered.map(_roomCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summary(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms,
  ) {
    int available = 0;
    int occupied = 0;
    int housekeeping = 0;
    int maintenance = 0;

    for (final room in rooms) {
      if (room.data()['isActive'] == false) continue;

      switch (_status(room.data())) {
        case 'occupied':
          occupied++;
          break;
        case 'housekeeping':
          housekeeping++;
          break;
        case 'maintenance':
        case 'blocked':
          maintenance++;
          break;
        default:
          available++;
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.75,
      children: [
        _metric('Available', '$available', Icons.check_circle_outline,
            Colors.green),
        _metric('Occupied', '$occupied', Icons.hotel_outlined, Colors.blue),
        _metric('Housekeeping', '$housekeeping',
            Icons.cleaning_services_outlined, Colors.purple),
        _metric('Maintenance', '$maintenance', Icons.build_outlined,
            Colors.redAccent),
      ],
    );
  }

  Widget _metric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _search = value.trim()),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search room number or type...',
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: yellow),
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _filters() {
    const filters = [
      'all',
      'available',
      'occupied',
      'housekeeping',
      'maintenance',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((item) {
          final selected = _filter == item;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              selectedColor: yellow.withValues(alpha: 0.25),
              checkmarkColor: yellow,
              label: Text(_label(item)),
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (_) => setState(() => _filter = item),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _roomCard(
    QueryDocumentSnapshot<Map<String, dynamic>> room,
  ) {
    final data = room.data();
    final roomNumber = data['roomNumber']?.toString() ?? room.id;
    final roomType =
        (data['roomType'] ?? data['roomName'] ?? data['name'] ?? 'Room')
            .toString();
    final status = _status(data);
    final price = _number(
      data['pricePerNight'] ?? data['roomPrice'] ?? data['price'],
    );
    final adults = _integer(data['adults'], 2);
    final children = _integer(data['children'], 0);
    final beds = _integer(data['beds'], 1);
    final quantity = _integer(data['quantity'], 1);
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(_statusIcon(status), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room $roomNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      roomType,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _badge(status),
            ],
          ),
          const SizedBox(height: 12),
          _row('Adults', '$adults'),
          _row('Children', '$children'),
          _row('Beds', '$beds'),
          _row('Quantity', '$quantity room(s)'),
          _row(
            'Night Price',
            price <= 0 ? 'Not set' : 'PKR ${_money(price)}',
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _working ? null : () => _openRoomForm(room: room),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _working ? null : () => _changeStatus(room),
                  icon: const Icon(Icons.sync_alt),
                  label: const Text('Status'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _working ? null : () => _removeRoom(room),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openRoomForm({
    QueryDocumentSnapshot<Map<String, dynamic>>? room,
  }) async {
    final data = room?.data() ?? <String, dynamic>{};

    const roomTypes = <String>[
      'Standard Room',
      'Deluxe Room',
      'Executive Room',
      'Family Room',
      'Twin Room',
      'Triple Room',
      'Suite',
      'Honeymoon Suite',
      'Dormitory',
      'Cottage',
      'Villa',
    ];

    const availableAmenities = <String>[
      'Air Conditioning',
      'TV',
      'WiFi',
      'Balcony',
      'Mountain View',
      'Breakfast',
      'Kitchen',
      'Private Bathroom',
      'Mini Bar',
      'Parking',
      'Heater',
      'Room Service',
    ];

    final number = TextEditingController(
      text: data['roomNumber']?.toString() ?? '',
    );
    final adults = TextEditingController(
      text: _integer(data['adults'], 2).toString(),
    );
    final children = TextEditingController(
      text: _integer(data['children'], 0).toString(),
    );
    final beds = TextEditingController(
      text: _integer(data['beds'], 1).toString(),
    );
    final quantity = TextEditingController(
      text: _integer(data['quantity'], 1).toString(),
    );
    final basePrice = TextEditingController(
      text: _number(
        data['pricePerNight'] ?? data['roomPrice'] ?? data['price'],
      ).toStringAsFixed(0),
    );
    final weekendPrice = TextEditingController(
      text: _number(data['weekendPrice']).toStringAsFixed(0),
    );
    final seasonalPrice = TextEditingController(
      text: _number(data['seasonalPrice']).toStringAsFixed(0),
    );
    final holidayPrice = TextEditingController(
      text: _number(data['holidayPrice']).toStringAsFixed(0),
    );
    final extraBedPrice = TextEditingController(
      text: _number(data['extraBedPrice']).toStringAsFixed(0),
    );
    final discountPrice = TextEditingController(
      text: _number(data['discountPrice']).toStringAsFixed(0),
    );

    String selectedRoomType =
        (data['roomType'] ?? data['roomName'] ?? 'Standard Room').toString();
    if (!roomTypes.contains(selectedRoomType)) {
      selectedRoomType = 'Standard Room';
    }

    bool extraBedAllowed = data['extraBedAllowed'] == true;

    final selectedAmenities = <String>{
      ...((data['amenities'] is List)
          ? (data['amenities'] as List).map((e) => e.toString())
          : <String>[]),
    };

    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room == null ? 'Add Room' : 'Edit Room',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _field(number, 'Room Number', Icons.numbers),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRoomType,
                        dropdownColor: darkCard,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Room Type',
                          prefixIcon: const Icon(
                            Icons.meeting_room_outlined,
                            color: yellow,
                          ),
                          filled: true,
                          fillColor: background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: roomTypes
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() {
                            selectedRoomType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              adults,
                              'Adults',
                              Icons.person_outline,
                              number: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _field(
                              children,
                              'Children',
                              Icons.child_care_outlined,
                              number: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              beds,
                              'Beds',
                              Icons.bed_outlined,
                              number: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _field(
                              quantity,
                              'Quantity',
                              Icons.inventory_2_outlined,
                              number: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        value: extraBedAllowed,
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: yellow,
                        title: const Text(
                          'Extra bed allowed',
                          style: TextStyle(color: Colors.white),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            extraBedAllowed = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _field(
                        basePrice,
                        'Base Night Price',
                        Icons.payments_outlined,
                        number: true,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              weekendPrice,
                              'Weekend Price',
                              Icons.weekend_outlined,
                              number: true,
                              optional: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _field(
                              seasonalPrice,
                              'Seasonal Price',
                              Icons.calendar_month_outlined,
                              number: true,
                              optional: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              holidayPrice,
                              'Holiday Price',
                              Icons.celebration_outlined,
                              number: true,
                              optional: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _field(
                              extraBedPrice,
                              'Extra Bed Price',
                              Icons.bedroom_parent_outlined,
                              number: true,
                              optional: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _field(
                        discountPrice,
                        'Discount Price',
                        Icons.discount_outlined,
                        number: true,
                        optional: true,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Room Amenities',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableAmenities.map((amenity) {
                          final selected =
                              selectedAmenities.contains(amenity);
                          return FilterChip(
                            selected: selected,
                            selectedColor:
                                yellow.withValues(alpha: 0.25),
                            checkmarkColor: yellow,
                            label: Text(amenity),
                            onSelected: (value) {
                              setSheetState(() {
                                if (value) {
                                  selectedAmenities.add(amenity);
                                } else {
                                  selectedAmenities.remove(amenity);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: yellow,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            if (formKey.currentState?.validate() == true) {
                              Navigator.pop(context, true);
                            }
                          },
                          child: const Text('Save Room'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Room image upload remains bypassed until Firebase Storage is enabled.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true) {
      await _saveRoom(
        room: room,
        roomNumber: number.text.trim(),
        roomType: selectedRoomType,
        adults: int.parse(adults.text.trim()),
        children: int.parse(children.text.trim()),
        beds: int.parse(beds.text.trim()),
        quantity: int.parse(quantity.text.trim()),
        extraBedAllowed: extraBedAllowed,
        basePrice: double.parse(basePrice.text.trim()),
        weekendPrice: double.tryParse(weekendPrice.text.trim()) ?? 0,
        seasonalPrice: double.tryParse(seasonalPrice.text.trim()) ?? 0,
        holidayPrice: double.tryParse(holidayPrice.text.trim()) ?? 0,
        extraBedPrice: double.tryParse(extraBedPrice.text.trim()) ?? 0,
        discountPrice: double.tryParse(discountPrice.text.trim()) ?? 0,
        amenities: selectedAmenities.toList(),
      );
    }

    number.dispose();
    adults.dispose();
    children.dispose();
    beds.dispose();
    quantity.dispose();
    basePrice.dispose();
    weekendPrice.dispose();
    seasonalPrice.dispose();
    holidayPrice.dispose();
    extraBedPrice.dispose();
    discountPrice.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool number = false,
    bool optional = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      validator: optional
          ? null
          : (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              if (number && double.tryParse(value.trim()) == null) {
                return 'Invalid number';
              }
              return null;
            },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: yellow),
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _saveRoom({
    required QueryDocumentSnapshot<Map<String, dynamic>>? room,
    required String roomNumber,
    required String roomType,
    required int adults,
    required int children,
    required int beds,
    required int quantity,
    required bool extraBedAllowed,
    required double basePrice,
    required double weekendPrice,
    required double seasonalPrice,
    required double holidayPrice,
    required double extraBedPrice,
    required double discountPrice,
    required List<String> amenities,
  }) async {
    setState(() => _working = true);

    try {
      final reference =
          room?.reference ?? _firestore.collection('hotel_rooms').doc();

      await reference.set(
        <String, dynamic>{
          'roomId': reference.id,
          'hotelId': widget.hotelId,
          'roomNumber': roomNumber,
          'roomType': roomType,
          'roomName': roomType,
          'adults': adults,
          'children': children,
          'capacity': adults + children,
          'beds': beds,
          'quantity': quantity,
          'availableQuantity': quantity,
          'extraBedAllowed': extraBedAllowed,
          'pricePerNight': basePrice,
          'roomPrice': basePrice,
          'weekendPrice': weekendPrice,
          'seasonalPrice': seasonalPrice,
          'holidayPrice': holidayPrice,
          'extraBedPrice': extraBedPrice,
          'discountPrice': discountPrice,
          'amenities': amenities,
          'manualStatus':
              room?.data()['manualStatus']?.toString() ?? 'available',
          'housekeepingStatus':
              room?.data()['housekeepingStatus']?.toString() ?? 'ready',
          'images': room?.data()['images'] ?? <String>[],
          'isActive': true,
          'storageUploadUsed': false,
          'createdAt':
              room?.data()['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _message(room == null
          ? 'Room added successfully.'
          : 'Room updated successfully.');
    } catch (error) {
      _message('Unable to save room: $error', error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _changeStatus(
    QueryDocumentSnapshot<Map<String, dynamic>> room,
  ) async {
    const statuses = [
      'available',
      'occupied',
      'housekeeping',
      'maintenance',
      'blocked',
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: darkCard,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses
              .map(
                (status) => ListTile(
                  leading: Icon(
                    _statusIcon(status),
                    color: _statusColor(status),
                  ),
                  title: Text(_label(status)),
                  onTap: () => Navigator.pop(context, status),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (selected == null) return;

    setState(() => _working = true);

    try {
      await room.reference.set(
        <String, dynamic>{
          'manualStatus': selected,
          if (selected == 'housekeeping')
            'housekeepingStatus': 'dirty',
          if (selected == 'available') 'housekeepingStatus': 'ready',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _message('Room status updated.');
    } catch (error) {
      _message('Unable to update status: $error', error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _removeRoom(
    QueryDocumentSnapshot<Map<String, dynamic>> room,
  ) async {
    if (_status(room.data()) == 'occupied') {
      _message('Occupied room cannot be removed.', error: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkCard,
        title: const Text(
          'Remove Room',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'The room will be hidden, while old booking history remains saved.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _working = true);

    try {
      await room.reference.set(
        <String, dynamic>{
          'isActive': false,
          'manualStatus': 'blocked',
          'deletedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      _message('Room removed successfully.');
    } catch (error) {
      _message('Unable to remove room: $error', error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _status(Map<String, dynamic> data) {
    return data['manualStatus']?.toString() ??
        data['status']?.toString() ??
        'available';
  }

  Widget _badge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stateMessage(IconData icon, String title, String message) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: yellow, size: 44),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'occupied':
        return Colors.blue;
      case 'housekeeping':
        return Colors.purple;
      case 'maintenance':
      case 'blocked':
        return Colors.redAccent;
      default:
        return yellow;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'available':
        return Icons.check_circle_outline;
      case 'occupied':
        return Icons.hotel_outlined;
      case 'housekeeping':
        return Icons.cleaning_services_outlined;
      case 'maintenance':
        return Icons.build_outlined;
      case 'blocked':
        return Icons.block_outlined;
      default:
        return Icons.meeting_room_outlined;
    }
  }

  String _label(String status) {
    if (status.isEmpty) return status;
    return status[0].toUpperCase() + status.substring(1);
  }

  int _integer(dynamic value, int fallback) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: error ? Colors.red : darkCard,
        ),
      );
  }
}
