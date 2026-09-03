import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HotelWalkInBookingScreen extends StatefulWidget {
  const HotelWalkInBookingScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelWalkInBookingScreen> createState() =>
      _HotelWalkInBookingScreenState();
}

class _HotelWalkInBookingScreenState
    extends State<HotelWalkInBookingScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _guestNameController =
      TextEditingController();

  final TextEditingController _guestPhoneController =
      TextEditingController();

  final TextEditingController _guestCnicController =
      TextEditingController();

  final TextEditingController _notesController =
      TextEditingController();

  final TextEditingController _advanceController =
      TextEditingController();

  DateTime _checkInDate = DateTime.now();
  DateTime _checkOutDate = DateTime.now().add(
    const Duration(days: 1),
  );

  String _selectedPaymentMethod = 'Cash';
  String _selectedPaymentStatus = 'cash_pending';

  QueryDocumentSnapshot<Map<String, dynamic>>?
      _selectedRoom;

  int _guestCount = 1;
  int _roomCount = 1;

  bool _isSaving = false;

  final List<String> _paymentMethods =
      const <String>[
    'Cash',
    'JazzCash',
    'Easypaisa',
    'Wallet',
    'Bank Transfer',
  ];

  int get _totalNights {
    final int value =
        _checkOutDate.difference(_checkInDate).inDays;

    return value <= 0 ? 1 : value;
  }

  double get _roomPrice {
    final Map<String, dynamic>? data =
        _selectedRoom?.data();

    if (data == null) {
      return 0;
    }

    return _readNumber(
      data['pricePerNight'] ??
          data['price'] ??
          data['roomPrice'],
    );
  }

  double get _totalAmount =>
      _roomPrice * _roomCount * _totalNights;

  double get _advanceAmount =>
      _readNumber(_advanceController.text);

  double get _remainingAmount {
    final double value =
        _totalAmount - _advanceAmount;

    return value < 0 ? 0 : value;
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _guestCnicController.dispose();
    _notesController.dispose();
    _advanceController.dispose();
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
          'Walk-in Booking',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              30,
            ),
            children: [
              _noticeCard(),

              const SizedBox(height: 18),

              _sectionTitle('Guest Details'),

              const SizedBox(height: 12),

              _textField(
                controller:
                    _guestNameController,
                label: 'Guest Full Name',
                icon: Icons.person_outline,
                validator: _required,
              ),

              const SizedBox(height: 12),

              _textField(
                controller:
                    _guestPhoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType:
                    TextInputType.phone,
                validator: _phoneValidator,
              ),

              const SizedBox(height: 12),

              _textField(
                controller:
                    _guestCnicController,
                label: 'CNIC Number',
                icon: Icons.badge_outlined,
                keyboardType:
                    TextInputType.number,
                validator: _required,
              ),

              const SizedBox(height: 22),

              _sectionTitle('Stay Details'),

              const SizedBox(height: 12),

              _dateCard(
                title: 'Check-in Date',
                date: _checkInDate,
                icon: Icons.login,
                onTap: _pickCheckInDate,
              ),

              const SizedBox(height: 12),

              _dateCard(
                title: 'Check-out Date',
                date: _checkOutDate,
                icon: Icons.logout,
                onTap: _pickCheckOutDate,
              ),

              const SizedBox(height: 12),

              _counterCard(
                title: 'Guests',
                icon: Icons.people_outline,
                value: _guestCount,
                min: 1,
                max: 20,
                onChanged: (value) {
                  setState(() {
                    _guestCount = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              _counterCard(
                title: 'Rooms',
                icon:
                    Icons.meeting_room_outlined,
                value: _roomCount,
                min: 1,
                max: 10,
                onChanged: (value) {
                  setState(() {
                    _roomCount = value;
                  });
                },
              ),

              const SizedBox(height: 22),

              _sectionTitle('Select Room'),

              const SizedBox(height: 12),

              _roomSelector(),

              const SizedBox(height: 22),

              _sectionTitle('Payment'),

              const SizedBox(height: 12),

              _paymentSelector(),

              const SizedBox(height: 12),

              _textField(
                controller:
                    _advanceController,
                label:
                    'Advance Received (optional)',
                icon: Icons.payments_outlined,
                keyboardType:
                    TextInputType.number,
                onChanged: (_) {
                  setState(() {});
                },
              ),

              const SizedBox(height: 12),

              _textField(
                controller: _notesController,
                label:
                    'Reception Notes (optional)',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 22),

              _summaryCard(),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : _saveWalkInBooking,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : 'Create Walk-in Booking',
                    style: const TextStyle(
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
                  ),
                ),
              ),

              const SizedBox(height: 14),

              _paymentBypassNotice(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roomSelector() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('hotel_rooms')
          .where(
            'hotelId',
            isEqualTo: widget.hotelId,
          )
          .snapshots(),
      builder: (
        context,
        AsyncSnapshot<
                QuerySnapshot<
                    Map<String, dynamic>>>
            snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: yellow,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _messageCard(
            icon: Icons.error_outline,
            title: 'Unable to Load Rooms',
            message:
                snapshot.error.toString(),
          );
        }

        final List<
                QueryDocumentSnapshot<
                    Map<String, dynamic>>>
            rooms = snapshot.data?.docs ??
                <QueryDocumentSnapshot<
                    Map<String, dynamic>>>[];

        final List<
                QueryDocumentSnapshot<
                    Map<String, dynamic>>>
            availableRooms =
            rooms.where(
          (room) {
            final Map<String, dynamic> data =
                room.data();

            final String manualStatus =
                data['manualStatus']
                        ?.toString() ??
                    data['status']
                        ?.toString() ??
                    'available';

            final String housekeepingStatus =
                data['housekeepingStatus']
                        ?.toString() ??
                    'ready';

            return manualStatus !=
                    'maintenance' &&
                manualStatus != 'blocked' &&
                housekeepingStatus !=
                    'dirty' &&
                housekeepingStatus !=
                    'cleaning';
          },
        ).toList();

        if (availableRooms.isEmpty) {
          return _messageCard(
            icon: Icons.meeting_room_outlined,
            title: 'No Rooms Available',
            message:
                'No room is currently ready for walk-in booking.',
          );
        }

        return Column(
          children: availableRooms.map(
            (room) {
              final Map<String, dynamic> data =
                  room.data();

              final String roomNumber =
                  data['roomNumber']
                          ?.toString() ??
                      room.id;

              final String roomName =
                  data['name']?.toString() ??
                      data['roomName']
                          ?.toString() ??
                      data['roomType']
                          ?.toString() ??
                      'Room';

              final double price =
                  _readNumber(
                data['pricePerNight'] ??
                    data['price'] ??
                    data['roomPrice'],
              );

              final bool selected =
                  _selectedRoom?.id ==
                      room.id;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedRoom = room;
                  });
                },
                borderRadius:
                    BorderRadius.circular(15),
                child: Container(
                  margin:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius:
                        BorderRadius.circular(15),
                    border: Border.all(
                      color: selected
                          ? yellow
                          : Colors.white
                              .withValues(
                                alpha: 0.05,
                              ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons
                                .radio_button_checked
                            : Icons
                                .radio_button_off,
                        color: selected
                            ? yellow
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              'Room $roomNumber',
                              style:
                                  const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              roomName,
                              style:
                                  const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        price <= 0
                            ? 'Price not set'
                            : 'PKR ${_formatMoney(price)}',
                        style: TextStyle(
                          color: price <= 0
                              ? Colors.grey
                              : yellow,
                          fontSize: 11,
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
        );
      },
    );
  }

  Widget _paymentSelector() {
    return Column(
      children: _paymentMethods.map(
        (method) {
          final bool selected =
              _selectedPaymentMethod ==
                  method;

          return Container(
            margin: const EdgeInsets.only(
              bottom: 9,
            ),
            decoration: BoxDecoration(
              color: darkCard,
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? yellow
                    : Colors.white.withValues(
                        alpha: 0.05,
                      ),
              ),
            ),
            child: RadioGroup<String>(
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedPaymentMethod = value;

                _selectedPaymentStatus =
                    value == 'Cash'
                        ? 'cash_pending'
                        : 'testing_bypassed';
              });
            },
            child: RadioListTile<String>(
              value: method,
              activeColor: yellow,
              title: Text(
                method,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          );
        },
      ).toList(),
    );
  }

  Widget _summaryCard() {
    final String roomName =
        _selectedRoom?.data()['name']
                ?.toString() ??
            _selectedRoom
                ?.data()['roomName']
                ?.toString() ??
            _selectedRoom
                ?.data()['roomType']
                ?.toString() ??
            'Not selected';

    return Container(
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
      child: Column(
        children: [
          _detailRow(
            'Room',
            roomName,
          ),
          _detailRow(
            'Stay',
            '${_formatDate(_checkInDate)} - ${_formatDate(_checkOutDate)}',
          ),
          _detailRow(
            'Nights',
            '$_totalNights',
          ),
          _detailRow(
            'Guests / Rooms',
            '$_guestCount / $_roomCount',
          ),
          _detailRow(
            'Payment',
            _selectedPaymentMethod,
          ),
          _detailRow(
            'Advance',
            'PKR ${_formatMoney(_advanceAmount)}',
          ),
          _detailRow(
            'Remaining',
            'PKR ${_formatMoney(_remainingAmount)}',
          ),
          const Divider(
            color: Colors.white12,
            height: 22,
          ),
          _detailRow(
            'Total Amount',
            _totalAmount <= 0
                ? 'Not available'
                : 'PKR ${_formatMoney(_totalAmount)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Future<void> _saveWalkInBooking() async {
    if (_formKey.currentState?.validate() !=
        true) {
      return;
    }

    if (_selectedRoom == null) {
      _showMessage(
        'Please select a room.',
        isError: true,
      );
      return;
    }

    if (_checkOutDate
        .isBefore(_checkInDate)) {
      _showMessage(
        'Check-out date must be after check-in date.',
        isError: true,
      );
      return;
    }

    if (_advanceAmount >
        _totalAmount) {
      _showMessage(
        'Advance amount cannot exceed total amount.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final Map<String, dynamic> roomData =
          _selectedRoom!.data();

      final String roomId =
          roomData['roomId']?.toString() ??
              _selectedRoom!.id;

      final String roomName =
          roomData['name']?.toString() ??
              roomData['roomName']
                  ?.toString() ??
              roomData['roomType']
                  ?.toString() ??
              'Room';

      final String roomNumber =
          roomData['roomNumber']
                  ?.toString() ??
              roomId;

      final DocumentReference<
              Map<String, dynamic>>
          bookingReference = _firestore
              .collection('hotel_bookings')
              .doc();

      final WriteBatch batch =
          _firestore.batch();

      batch.set(
        bookingReference,
        <String, dynamic>{
          'bookingId':
              bookingReference.id,
          'hotelId': widget.hotelId,
          'roomId': roomId,
          'roomName': roomName,
          'roomNumber': roomNumber,
          'guestName':
              _guestNameController.text.trim(),
          'guestPhone':
              _guestPhoneController.text.trim(),
          'guestCnic':
              _guestCnicController.text.trim(),
          'notes':
              _notesController.text.trim(),
          'checkIn': Timestamp.fromDate(
            DateTime(
              _checkInDate.year,
              _checkInDate.month,
              _checkInDate.day,
            ),
          ),
          'checkOut': Timestamp.fromDate(
            DateTime(
              _checkOutDate.year,
              _checkOutDate.month,
              _checkOutDate.day,
            ),
          ),
          'hotelCheckOutHour': 12,
          'hotelCheckOutMinute': 0,
          'nights': _totalNights,
          'guests': _guestCount,
          'rooms': _roomCount,
          'roomPrice': _roomPrice,
          'totalAmount': _totalAmount,
          'advanceAmount':
              _advanceAmount,
          'remainingAmount':
              _remainingAmount,
          'paymentMethod':
              _selectedPaymentMethod,
          'paymentStatus':
              _selectedPaymentStatus,
          'bookingStatus': 'confirmed',
          'bookingSource':
              'hotel_walk_in',
          'isWalkInBooking': true,
          'createdByRole':
              'hotel_reception',
          'realPaymentProcessed': false,
          'isTestingMode': true,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        _firestore
            .collection('hotel_rooms')
            .doc(roomId),
        <String, dynamic>{
          'manualStatus': 'occupied',
          'currentBookingId':
              bookingReference.id,
          'currentGuestName':
              _guestNameController.text.trim(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final DocumentReference<
              Map<String, dynamic>>
          transactionReference =
          _firestore
              .collection(
                'hotel_wallet_transactions',
              )
              .doc();

      batch.set(
        transactionReference,
        <String, dynamic>{
          'transactionId':
              transactionReference.id,
          'hotelId': widget.hotelId,
          'bookingId':
              bookingReference.id,
          'type':
              _advanceAmount > 0
                  ? 'walk_in_advance'
                  : 'walk_in_booking',
          'amount': _advanceAmount,
          'paymentMethod':
              _selectedPaymentMethod,
          'status':
              _advanceAmount > 0
                  ? 'recorded'
                  : 'pending',
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: darkCard,
            title: const Text(
              'Walk-in Booking Created',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Booking ${bookingReference.id} has been created and Room $roomNumber is marked occupied.',
              style: const TextStyle(
                color: Colors.grey,
                height: 1.45,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                  Navigator.pop(
                    context,
                    true,
                  );
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor:
                      Colors.black,
                ),
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      _showMessage(
        'Unable to create walk-in booking: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }

    // Real online payment verification and automatic
    // commission settlement remain bypassed.
  }

  Future<void> _pickCheckInDate() async {
    final DateTime? selected =
        await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 1),
      ),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (selected == null || !mounted) {
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
      initialDate: _checkOutDate,
      firstDate: firstDate,
      lastDate: _checkInDate.add(
        const Duration(days: 365),
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _checkOutDate = selected;
    });
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
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
        fillColor: darkCard,
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
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius:
              BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: yellow,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              color: yellow,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterCard({
    required String title,
    required IconData icon,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: yellow,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: value > min
                ? () => onChanged(
                      value - 1,
                    )
                : null,
            icon: const Icon(
              Icons.remove_circle_outline,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: value < max
                ? () => onChanged(
                      value + 1,
                    )
                : null,
            icon: const Icon(
              Icons.add_circle_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String title,
    String value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isTotal
                    ? Colors.white
                    : Colors.grey,
                fontSize:
                    isTotal ? 14 : 11,
                fontWeight: isTotal
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style: TextStyle(
                color:
                    isTotal ? yellow : Colors.white,
                fontSize:
                    isTotal ? 16 : 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: yellow,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Use this screen when a guest arrives directly at hotel reception without booking through the customer app.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentBypassNotice() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: const Text(
        'Walk-in booking and advance records are saved to Firestore. Real JazzCash, Easypaisa, wallet verification and automatic commission settlement remain bypassed.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey,
          fontSize: 10,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: yellow,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String? _required(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  String? _phoneValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().length < 10) {
      return 'Enter a valid phone number.';
    }

    return null;
  }

  double _readNumber(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _formatDate(
    DateTime value,
  ) {
    final String day =
        value.day.toString().padLeft(
              2,
              '0',
            );

    final String month =
        value.month.toString().padLeft(
              2,
              '0',
            );

    return '$day/$month/${value.year}';
  }

  String _formatMoney(
    double amount,
  ) {
    final String value =
        amount.toStringAsFixed(0);

    return value.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
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


