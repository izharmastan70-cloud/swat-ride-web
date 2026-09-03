import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HotelCancellationRequestScreen extends StatefulWidget {
  const HotelCancellationRequestScreen({
    super.key,
    required this.booking,
  });

  final Map<String, dynamic> booking;

  @override
  State<HotelCancellationRequestScreen> createState() =>
      _HotelCancellationRequestScreenState();
}

class _HotelCancellationRequestScreenState
    extends State<HotelCancellationRequestScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _reasonController =
      TextEditingController();

  final TextEditingController _detailsController =
      TextEditingController();

  String _selectedReason = 'Change of plan';
  bool _confirmCancellation = false;
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

  double get _totalAmount =>
      _readNumber(widget.booking['totalAmount']);

  DateTime get _checkIn =>
      _readDateTime(widget.booking['checkIn']);
int get _freeCancellationHours =>
      _readInt(
        widget.booking['freeCancellationHours'],
        fallback: 24,
      );

  double get _cancellationFeePercentage =>
      _readNumber(
        widget.booking['cancellationFeePercentage'],
      );

  bool get _isWithinFreeCancellation {
    if (_checkIn.millisecondsSinceEpoch == 0) {
      return false;
    }

    final DateTime freeUntil = _checkIn.subtract(
      Duration(hours: _freeCancellationHours),
    );

    return DateTime.now().isBefore(freeUntil);
  }

  double get _estimatedCancellationFee {
    if (_isWithinFreeCancellation) {
      return 0;
    }

    if (_cancellationFeePercentage <= 0) {
      return 0;
    }

    return _totalAmount *
        (_cancellationFeePercentage / 100);
  }

  double get _estimatedRefund {
    final double refund =
        _totalAmount - _estimatedCancellationFee;

    return refund < 0 ? 0 : refund;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _detailsController.dispose();
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
          'Cancel Hotel Booking',
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
            _bookingSummary(),

            const SizedBox(height: 16),

            _policyCard(),

            const SizedBox(height: 18),

            const Text(
              'Cancellation Reason',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _reasonSelector(),

            const SizedBox(height: 12),

            TextField(
              controller: _detailsController,
              maxLines: 4,
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                labelText:
                    'Additional details (optional)',
                labelStyle: const TextStyle(
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

            CheckboxListTile(
              value: _confirmCancellation,
              onChanged: (value) {
                setState(() {
                  _confirmCancellation =
                      value ?? false;
                });
              },
              activeColor: yellow,
              checkColor: Colors.black,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I understand that this request will be reviewed according to the hotel cancellation policy.',
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
                onPressed: _isSubmitting
                    ? null
                    : _submitCancellationRequest,
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
                        Icons.cancel_outlined,
                      ),
                label: Text(
                  _isSubmitting
                      ? 'Submitting...'
                      : 'Submit Cancellation Request',
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

            const SizedBox(height: 14),

            _bypassNotice(),
          ],
        ),
      ),
    );
  }

  Widget _bookingSummary() {
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _detailRow(
            'Booking ID',
            _bookingId.isEmpty
                ? 'Not available'
                : _bookingId,
          ),
          _detailRow(
            'Check-in',
            _formatDate(_checkIn),
          ),
          _detailRow(
            'Booking Status',
            _statusLabel(_bookingStatus),
          ),
          _detailRow(
            'Booking Total',
            _totalAmount <= 0
                ? 'Not available'
                : 'PKR ${_formatMoney(_totalAmount)}',
          ),
        ],
      ),
    );
  }

  Widget _policyCard() {
    final Color policyColor =
        _isWithinFreeCancellation
            ? Colors.green
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: policyColor.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: policyColor.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isWithinFreeCancellation
                    ? Icons.check_circle_outline
                    : Icons.policy_outlined,
                color: policyColor,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _isWithinFreeCancellation
                      ? 'Free Cancellation Window'
                      : 'Cancellation Fee May Apply',
                  style: TextStyle(
                    color: policyColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow(
            'Free cancellation',
            'Up to $_freeCancellationHours hours before check-in',
          ),
          _detailRow(
            'Estimated fee',
            'PKR ${_formatMoney(_estimatedCancellationFee)}',
          ),
          _detailRow(
            'Estimated refund',
            'PKR ${_formatMoney(_estimatedRefund)}',
          ),
          const SizedBox(height: 8),
          const Text(
            'Final fee and refund are confirmed by the hotel/admin after reviewing the booking policy and payment record.',
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

  Widget _reasonSelector() {
    const List<String> reasons = <String>[
      'Change of plan',
      'Found another hotel',
      'Travel cancelled',
      'Wrong dates selected',
      'Hotel information issue',
      'Payment issue',
      'Other',
    ];

    return Column(
      children: reasons.map(
        (reason) {
          final bool selected =
              _selectedReason == reason;

          return Container(
            margin:
                const EdgeInsets.only(
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
            groupValue: _selectedReason,
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedReason = value;
              });
            },
            child: RadioListTile<String>(
              value: reason,
              activeColor: yellow,
              title: Text(
                reason,
                style: const TextStyle(
                  color: Colors.white,
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

  Future<void> _submitCancellationRequest() async {
    if (_bookingId.isEmpty) {
      _showMessage(
        'Booking ID is not available.',
        isError: true,
      );
      return;
    }

    if (!_confirmCancellation) {
      _showMessage(
        'Please confirm that you understand the cancellation policy.',
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
                'hotel_cancellation_requests',
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
          'reason': _selectedReason,
          'details':
              _detailsController.text.trim(),
          'requestStatus': 'pending',
          'bookingStatusAtRequest':
              _bookingStatus,
          'totalAmount': _totalAmount,
          'freeCancellationHours':
              _freeCancellationHours,
          'cancellationFeePercentage':
              _cancellationFeePercentage,
          'estimatedCancellationFee':
              _estimatedCancellationFee,
          'estimatedRefund':
              _estimatedRefund,
          'withinFreeCancellation':
              _isWithinFreeCancellation,
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
          'cancellationRequested': true,
          'cancellationRequestId':
              requestReference.id,
          'cancellationRequestStatus':
              'pending',
          'cancellationReason':
              _selectedReason,
          'cancellationDetails':
              _detailsController.text.trim(),
          'cancellationRequestedBy':
              user.uid,
          'cancellationRequestedAt':
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
                'cancellation_request',
            'title':
                'New Cancellation Request',
            'message':
                'A guest requested cancellation for booking $_bookingId.',
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
            content: const Text(
              'Your cancellation request has been sent to the hotel for review. Final fee and refund status will appear in My Bookings.',
              style: TextStyle(
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
        'Unable to submit cancellation request: $error',
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
    // REAL REFUND + COMMISSION FLOW - COMMENTED FOR LATER
    // =======================================================
    //
    // 1. Verify actual payment transaction.
    // 2. Load admin-controlled cancellation policy.
    // 3. Calculate final refundable amount.
    // 4. Reverse or adjust hotel/admin commission.
    // 5. Process JazzCash/Easypaisa/wallet refund.
    // 6. Save refund transaction and settlement records.
    //
    // Request creation is active now. Real money refund and
    // automatic commission reversal remain bypassed.
    // =======================================================
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
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
              textAlign:
                  TextAlign.right,
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
              'Cancellation request and hotel notification are saved to Firestore. Real payment refund and commission reversal remain bypassed until payment integration is enabled.',
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
          DateTime.fromMillisecondsSinceEpoch(
            0,
          );
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
    );
  }

  String _formatDate(
    DateTime value,
  ) {
    if (value.millisecondsSinceEpoch == 0) {
      return 'Not available';
    }

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

  String _statusLabel(
    String status,
  ) {
    switch (status) {
      case 'pending_hotel_confirmation':
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'checked_in':
        return 'Checked In';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
      case 'checked_out':
        return 'Completed';
      default:
        return status;
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




