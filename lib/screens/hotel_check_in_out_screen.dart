import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/hotel_booking.dart';
import '../models/hotel_room.dart';
import '../services/hotel_booking_operations_service.dart';
import '../services/tourism_service.dart';

class HotelCheckInOutScreen extends StatefulWidget {
  const HotelCheckInOutScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelCheckInOutScreen> createState() =>
      _HotelCheckInOutScreenState();
}

class _HotelCheckInOutScreenState
    extends State<HotelCheckInOutScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final HotelBookingOperationsService _bookingService =
      HotelBookingOperationsService();
  final TourismService _tourismService =
      TourismService();
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String _selectedTab = 'arrivals';
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Colors.white),
        title: const Text(
          'Check-in / Check-out',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Scan QR',
            onPressed:
                _isWorking ? null : _openQrScanner,
            icon: const Icon(
              Icons.qr_code_scanner,
              color: yellow,
            ),
          ),
          IconButton(
            tooltip: 'Manual verification',
            onPressed: _isWorking
                ? null
                : _openManualVerification,
            icon: const Icon(
              Icons.pin_outlined,
              color: yellow,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<HotelBooking>>(
          stream: _bookingService
              .hotelBookingsStream(widget.hotelId),
          builder: (
            context,
            AsyncSnapshot<List<HotelBooking>>
                snapshot,
          ) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: yellow,
                ),
              );
            }

            if (snapshot.hasError) {
              return _emptyState(
                icon: Icons.error_outline,
                title: 'Unable to Load Guests',
                message: snapshot.error.toString(),
              );
            }

            final allBookings =
                snapshot.data ?? <HotelBooking>[];

            final visibleBookings =
                allBookings.where((booking) {
              if (_selectedTab == 'arrivals') {
                return booking.bookingStatus ==
                    'confirmed';
              }

              if (_selectedTab == 'staying') {
                return booking.bookingStatus ==
                    'checked_in';
              }

              return booking.bookingStatus ==
                      'completed' ||
                  booking.bookingStatus ==
                      'no_show';
            }).toList();

            return Column(
              children: [
                _verificationBanner(),
                _tabs(allBookings),
                Expanded(
                  child: visibleBookings.isEmpty
                      ? _emptyState(
                          icon: _selectedTab ==
                                  'arrivals'
                              ? Icons.login
                              : _selectedTab ==
                                      'staying'
                                  ? Icons.hotel
                                  : Icons.history,
                          title: _selectedTab ==
                                  'arrivals'
                              ? 'No Confirmed Arrivals'
                              : _selectedTab ==
                                      'staying'
                                  ? 'No Checked-in Guests'
                                  : 'No Completed Stays',
                          message: _selectedTab ==
                                  'arrivals'
                              ? 'Confirmed bookings ready for secure check-in will appear here.'
                              : _selectedTab ==
                                      'staying'
                                  ? 'Guests currently staying at the hotel will appear here.'
                                  : 'Completed and no-show records will appear here.',
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            12,
                            16,
                            24,
                          ),
                          itemCount:
                              visibleBookings.length,
                          itemBuilder:
                              (context, index) {
                            return _bookingCard(
                              visibleBookings[index],
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _verificationBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        4,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yellow.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: yellow.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: yellow,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Verify guest by secure QR or Booking ID + 6-digit PIN before check-in.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: yellow,
            ),
            color: darkCard,
            onSelected: (value) {
              if (value == 'qr') {
                _openQrScanner();
              } else {
                _openManualVerification();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'qr',
                child: Text('Scan QR'),
              ),
              PopupMenuItem(
                value: 'manual',
                child: Text(
                  'Booking ID + PIN',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openQrScanner() async {
    bool handled = false;

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (scannerContext) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: const Text(
                'Scan Hotel Check-in QR',
              ),
            ),
            body: Stack(
              children: [
                MobileScanner(
                  onDetect: (capture) async {
                    if (handled) return;

                    final String? value =
                        capture.barcodes
                            .map(
                              (barcode) =>
                                  barcode.rawValue,
                            )
                            .whereType<String>()
                            .firstOrNull;

                    if (value == null ||
                        value.isEmpty) {
                      return;
                    }

                    handled = true;
                    Navigator.pop(scannerContext);

                    await _verifyQrPayload(value);
                  },
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: yellow,
                        width: 3,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
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

  Future<void> _openManualVerification() async {
    final TextEditingController idController =
        TextEditingController();
    final TextEditingController pinController =
        TextEditingController();

    final bool? submit =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Manual Check-in Verification',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(
                controller: idController,
                label: 'Booking ID',
                icon: Icons.confirmation_number,
              ),
              const SizedBox(height: 12),
              _dialogField(
                controller: pinController,
                label: '6-digit PIN',
                icon: Icons.pin,
                keyboardType:
                    TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );

    final String bookingId =
        idController.text.trim();
    final String pin =
        pinController.text.trim();

    idController.dispose();
    pinController.dispose();

    if (submit == true) {
      await _verifyBooking(
        bookingId: bookingId,
        pin: pin,
        method: 'manual_id_pin',
      );
    }
  }

  Widget _dialogField({
    required TextEditingController controller,
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
        prefixIcon: Icon(icon, color: yellow),
        filled: true,
        fillColor: darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _verifyQrPayload(
    String payload,
  ) async {
    try {
      final dynamic decoded =
          jsonDecode(payload);

      if (decoded is! Map) {
        throw const FormatException();
      }

      final String type =
          decoded['type']?.toString() ?? '';
      final String bookingId =
          decoded['bookingId']?.toString() ?? '';
      final String token =
          decoded['token']?.toString() ?? '';

      if (type !=
              'swat_ride_hotel_check_in' ||
          bookingId.isEmpty ||
          token.isEmpty) {
        throw const FormatException();
      }

      await _verifyBooking(
        bookingId: bookingId,
        token: token,
        method: 'qr',
      );
    } catch (_) {
      _showMessage(
        'This is not a valid SWAT RIDE hotel QR.',
        isError: true,
      );
    }
  }

  Future<void> _verifyBooking({
    required String bookingId,
    String? token,
    String? pin,
    required String method,
  }) async {
    final User? staff =
        FirebaseAuth.instance.currentUser;

    if (staff == null) {
      _showMessage(
        'Hotel staff login is required.',
        isError: true,
      );
      return;
    }

    if (bookingId.trim().isEmpty) {
      _showMessage(
        'Enter a valid Booking ID.',
        isError: true,
      );
      return;
    }

    if (method == 'manual_id_pin' &&
        !RegExp(r'^\d{6}$').hasMatch(
          pin ?? '',
        )) {
      _showMessage(
        'Enter the correct 6-digit PIN.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      DocumentSnapshot<Map<String, dynamic>>
          snapshot = await _firestore
              .collection('hotel_bookings')
              .doc(bookingId)
              .get();

      if (!snapshot.exists) {
        final QuerySnapshot<Map<String, dynamic>>
            query = await _firestore
                .collection('hotel_bookings')
                .where(
                  'bookingId',
                  isEqualTo: bookingId,
                )
                .limit(1)
                .get();

        if (query.docs.isEmpty) {
          throw Exception(
            'Booking not found.',
          );
        }

        snapshot = query.docs.first;
      }

      final Map<String, dynamic> data =
          snapshot.data() ??
              <String, dynamic>{};

      final String bookingHotelId =
          data['hotelId']?.toString() ?? '';

      if (bookingHotelId != widget.hotelId) {
        throw Exception(
          'This booking belongs to another hotel.',
        );
      }

      final String status =
          data['bookingStatus']?.toString() ??
              '';

      if (status == 'cancelled' ||
          status == 'rejected' ||
          status == 'no_show') {
        throw Exception(
          'This booking is $status and cannot be checked in.',
        );
      }

      if (status == 'checked_in' ||
          status == 'active' ||
          status == 'in_stay') {
        throw Exception(
          'This guest is already checked in.',
        );
      }

      if (status == 'completed' ||
          status == 'checked_out') {
        throw Exception(
          'This stay is already completed.',
        );
      }

      if (status != 'confirmed') {
        throw Exception(
          'Only confirmed bookings can be checked in.',
        );
      }

      final DateTime? checkIn =
          _readDate(data['checkIn']);
      final DateTime? checkOut =
          _readDate(data['checkOut']);
      final DateTime now = DateTime.now();

      if (checkIn == null ||
          checkOut == null) {
        throw Exception(
          'Booking dates are missing.',
        );
      }

      final DateTime earliest =
          DateTime(
            checkIn.year,
            checkIn.month,
            checkIn.day,
          ).subtract(
            const Duration(hours: 6),
          );

      final DateTime latest =
          DateTime(
            checkOut.year,
            checkOut.month,
            checkOut.day,
            23,
            59,
          );

      if (now.isBefore(earliest)) {
        throw Exception(
          'Check-in is not open yet.',
        );
      }

      if (now.isAfter(latest)) {
        throw Exception(
          'This booking has expired.',
        );
      }

      if (data['qrIsActive'] != true ||
          data['verificationPinIsActive'] !=
              true) {
        throw Exception(
          'Verification code is inactive or already used.',
        );
      }

      if (method == 'qr' &&
          data['qrToken']?.toString() !=
              token) {
        throw Exception(
          'QR security token does not match.',
        );
      }

      if (method == 'manual_id_pin' &&
          data['verificationPin']
                  ?.toString() !=
              pin) {
        throw Exception(
          'Booking ID or PIN is incorrect.',
        );
      }

      final bool? confirmed =
          await _showVerifiedBooking(
        data: data,
        bookingId: snapshot.id,
        method: method,
      );

      if (confirmed != true) {
        return;
      }

      final WriteBatch batch =
          _firestore.batch();

      batch.set(
        snapshot.reference,
        <String, dynamic>{
          'bookingStatus': 'checked_in',
          'checkedInAt':
              FieldValue.serverTimestamp(),
          'checkedInBy': staff.uid,
          'checkInMethod': method,
          'qrIsActive': false,
          'qrUsedAt':
              FieldValue.serverTimestamp(),
          'verificationPinIsActive':
              false,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final DocumentReference<
              Map<String, dynamic>>
          logReference = _firestore
              .collection(
                'hotel_check_in_logs',
              )
              .doc();

      batch.set(
        logReference,
        <String, dynamic>{
          'logId': logReference.id,
          'bookingId': snapshot.id,
          'hotelId': widget.hotelId,
          'staffUserId': staff.uid,
          'method': method,
          'result': 'success',
          'createdAt':
              FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      _showMessage(
        'Guest verified and checked in successfully.',
      );
    } catch (error) {
      await _saveFailedVerificationLog(
        bookingId: bookingId,
        method: method,
        reason: error.toString(),
      );

      _showMessage(
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<bool?> _showVerifiedBooking({
    required Map<String, dynamic> data,
    required String bookingId,
    required String method,
  }) {
    final String guestName =
        data['guestName']?.toString() ??
            'Guest';
    final String roomName =
        data['roomName']?.toString() ??
            'Hotel Room';
    final int guests =
        _readInt(data['guests'], 1);
    final int rooms =
        _readInt(data['rooms'], 1);

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Row(
            children: [
              Icon(
                Icons.verified,
                color: Colors.green,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Booking Verified',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(
                'Booking',
                _shortId(bookingId),
              ),
              _detailRow(
                'Guest',
                guestName,
              ),
              _detailRow(
                'Room',
                roomName,
              ),
              _detailRow(
                'Guests / Rooms',
                '$guests / $rooms',
              ),
              _detailRow(
                'Method',
                method == 'qr'
                    ? 'Secure QR'
                    : 'Booking ID + PIN',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'Confirm Check-in',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveFailedVerificationLog({
    required String bookingId,
    required String method,
    required String reason,
  }) async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    try {
      await _firestore
          .collection('hotel_check_in_logs')
          .add(
        <String, dynamic>{
          'bookingId': bookingId,
          'hotelId': widget.hotelId,
          'staffUserId': user?.uid ?? '',
          'method': method,
          'result': 'failed',
          'reason': reason,
          'createdAt':
              FieldValue.serverTimestamp(),
        },
      );
    } catch (_) {
      // Verification result remains visible even if audit logging fails.
    }
  }

  Widget _tabs(
    List<HotelBooking> bookings,
  ) {
    final int arrivals = bookings
        .where(
          (booking) =>
              booking.bookingStatus ==
              'confirmed',
        )
        .length;
    final int staying = bookings
        .where(
          (booking) =>
              booking.bookingStatus ==
              'checked_in',
        )
        .length;
    final int history = bookings
        .where(
          (booking) =>
              booking.bookingStatus ==
                  'completed' ||
              booking.bookingStatus ==
                  'no_show',
        )
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        4,
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              value: 'arrivals',
              label: 'Arrivals',
              count: arrivals,
              icon: Icons.login,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _tabButton(
              value: 'staying',
              label: 'Staying',
              count: staying,
              icon: Icons.hotel,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _tabButton(
              value: 'history',
              label: 'History',
              count: history,
              icon: Icons.history,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String value,
    required String label,
    required int count,
    required IconData icon,
  }) {
    final bool selected =
        _selectedTab == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = value;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected ? yellow : darkCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected
                  ? Colors.black
                  : yellow,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              '$label ($count)',
              style: TextStyle(
                color: selected
                    ? Colors.black
                    : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingCard(
    HotelBooking booking,
  ) {
    return FutureBuilder<HotelRoom?>(
      future: _tourismService
          .getHotelRoomById(booking.roomId),
      builder: (context, roomSnapshot) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _loadGuest(booking.userId),
          builder: (context, guestSnapshot) {
            final guestData =
                guestSnapshot.data ??
                    <String, dynamic>{};

            final String guestName =
                guestData['name']?.toString() ??
                    guestData['fullName']
                        ?.toString() ??
                    'Guest';
            final String guestPhone =
                guestData['phoneNumber']
                        ?.toString() ??
                    guestData['phone']
                        ?.toString() ??
                    'Not available';
            final String roomName =
                roomSnapshot.data?.name ??
                    'Hotel Room';

            return Container(
              margin:
                  const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: darkCard,
                borderRadius:
                    BorderRadius.circular(17),
                border: Border.all(
                  color: _statusColor(
                    booking.bookingStatus,
                  ).withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor:
                            Color(0x22FFD60A),
                        child: Icon(
                          Icons.person_outline,
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
                              guestName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$roomName • #${_shortId(booking.id)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _statusBadge(
                        booking.bookingStatus,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailRow('Phone', guestPhone),
                  _detailRow(
                    'Check-in',
                    _formatDate(booking.checkIn),
                  ),
                  _detailRow(
                    'Check-out',
                    _formatDate(booking.checkOut),
                  ),
                  _detailRow(
                    'Guests / Rooms',
                    '${booking.guests} / ${booking.rooms}',
                  ),
                  _detailRow(
                    'Remaining Payment',
                    'Rs. ${booking.remainingAmount.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 10),
                  if (booking.bookingStatus ==
                      'confirmed')
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isWorking
                                ? null
                                : () => _markNoShow(
                                      booking,
                                    ),
                            icon: const Icon(
                              Icons
                                  .person_off_outlined,
                            ),
                            label:
                                const Text('No Show'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isWorking
                                ? null
                                : () => _confirmCheckIn(
                                      booking,
                                      guestName,
                                    ),
                            icon:
                                const Icon(Icons.login),
                            label: const Text(
                              'Normal Check-in',
                            ),
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor: yellow,
                              foregroundColor:
                                  Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (booking.bookingStatus ==
                      'checked_in')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isWorking
                            ? null
                            : () => _confirmCheckOut(
                                  booking,
                                  guestName,
                                ),
                        icon:
                            const Icon(Icons.logout),
                        label: const Text(
                          'Check-out Guest',
                        ),
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor: yellow,
                          foregroundColor:
                              Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmCheckIn(
    HotelBooking booking,
    String guestName,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Normal Check-in',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Check in $guestName without QR/PIN verification? Use this only after manually checking identification.',
            style: const TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Check-in'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _checkIn(booking);
    }
  }

  Future<void> _confirmCheckOut(
    HotelBooking booking,
    String guestName,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Confirm Check-out',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Confirm that $guestName has checked out and the stay is completed?',
            style: const TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Check-out'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _checkOut(booking);
    }
  }

  Future<void> _markNoShow(
    HotelBooking booking,
  ) async {
    final TextEditingController noteController =
        TextEditingController();

    final String? note =
        await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Mark No Show',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: noteController,
            maxLines: 3,
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: const InputDecoration(
              hintText:
                  'Optional note about guest absence',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  noteController.text.trim(),
                );
              },
              child:
                  const Text('Mark No Show'),
            ),
          ],
        );
      },
    );

    noteController.dispose();

    if (note == null) return;

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
      _isWorking = true;
    });

    try {
      await _bookingService.markNoShow(
        booking: booking,
        agentUserId: user.uid,
        note: note,
      );
      _showMessage(
        'Booking marked as no show.',
      );
    } catch (error) {
      _showMessage(
        error.toString(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _checkIn(
    HotelBooking booking,
  ) async {
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
      _isWorking = true;
    });

    try {
      await _bookingService.markCheckedIn(
        booking: booking,
        agentUserId: user.uid,
      );

      await _firestore
          .collection('hotel_bookings')
          .doc(booking.id)
          .set(
        <String, dynamic>{
          'checkInMethod':
              'manual_staff_override',
          'checkedInBy': user.uid,
          'checkedInAt':
              FieldValue.serverTimestamp(),
          'qrIsActive': false,
          'verificationPinIsActive': false,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _showMessage(
        'Guest checked in successfully.',
      );
    } catch (error) {
      _showMessage(
        error.toString(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _checkOut(
    HotelBooking booking,
  ) async {
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
      _isWorking = true;
    });

    try {
      await _bookingService.markCheckedOut(
        booking: booking,
        agentUserId: user.uid,
      );
      _showMessage(
        'Guest checked out. Stay completed.',
      );
    } catch (error) {
      _showMessage(
        error.toString(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _loadGuest(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      return snapshot.data() ??
          <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  int _readInt(
    dynamic value,
    int fallback,
  ) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
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
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final Color color =
        _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(icon, color: yellow, size: 48),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'checked_in':
        return Colors.blue;
      case 'completed':
        return Colors.teal;
      case 'no_show':
        return Colors.orange;
      default:
        return yellow;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_hotel_confirmation':
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'checked_in':
        return 'Checked In';
      case 'completed':
      case 'checked_out':
        return 'Completed';
      case 'no_show':
        return 'No Show';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final String day =
        date.day.toString().padLeft(2, '0');
    final String month =
        date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _shortId(String id) {
    if (id.length <= 8) {
      return id.toUpperCase();
    }
    return id
        .substring(0, 8)
        .toUpperCase();
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

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

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final Iterator<T> iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
