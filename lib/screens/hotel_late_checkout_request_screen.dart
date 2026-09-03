import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HotelLateCheckoutRequestScreen extends StatefulWidget {
  const HotelLateCheckoutRequestScreen({
    super.key,
    required this.booking,
  });

  final Map<String, dynamic> booking;

  @override
  State<HotelLateCheckoutRequestScreen> createState() =>
      _HotelLateCheckoutRequestScreenState();
}

class _HotelLateCheckoutRequestScreenState
    extends State<HotelLateCheckoutRequestScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _reasonController =
      TextEditingController();

  String _selectedOption = '2_hours';
  bool _agree = false;
  bool _isSubmitting = false;

  String get _bookingId =>
      widget.booking['bookingId']?.toString() ??
      widget.booking['id']?.toString() ??
      '';

  String get _hotelId =>
      widget.booking['hotelId']?.toString() ?? '';

  String get _hotelName =>
      widget.booking['hotelName']?.toString() ??
      'Hotel';

  String get _roomName =>
      widget.booking['roomName']?.toString() ??
      widget.booking['roomType']?.toString() ??
      'Selected Room';

  String get _bookingStatus =>
      widget.booking['bookingStatus']?.toString() ??
      'pending';

  DateTime get _checkOutDate =>
      _readDateTime(widget.booking['checkOut']);

  int get _checkOutHour =>
      _readInt(
        widget.booking['hotelCheckOutHour'],
        fallback: 12,
      );

  int get _checkOutMinute =>
      _readInt(
        widget.booking['hotelCheckOutMinute'],
      );

  DateTime get _currentCheckoutDateTime {
    final DateTime date = _checkOutDate;

    if (date.millisecondsSinceEpoch == 0) {
      return DateTime.now();
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      _checkOutHour.clamp(0, 23),
      _checkOutMinute.clamp(0, 59),
    );
  }

  int get _extraHours {
    switch (_selectedOption) {
      case '1_hour':
        return 1;
      case '4_hours':
        return 4;
      case '6_hours':
        return 6;
      case 'half_day':
        return 12;
      case 'full_day':
        return 24;
      default:
        return 2;
    }
  }

  DateTime get _requestedCheckoutDateTime =>
      _currentCheckoutDateTime.add(
        Duration(hours: _extraHours),
      );

  double get _hourlyLateCheckoutRate =>
      _readNumber(
        widget.booking['lateCheckoutHourlyRate'],
      );

  double get _halfDayRate =>
      _readNumber(
        widget.booking['lateCheckoutHalfDayRate'],
      );

  double get _fullDayRate =>
      _readNumber(
        widget.booking['lateCheckoutFullDayRate'],
      );

  double get _estimatedCharge {
    if (_selectedOption == 'half_day') {
      return _halfDayRate;
    }

    if (_selectedOption == 'full_day') {
      return _fullDayRate;
    }

    if (_hourlyLateCheckoutRate <= 0) {
      return 0;
    }

    return _hourlyLateCheckoutRate * _extraHours;
  }

  bool get _canRequest {
    return _bookingStatus == 'confirmed' ||
        _bookingStatus == 'checked_in' ||
        _bookingStatus == 'active' ||
        _bookingStatus == 'in_stay';
  }

  @override
  void dispose() {
    _reasonController.dispose();
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
          'Late Check-out Request',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            30,
          ),
          children: [
            _bookingCard(),

            const SizedBox(height: 16),

            _currentCheckoutCard(),

            const SizedBox(height: 20),

            const Text(
              'Choose Extra Time',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _optionCard(
              value: '1_hour',
              title: '1 Extra Hour',
              subtitle: 'Short extension',
            ),
            _optionCard(
              value: '2_hours',
              title: '2 Extra Hours',
              subtitle: 'Common late check-out request',
            ),
            _optionCard(
              value: '4_hours',
              title: '4 Extra Hours',
              subtitle: 'Extended room use',
            ),
            _optionCard(
              value: '6_hours',
              title: '6 Extra Hours',
              subtitle: 'Long extension',
            ),
            _optionCard(
              value: 'half_day',
              title: 'Half Day',
              subtitle: 'Up to 12 extra hours',
            ),
            _optionCard(
              value: 'full_day',
              title: 'Full Day',
              subtitle: 'Up to 24 extra hours',
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _reasonController,
              maxLines: 4,
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                hintText:
                    'Example: late transport, medical need, family delay',
                labelStyle: const TextStyle(
                  color: Colors.grey,
                ),
                hintStyle: const TextStyle(
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: darkCard,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            _estimateCard(),

            const SizedBox(height: 14),

            CheckboxListTile(
              value: _agree,
              onChanged: (value) {
                setState(() {
                  _agree = value ?? false;
                });
              },
              activeColor: yellow,
              checkColor: Colors.black,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I understand that the hotel must approve this request and may apply an extra charge.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: !_canRequest ||
                        _isSubmitting
                    ? null
                    : _submitRequest,
                icon: _isSubmitting
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
                        Icons.schedule_send_outlined,
                      ),
                label: Text(
                  _isSubmitting
                      ? 'Submitting...'
                      : 'Submit Late Check-out Request',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
              ),
            ),

            if (!_canRequest) ...[
              const SizedBox(height: 12),
              const Text(
                'Late check-out can only be requested for confirmed or active stays.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                ),
              ),
            ],

            const SizedBox(height: 14),

            _bypassNotice(),
          ],
        ),
      ),
    );
  }

  Widget _bookingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: yellow.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.hotel_outlined,
              color: yellow,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _hotelName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _roomName,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Booking: ${_bookingId.isEmpty ? 'Not available' : _bookingId}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentCheckoutCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _detailRow(
            'Current check-out',
            _formatDateTime(
              _currentCheckoutDateTime,
            ),
          ),
          _detailRow(
            'Requested check-out',
            _formatDateTime(
              _requestedCheckoutDateTime,
            ),
          ),
          _detailRow(
            'Extra time',
            '$_extraHours hour(s)',
          ),
        ],
      ),
    );
  }

  Widget _optionCard({
    required String value,
    required String title,
    required String subtitle,
  }) {
    final bool selected =
        _selectedOption == value;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
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
        groupValue: _selectedOption,
        onChanged: (newValue) {
          if (newValue == null) {
            return;
          }

          setState(() {
            _selectedOption = newValue;
          });
        },
        child: RadioListTile<String>(
          value: value,
          activeColor: yellow,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  Widget _estimateCard() {
    final String chargeText =
        _estimatedCharge <= 0
            ? 'Hotel will confirm'
            : 'PKR ${_formatMoney(_estimatedCharge)}';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        children: [
          _detailRow(
            'Estimated extra charge',
            chargeText,
          ),
          _detailRow(
            'Approval status',
            'Pending hotel approval',
          ),
          const SizedBox(height: 6),
          const Text(
            'The hotel may approve, reject or adjust the final late check-out charge depending on room availability and policy.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (_bookingId.isEmpty) {
      _showMessage(
        'Booking ID is not available.',
        isError: true,
      );
      return;
    }

    if (!_agree) {
      _showMessage(
        'Please accept the late check-out terms.',
        isError: true,
      );
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in first.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final DocumentReference<Map<String, dynamic>>
          requestReference = _firestore
              .collection(
                'hotel_late_checkout_requests',
              )
              .doc();

      final WriteBatch batch =
          _firestore.batch();

      batch.set(
        requestReference,
        <String, dynamic>{
          'requestId': requestReference.id,
          'bookingId': _bookingId,
          'hotelId': _hotelId,
          'hotelName': _hotelName,
          'roomName': _roomName,
          'userId': user.uid,
          'selectedOption': _selectedOption,
          'extraHours': _extraHours,
          'reason':
              _reasonController.text.trim(),
          'currentCheckoutAt':
              Timestamp.fromDate(
            _currentCheckoutDateTime,
          ),
          'requestedCheckoutAt':
              Timestamp.fromDate(
            _requestedCheckoutDateTime,
          ),
          'estimatedCharge':
              _estimatedCharge,
          'requestStatus': 'pending',
          'bookingStatusAtRequest':
              _bookingStatus,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        _firestore
            .collection('hotel_bookings')
            .doc(_bookingId),
        <String, dynamic>{
          'lateCheckoutRequested': true,
          'lateCheckoutRequestId':
              requestReference.id,
          'lateCheckoutRequestStatus':
              'pending',
          'requestedExtraHours':
              _extraHours,
          'requestedCheckoutAt':
              Timestamp.fromDate(
            _requestedCheckoutDateTime,
          ),
          'lateCheckoutEstimatedCharge':
              _estimatedCharge,
          'lateCheckoutReason':
              _reasonController.text.trim(),
          'lateCheckoutRequestedBy':
              user.uid,
          'lateCheckoutRequestedAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (_hotelId.isNotEmpty) {
        final DocumentReference<
                Map<String, dynamic>>
            notificationReference =
            _firestore
                .collection(
                  'hotel_notifications',
                )
                .doc();

        batch.set(
          notificationReference,
          <String, dynamic>{
            'hotelId': _hotelId,
            'type':
                'late_checkout_request',
            'title':
                'Late Check-out Request',
            'message':
                'A guest requested $_extraHours extra checkout hour(s) for booking $_bookingId.',
            'bookingId': _bookingId,
            'requestId':
                requestReference.id,
            'isRead': false,
            'createdAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

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
              'Request Submitted',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Your request for $_extraHours extra checkout hour(s) has been sent to the hotel. Approval and final charges will appear in My Bookings.',
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      _showMessage(
        'Unable to submit late check-out request: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }

    // =======================================================
    // REAL EXTRA PAYMENT FLOW - COMMENTED FOR LATER
    // =======================================================
    //
    // 1. Hotel approves requested extra time.
    // 2. Load admin-controlled late checkout pricing.
    // 3. Recalculate hotel/admin commission.
    // 4. Charge JazzCash, Easypaisa or wallet.
    // 5. Save payment and settlement transactions.
    // 6. Update final checkout timestamp.
    //
    // Request and notification are active now. Real payment
    // collection and automatic commission settlement remain
    // bypassed until payment integration is enabled.
    // =======================================================
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bypassNotice() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(14),
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
              'Late check-out request and hotel notification are saved to Firestore. Real extra payment and automatic commission settlement remain bypassed.',
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

  DateTime _readDateTime(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDateTime(
    DateTime value,
  ) {
    final String day =
        value.day.toString().padLeft(2, '0');

    final String month =
        value.month.toString().padLeft(2, '0');

    final int hour12 =
        value.hour == 0
            ? 12
            : value.hour > 12
                ? value.hour - 12
                : value.hour;

    final String minute =
        value.minute.toString().padLeft(2, '0');

    final String period =
        value.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/${value.year} '
        '$hour12:$minute $period';
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


