import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'hotel_booking_screen.dart';

class HotelRoomSelectionScreen extends StatefulWidget {
  const HotelRoomSelectionScreen({
    super.key,
    required this.hotel,
  });

  final Map<String, dynamic> hotel;

  @override
  State<HotelRoomSelectionScreen> createState() =>
      _HotelRoomSelectionScreenState();
}

class _HotelRoomSelectionScreenState
    extends State<HotelRoomSelectionScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  int selectedRoomIndex = 0;

  // =========================================================
  // REAL FIRESTORE ROOM DATA
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> get _roomStream {
    final String hotelId =
        widget.hotel['hotelId']?.toString().trim().isNotEmpty == true
            ? widget.hotel['hotelId'].toString().trim()
            : widget.hotel['id']?.toString().trim() ?? '';

    return FirebaseFirestore.instance
        .collection('hotel_rooms')
        .where('hotelId', isEqualTo: hotelId)
        .snapshots();
  }

  List<Map<String, dynamic>> _activeRooms(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List<Map<String, dynamic>> rooms = snapshot.docs
        .where((doc) => doc.data()['isActive'] != false)
        .map((doc) {
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(doc.data());

          final String roomId =
              data['roomId']?.toString().trim().isNotEmpty == true
                  ? data['roomId'].toString().trim()
                  : doc.id;

          final String roomType =
              data['roomType']?.toString().trim().isNotEmpty == true
                  ? data['roomType'].toString().trim()
                  : data['roomName']?.toString().trim().isNotEmpty == true
                      ? data['roomName'].toString().trim()
                      : 'Room';

          final int adults = _readInt(
            data['adults'],
            fallback: 2,
          );
          final int children = _readInt(
            data['children'],
            fallback: 0,
          );
          final int beds = _readInt(
            data['beds'],
            fallback: 1,
          );
          final int quantity = _readInt(
            data['availableQuantity'] ?? data['quantity'],
            fallback: 1,
          );

          return <String, dynamic>{
            ...data,
            'id': roomId,
            'roomId': roomId,
            'name': roomType,
            'roomName': roomType,
            'roomType': roomType,
            'subtitle': data['description']?.toString().trim().isNotEmpty == true
                ? data['description'].toString().trim()
                : 'Comfortable room for your stay.',
            'pricePerNight': _readDouble(
              data['pricePerNight'] ??
                  data['roomPrice'] ??
                  data['price'],
            ),
            'adults': adults,
            'children': children,
            'capacity': _readInt(
              data['capacity'],
              fallback: adults + children,
            ),
            'beds': beds,
            'quantity': quantity,
            'availableQuantity': quantity,
            'available': quantity > 0 &&
                data['manualStatus']?.toString() != 'blocked',
            'isActive': data['isActive'] != false,
          };
        })
        .toList();

    rooms.sort((a, b) {
      final String aType = a['roomType']?.toString() ?? '';
      final String bType = b['roomType']?.toString() ?? '';
      return aType.compareTo(bType);
    });

    return rooms;
  }

  IconData _roomIcon(String roomType) {
    final String value = roomType.toLowerCase();

    if (value.contains('suite')) {
      return Icons.apartment;
    }

    if (value.contains('family')) {
      return Icons.family_restroom;
    }

    if (value.contains('deluxe') || value.contains('king')) {
      return Icons.king_bed;
    }

    return Icons.bed;
  }

  String _guestLabel(
    Map<String, dynamic> room,
  ) {
    final int adults = _readInt(
      room['adults'],
      fallback: 2,
    );
    final int children = _readInt(
      room['children'],
      fallback: 0,
    );

    if (children > 0) {
      return '$adults adult(s), $children child(ren)';
    }

    return '$adults adult(s)';
  }

  String _bedLabel(
    Map<String, dynamic> room,
  ) {
    final int beds = _readInt(
      room['beds'],
      fallback: 1,
    );

    return '$beds bed(s)';
  }

  int _readInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  double _readDouble(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  @override
  Widget build(BuildContext context) {
    final String hotelName =
        widget.hotel['name']?.toString().trim().isNotEmpty == true
            ? widget.hotel['name'].toString()
            : widget.hotel['hotelName']?.toString().trim().isNotEmpty == true
                ? widget.hotel['hotelName'].toString()
                : 'Hotel';

    final String location =
        widget.hotel['location']?.toString().trim().isNotEmpty == true
            ? widget.hotel['location'].toString()
            : 'Swat';

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Select Room',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _roomStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: yellow,
              ),
            );
          }

          if (snapshot.hasError) {
            return _messageState(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to Load Rooms',
              message: snapshot.error.toString(),
            );
          }

          final List<Map<String, dynamic>> rooms =
              snapshot.hasData
                  ? _activeRooms(snapshot.data!)
                  : <Map<String, dynamic>>[];

          if (rooms.isEmpty) {
            return _messageState(
              icon: Icons.meeting_room_outlined,
              title: 'No Rooms Available',
              message:
                  'This hotel does not have any active rooms available yet.',
            );
          }

          if (selectedRoomIndex >= rooms.length) {
            selectedRoomIndex = 0;
          }

          final Map<String, dynamic> selectedRoom =
              rooms[selectedRoomIndex];

          final double selectedPrice = _readDouble(
            selectedRoom['pricePerNight'] ??
                selectedRoom['roomPrice'] ??
                selectedRoom['price'],
          );

          return SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: 0.05,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: yellow.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hotel,
                          color: yellow,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              hotelName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: yellow,
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Choose Your Room',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select an active room configured by the hotel admin.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final Map<String, dynamic> room =
                          rooms[index];

                      final bool isSelected =
                          selectedRoomIndex == index;

                      final bool isAvailable =
                          room['available'] == true;

                      final double roomPrice =
                          _readDouble(
                        room['pricePerNight'] ??
                            room['roomPrice'] ??
                            room['price'],
                      );

                      final String roomName =
                          room['roomName']?.toString() ??
                              room['roomType']?.toString() ??
                              room['name']?.toString() ??
                              'Room';

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 14,
                        ),
                        child: InkWell(
                          onTap: isAvailable
                              ? () {
                                  setState(() {
                                    selectedRoomIndex = index;
                                  });
                                }
                              : () {
                                  _showMessage(
                                    'This room is currently unavailable.',
                                  );
                                },
                          borderRadius:
                              BorderRadius.circular(18),
                          child: Container(
                            padding:
                                const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: darkCard,
                              borderRadius:
                                  BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? yellow
                                    : Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                width:
                                    isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            yellow.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(14),
                                      ),
                                      child: Icon(
                                        _roomIcon(
                                          roomName,
                                        ),
                                        color: yellow,
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  roomName,
                                                  style:
                                                      const TextStyle(
                                                    color:
                                                        Colors.white,
                                                    fontSize:
                                                        17,
                                                    fontWeight:
                                                        FontWeight
                                                            .bold,
                                                  ),
                                                ),
                                              ),
                                              if (!isAvailable)
                                                Container(
                                                  padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal:
                                                        8,
                                                    vertical: 4,
                                                  ),
                                                  decoration:
                                                      BoxDecoration(
                                                    color: Colors
                                                        .red
                                                        .withValues(
                                                      alpha:
                                                          0.15,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                      7,
                                                    ),
                                                  ),
                                                  child:
                                                      const Text(
                                                    'Unavailable',
                                                    style:
                                                        TextStyle(
                                                      color: Colors
                                                          .redAccent,
                                                      fontSize:
                                                          10,
                                                      fontWeight:
                                                          FontWeight
                                                              .bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(
                                              height: 6),
                                          Text(
                                            room['subtitle']
                                                    ?.toString() ??
                                                'Comfortable room for your stay.',
                                            style:
                                                const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isSelected
                                          ? Icons
                                              .radio_button_checked
                                          : Icons
                                              .radio_button_off,
                                      color: isSelected
                                          ? yellow
                                          : Colors.grey,
                                      size: 25,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _roomInfo(
                                        icon: Icons.people,
                                        text:
                                            _guestLabel(room),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _roomInfo(
                                        icon: Icons.bed,
                                        text:
                                            _bedLabel(room),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _roomInfo(
                                  icon:
                                      Icons.inventory_2_outlined,
                                  text:
                                      '${_readInt(room['availableQuantity'] ?? room['quantity'], fallback: 1)} room(s) available',
                                ),
                                const SizedBox(height: 14),
                                const Divider(
                                  color: Colors.white12,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        roomPrice > 0
                                            ? 'Rs. ${_formatPrice(roomPrice.round())} / night'
                                            : 'Price on request',
                                        style:
                                            const TextStyle(
                                          color: yellow,
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Text(
                                        'Selected',
                                        style: TextStyle(
                                          color: yellow,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Selected room price',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              selectedPrice > 0
                                  ? 'Rs. ${_formatPrice(selectedPrice.round())} / night'
                                  : 'Price on request',
                              style: const TextStyle(
                                color: yellow,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                selectedRoom['available'] == true
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder:
                                                (context) {
                                              return HotelBookingScreen(
                                                hotel:
                                                    widget.hotel,
                                                room:
                                                    selectedRoom,
                                                roomPrice:
                                                    selectedPrice
                                                        .round(),
                                                rooms: rooms,
                                              );
                                            },
                                          ),
                                        );
                                      }
                                    : null,
                            icon: const Icon(
                              Icons.arrow_forward,
                              color: Colors.black,
                            ),
                            label: Text(
                              selectedPrice > 0
                                  ? 'Continue - Rs. ${_formatPrice(selectedPrice.round())} / Night'
                                  : 'Continue to Booking',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor: yellow,
                              foregroundColor:
                                  Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 16,
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
                        const SizedBox(height: 8),
                        const Text(
                          'Rooms, capacity and pricing are loaded from Firestore. Room images remain on local placeholders until Firebase Storage billing is enabled.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: yellow,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ROOM INFORMATION
  // =========================================================
  Widget _roomInfo({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: yellow,
          size: 17,
        ),

        const SizedBox(width: 5),

        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PRICE FORMATTING
  // =========================================================
  String _formatPrice(int price) {
    final String priceText = price.toString();
    final StringBuffer result = StringBuffer();

    for (int index = 0;
        index < priceText.length;
        index++) {
      final int remaining =
          priceText.length - index;

      result.write(priceText[index]);

      if (remaining > 1 && remaining % 3 == 1) {
        result.write(',');
      }
    }

    return result.toString();
  }

  // =========================================================
  // MESSAGE
  // =========================================================
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: darkCard,
          duration: const Duration(
            seconds: 3,
          ),
        ),
      );
  }
}