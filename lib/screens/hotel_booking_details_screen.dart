import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../safety/models/safety_models.dart';
import '../safety/screens/safety_center_screen.dart';

import '../widgets/hotel_checkout_countdown.dart';
import 'hotel_cancellation_request_screen.dart';
import 'hotel_late_checkout_request_screen.dart';
import 'hotel_customer_chat_screen.dart';
import 'hotel_invoice_screen.dart';

class HotelBookingDetailsScreen extends StatefulWidget {
  const HotelBookingDetailsScreen({super.key, required this.booking});

  /// Expected booking fields:
  ///
  /// bookingId / id
  /// hotelId
  /// hotelName
  /// hotelPhone
  /// roomId
  /// roomName
  /// roomNumber
  /// guestName
  /// guestPhone
  /// guestCnic
  /// bookingStatus
  /// paymentMethod
  /// paymentStatus
  /// totalAmount
  /// checkIn
  /// checkOut
  /// hotelCheckOutHour
  /// hotelCheckOutMinute
  final Map<String, dynamic> booking;

  @override
  State<HotelBookingDetailsScreen> createState() =>
      _HotelBookingDetailsScreenState();
}

class _HotelBookingDetailsScreenState extends State<HotelBookingDetailsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isWorking = false;
  bool _checkoutReachedLocally = false;

  String get _bookingId =>
      widget.booking['bookingId']?.toString() ??
      widget.booking['id']?.toString() ??
      '';

  String get _hotelName => widget.booking['hotelName']?.toString() ?? 'Hotel';

  String get _roomName =>
      widget.booking['roomName']?.toString() ??
      widget.booking['roomType']?.toString() ??
      'Selected Room';

  String get _roomNumber => widget.booking['roomNumber']?.toString() ?? '';

  String get _guestName => widget.booking['guestName']?.toString() ?? 'Guest';

  String get _guestPhone =>
      widget.booking['guestPhone']?.toString() ??
      widget.booking['phoneNumber']?.toString() ??
      '';

  String get _guestCnic =>
      widget.booking['guestCnic']?.toString() ??
      widget.booking['cnic']?.toString() ??
      '';

  String get _hotelPhone => widget.booking['hotelPhone']?.toString() ?? '';

  String get _bookingStatus =>
      widget.booking['bookingStatus']?.toString() ?? 'pending';

  String get _paymentMethod =>
      widget.booking['paymentMethod']?.toString() ?? 'Not set';

  String get _paymentStatus =>
      widget.booking['paymentStatus']?.toString() ?? 'pending';

  double get _totalAmount => _readNumber(widget.booking['totalAmount']);

  DateTime get _checkInDate => _readDateTime(widget.booking['checkIn']);

  DateTime get _checkOutDate => _readDateTime(widget.booking['checkOut']);

  DateTime get _checkOutDateTime {
    final int hour = _readInt(
      widget.booking['hotelCheckOutHour'],
      fallback: 12,
    );

    final int minute = _readInt(widget.booking['hotelCheckOutMinute']);

    final DateTime date = _checkOutDate;

    if (date.millisecondsSinceEpoch == 0) {
      return DateTime.now();
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour.clamp(0, 23),
      minute.clamp(0, 59),
    );
  }

  bool get _showCountdown {
    const Set<String> allowedStatuses = <String>{
      'confirmed',
      'checked_in',
      'active',
      'in_stay',
    };

    return allowedStatuses.contains(_bookingStatus) &&
        _checkOutDate.millisecondsSinceEpoch != 0;
  }

  bool get _canCancel {
    return _bookingStatus == 'pending' || _bookingStatus == 'confirmed';
  }

  bool get _canRate {
    return _bookingStatus == 'completed' || _bookingStatus == 'checked_out';
  }

  void _openUniversalHotelSafety() {
    final bool activeStay = <String>{
      'checked_in',
      'active',
      'in_stay',
    }.contains(_bookingStatus);

    final String guestUserId =
        widget.booking['userId']?.toString() ??
        widget.booking['customerId']?.toString() ??
        '';

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return SafetyCenterScreen(
            contextData: SafetyContext(
              serviceType: activeStay
                  ? SafetyServiceType.hotelStay
                  : SafetyServiceType.hotelBooking,
              referenceId: _bookingId,
              initiatedByUserId: guestUserId,
              initiatedByRole: SafetyUserRole.hotelGuest,
              sourcePage: activeStay
                  ? SafetySourcePage.activeHotelStay
                  : SafetySourcePage.hotelBookingDetails,
              referenceStatus: _bookingStatus,
              serviceTitle: activeStay
                  ? 'Hotel Stay Safety'
                  : 'Hotel Booking Safety',
              serviceSubtitle: _hotelName,
              paymentMethod: _paymentMethod,
              metadata: <String, dynamic>{
                'bookingId': _bookingId,
                'hotelId': widget.booking['hotelId']?.toString() ?? '',
                'hotelName': _hotelName,
                'roomId': widget.booking['roomId']?.toString() ?? '',
                'roomName': _roomName,
                'roomNumber': _roomNumber,
                'bookingStatus': _bookingStatus,
                'paymentStatus': _paymentStatus,
                'totalAmount': _totalAmount,
                'checkIn': _checkInDate.toIso8601String(),
                'checkOut': _checkOutDateTime.toIso8601String(),
                'activeStay': activeStay,

                // Guest phone, CNIC and other unnecessary
                // private identity data are intentionally
                // excluded from Safety metadata.
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Booking Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          children: [
            _statusHeader(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openUniversalHotelSafety,
              icon: const Icon(Icons.shield_outlined),
              label: const Text(
                'SAFETY & SOS',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),

            if (_showCountdown) ...[
              const SizedBox(height: 16),
              HotelCheckoutCountdown(
                checkOutDateTime: _checkOutDateTime,
                hotelName: _hotelName,
                onCheckoutReached: () {
                  if (!mounted || _checkoutReachedLocally) {
                    return;
                  }

                  setState(() {
                    _checkoutReachedLocally = true;
                  });
                },
              ),
            ],

            const SizedBox(height: 18),

            _sectionCard(
              title: 'Hotel & Room',
              icon: Icons.hotel_outlined,
              child: Column(
                children: [
                  _detailRow('Hotel', _hotelName),
                  _detailRow('Room', _roomName),
                  if (_roomNumber.isNotEmpty)
                    _detailRow('Room Number', _roomNumber),
                  if (_hotelPhone.isNotEmpty)
                    _detailRow('Hotel Helpline', _hotelPhone),
                ],
              ),
            ),

            const SizedBox(height: 14),

            _sectionCard(
              title: 'Stay Information',
              icon: Icons.calendar_month_outlined,
              child: Column(
                children: [
                  _detailRow('Check-in', _formatDateTime(_checkInDate)),
                  _detailRow('Check-out', _formatDateTime(_checkOutDateTime)),
                  _detailRow('Nights', '${_calculateNights()}'),
                  _detailRow(
                    'Booking ID',
                    _bookingId.isEmpty ? 'Not available' : _bookingId,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            _sectionCard(
              title: 'Guest Details',
              icon: Icons.person_outline,
              child: Column(
                children: [
                  _detailRow('Guest', _guestName),
                  if (_guestPhone.isNotEmpty) _detailRow('Phone', _guestPhone),
                  if (_guestCnic.isNotEmpty) _detailRow('CNIC', _guestCnic),
                ],
              ),
            ),

            const SizedBox(height: 14),

            _sectionCard(
              title: 'Payment Summary',
              icon: Icons.payments_outlined,
              child: Column(
                children: [
                  _detailRow('Payment Method', _paymentMethod),
                  _detailRow('Payment Status', _statusLabel(_paymentStatus)),
                  _detailRow(
                    'Total Amount',
                    _totalAmount <= 0
                        ? 'Not available'
                        : 'PKR ${_formatMoney(_totalAmount)}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            _actionButtons(),

            const SizedBox(height: 16),

            _zeroCostNotice(),
          ],
        ),
      ),
    );
  }

  Widget _statusHeader() {
    final Color statusColor = _statusColor(_bookingStatus);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _statusIcon(_bookingStatus),
              color: statusColor,
              size: 29,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hotelName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _roomName,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              _statusLabel(
                _checkoutReachedLocally ? 'checkout_due' : _bookingStatus,
              ),
              style: TextStyle(
                color: _checkoutReachedLocally ? Colors.orange : statusColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Column(
      children: [
        if (_hotelPhone.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isWorking ? null : _showHotelContact,
              icon: const Icon(Icons.phone_outlined),
              label: const Text('Hotel Helpline'),
              style: OutlinedButton.styleFrom(
                foregroundColor: yellow,
                side: const BorderSide(color: yellow),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

        if (_hotelPhone.isNotEmpty) const SizedBox(height: 10),

        if (_canCancel)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isWorking
                  ? null
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HotelCancellationRequestScreen(
                            booking: widget.booking,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Request Cancellation'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isWorking
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HotelLateCheckoutRequestScreen(
                          booking: widget.booking,
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.schedule),
            label: const Text('Late Check-out'),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isWorking
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            HotelCustomerChatScreen(booking: widget.booking),
                      ),
                    );
                  },
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Hotel Chat'),
            style: OutlinedButton.styleFrom(
              foregroundColor: yellow,
              side: const BorderSide(color: yellow),
            ),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isWorking
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            HotelInvoiceScreen(booking: widget.booking),
                      ),
                    );
                  },
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text(
              'View Invoice PDF',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        if (_canRate)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isWorking ? null : _rateHotel,
              icon: const Icon(Icons.star_outline),
              label: const Text(
                'Rate Hotel',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _rateHotel() async {
    if (_bookingId.isEmpty) {
      _showMessage('Booking ID is not available.', isError: true);
      return;
    }

    int rating = 5;
    final TextEditingController reviewController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: darkCard,
              title: const Text(
                'Rate Hotel',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final int value = index + 1;

                      return IconButton(
                        onPressed: () {
                          setDialogState(() {
                            rating = value;
                          });
                        },
                        icon: Icon(
                          value <= rating ? Icons.star : Icons.star_border,
                          color: yellow,
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Write an optional review',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    final String review = reviewController.text.trim();

    reviewController.dispose();

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      await _firestore.collection('hotel_reviews').add(<String, dynamic>{
        'bookingId': _bookingId,
        'hotelId': widget.booking['hotelId']?.toString() ?? '',
        'hotelName': _hotelName,
        'guestName': _guestName,
        'rating': rating,
        'review': review,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showMessage('Thank you for your rating.');
    } catch (error) {
      _showMessage('Unable to submit rating: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  void _showHotelContact() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Hotel Helpline',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            _hotelPhone,
            style: const TextStyle(
              color: yellow,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: yellow),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zeroCostNotice() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: yellow.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: yellow),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Checkout countdown runs locally on this device. Firebase is not read or written every second.',
              style: TextStyle(color: Colors.grey, fontSize: 10, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateNights() {
    if (_checkInDate.millisecondsSinceEpoch == 0 ||
        _checkOutDate.millisecondsSinceEpoch == 0) {
      return 0;
    }

    final int nights = _checkOutDate.difference(_checkInDate).inDays;

    return nights < 0 ? 0 : nights;
  }

  int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _readNumber(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDateTime(DateTime value) {
    if (value.millisecondsSinceEpoch == 0) {
      return 'Not available';
    }

    final String day = value.day.toString().padLeft(2, '0');

    final String month = value.month.toString().padLeft(2, '0');

    final int hour12 = value.hour == 0
        ? 12
        : value.hour > 12
        ? value.hour - 12
        : value.hour;

    final String minute = value.minute.toString().padLeft(2, '0');

    final String period = value.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/${value.year} '
        '$hour12:$minute $period';
  }

  String _formatMoney(double amount) {
    final String value = amount.toStringAsFixed(0);

    return value.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'checked_in':
      case 'completed':
      case 'checked_out':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'checkout_due':
        return Colors.orange;
      default:
        return yellow;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'checked_in':
        return Icons.login;
      case 'completed':
      case 'checked_out':
        return Icons.task_alt;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'checked_in':
        return 'Checked In';
      case 'completed':
        return 'Completed';
      case 'checked_out':
        return 'Checked Out';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'checkout_due':
        return 'Check-out Due';
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : darkCard,
        ),
      );
  }
}
