import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/hotel_booking.dart';
import '../models/hotel_room.dart';
import '../services/hotel_booking_operations_service.dart';
import '../services/tourism_service.dart';
import '../safety/models/safety_models.dart';
import '../safety/screens/safety_center_screen.dart';
import 'hotel_guest_chat_screen.dart';

class HotelBookingRequestsScreen extends StatefulWidget {
  const HotelBookingRequestsScreen({super.key, required this.hotelId});

  final String hotelId;

  @override
  State<HotelBookingRequestsScreen> createState() =>
      _HotelBookingRequestsScreenState();
}

class _HotelBookingRequestsScreenState
    extends State<HotelBookingRequestsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final HotelBookingOperationsService _bookingService =
      HotelBookingOperationsService();

  final TourismService _tourismService = TourismService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedFilter = 'all';
  bool _isWorking = false;

  final List<String> _filters = const <String>[
    'all',
    'pending',
    'confirmed',
    'checked_in',
    'completed',
    'rejected',
    'cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Hotel Booking Requests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<HotelBooking>>(
          stream: _bookingService.hotelBookingsStream(widget.hotelId),
          builder: (context, AsyncSnapshot<List<HotelBooking>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: yellow),
              );
            }

            if (snapshot.hasError) {
              return _messageState(
                icon: Icons.error_outline,
                title: 'Unable to Load Bookings',
                message: snapshot.error.toString(),
              );
            }

            final List<HotelBooking> allBookings =
                snapshot.data ?? <HotelBooking>[];

            final List<HotelBooking> bookings = allBookings.where((booking) {
              if (_selectedFilter == 'all') {
                return true;
              }

              if (_selectedFilter == 'pending') {
                return booking.bookingStatus == 'pending' ||
                    booking.bookingStatus == 'pending_hotel_confirmation';
              }

              return booking.bookingStatus == _selectedFilter;
            }).toList();

            return Column(
              children: [
                _filterBar(allBookings),

                Expanded(
                  child: bookings.isEmpty
                      ? _messageState(
                          icon: Icons.book_online_outlined,
                          title: 'No Bookings Found',
                          message:
                              'There are no hotel bookings in this category.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            return _bookingCard(bookings[index]);
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

  Widget _filterBar(List<HotelBooking> bookings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: darkBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filters.map((filter) {
            final bool selected = _selectedFilter == filter;

            final int count = bookings.where((booking) {
              if (filter == 'all') {
                return true;
              }

              if (filter == 'pending') {
                return booking.bookingStatus == 'pending' ||
                    booking.bookingStatus == 'pending_hotel_confirmation';
              }

              return booking.bookingStatus == filter;
            }).length;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: selected,
                label: Text('${_statusLabel(filter)} ($count)'),
                selectedColor: yellow.withValues(alpha: 0.25),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.grey,
                ),
                side: BorderSide(
                  color: selected
                      ? yellow
                      : Colors.white.withValues(alpha: 0.06),
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _bookingCard(HotelBooking booking) {
    return FutureBuilder<HotelRoom?>(
      future: _tourismService.getHotelRoomById(booking.roomId),
      builder: (context, AsyncSnapshot<HotelRoom?> snapshot) {
        final String roomName = snapshot.data?.name ?? 'Hotel Room';

        return InkWell(
          onTap: () {
            _openBookingDetails(booking: booking, room: snapshot.data);
          },
          borderRadius: BorderRadius.circular(17),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: darkCard,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: _statusColor(
                  booking.bookingStatus,
                ).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: yellow.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.hotel, color: yellow),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roomName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Booking #${_shortId(booking.id)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _statusBadge(booking.bookingStatus),
                  ],
                ),

                const SizedBox(height: 14),

                _detailRow('Check-in', _formatDate(booking.checkIn)),

                _detailRow('Check-out', _formatDate(booking.checkOut)),

                _detailRow(
                  'Guests / Rooms',
                  '${booking.guests} guests ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ${booking.rooms} rooms',
                ),

                _detailRow(
                  'Total',
                  'Rs. ${booking.totalAmount.toStringAsFixed(0)}',
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _openBookingDetails(
                            booking: booking,
                            room: snapshot.data,
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: yellow,
                          side: const BorderSide(color: yellow),
                        ),
                      ),
                    ),

                    if (_isPending(booking.bookingStatus)) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isWorking
                              ? null
                              : () {
                                  _acceptBooking(booking);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: yellow,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openBookingDetails({
    required HotelBooking booking,
    required HotelRoom? room,
  }) async {
    final Map<String, dynamic> userData = await _loadUserData(booking.userId);

    if (!mounted) {
      return;
    }

    final String guestName =
        userData['name']?.toString() ??
        userData['fullName']?.toString() ??
        'Guest';

    final String guestPhone =
        userData['phoneNumber']?.toString() ??
        userData['phone']?.toString() ??
        'Not available';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: darkBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Booking Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _statusBadge(booking.bookingStatus),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _sectionCard(
                    title: 'Guest Information',
                    children: [
                      _detailRow('Guest', guestName),
                      _detailRow('Phone', guestPhone),
                      _detailRow('User ID', booking.userId),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _sectionCard(
                    title: 'Stay Information',
                    children: [
                      _detailRow('Room', room?.name ?? 'Hotel Room'),
                      _detailRow(
                        'Room Type',
                        room?.roomType ?? 'Not available',
                      ),
                      _detailRow('Check-in', _formatDate(booking.checkIn)),
                      _detailRow('Check-out', _formatDate(booking.checkOut)),
                      _detailRow('Nights', '${booking.nights}'),
                      _detailRow('Guests', '${booking.guests}'),
                      _detailRow('Rooms', '${booking.rooms}'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _sectionCard(
                    title: 'Payment Summary',
                    children: [
                      _detailRow(
                        'Price / Night',
                        'Rs. ${booking.pricePerNight.toStringAsFixed(0)}',
                      ),
                      _detailRow(
                        'Total',
                        'Rs. ${booking.totalAmount.toStringAsFixed(0)}',
                      ),
                      _detailRow(
                        'Advance',
                        'Rs. ${booking.advanceAmount.toStringAsFixed(0)}',
                      ),
                      _detailRow(
                        'Remaining',
                        'Rs. ${booking.remainingAmount.toStringAsFixed(0)}',
                      ),
                      _detailRow('Payment', booking.paymentStatus),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _actionButtons(booking, sheetContext, guestPhone),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionButtons(
    HotelBooking booking,
    BuildContext sheetContext,
    String guestPhone,
  ) {
    final List<Widget> buttons = <Widget>[];

    if (_isPending(booking.bookingStatus)) {
      buttons.addAll([
        _actionButton(
          title: 'Accept Booking',
          icon: Icons.check_circle_outline,
          onPressed: () {
            Navigator.pop(sheetContext);
            _acceptBooking(booking);
          },
        ),
        _actionButton(
          title: 'Reject Booking',
          icon: Icons.cancel_outlined,
          isDanger: true,
          onPressed: () {
            Navigator.pop(sheetContext);
            _rejectBooking(booking);
          },
        ),
      ]);
    }

    if (booking.bookingStatus == 'confirmed') {
      buttons.add(
        _actionButton(
          title: 'Mark Check-in',
          icon: Icons.login,
          onPressed: () {
            Navigator.pop(sheetContext);
            _checkIn(booking);
          },
        ),
      );
    }

    if (booking.bookingStatus == 'checked_in') {
      buttons.add(
        _actionButton(
          title: 'Mark Check-out',
          icon: Icons.logout,
          onPressed: () {
            Navigator.pop(sheetContext);
            _checkOut(booking);
          },
        ),
      );
    }

    buttons.addAll([
      _actionButton(
        title: 'Chat with Guest',
        icon: Icons.chat_bubble_outline,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => HotelGuestChatScreen(
                chatId: booking.id,
                bookingId: booking.id,
                hotelId: booking.hotelId,
                userId: booking.userId,
                guestName: 'Guest',
              ),
            ),
          );
        },
      ),
      _actionButton(
        title: 'Safety & SOS',
        icon: Icons.shield_outlined,
        isDanger: true,
        onPressed: () {
          Navigator.pop(sheetContext);
          _openUniversalHotelOwnerSafety(booking);
        },
      ),
      _actionButton(
        title: 'Call Guest',
        icon: Icons.call_outlined,
        onPressed: () {
          _callGuest(guestPhone);
        },
      ),
    ]);

    return Column(children: buttons);
  }

  void _openUniversalHotelOwnerSafety(HotelBooking booking) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showMessage('Please log in first.', isError: true);
      return;
    }

    final String status = booking.bookingStatus.trim().toLowerCase();

    final bool activeStay = <String>{
      'checked_in',
      'active',
      'in_stay',
    }.contains(status);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return SafetyCenterScreen(
            contextData: SafetyContext(
              serviceType: activeStay
                  ? SafetyServiceType.hotelStay
                  : SafetyServiceType.hotelBooking,
              referenceId: booking.id,
              initiatedByUserId: currentUser.uid,
              initiatedByRole: SafetyUserRole.hotelOwner,
              sourcePage: activeStay
                  ? SafetySourcePage.activeHotelStay
                  : SafetySourcePage.hotelBookingDetails,
              referenceStatus: booking.bookingStatus,
              primaryPerson: SafetyPersonSnapshot(
                userId: booking.userId,
                role: SafetyUserRole.hotelGuest,
              ),
              serviceTitle: activeStay
                  ? 'Hotel Stay Safety'
                  : 'Hotel Booking Safety',
              serviceSubtitle: 'Hotel Owner / Partner',
              metadata: <String, dynamic>{
                'bookingId': booking.id,
                'hotelId': booking.hotelId,
                'roomId': booking.roomId,
                'bookingStatus': booking.bookingStatus,
                'paymentStatus': booking.paymentStatus,
                'totalAmount': booking.totalAmount,
                'checkIn': booking.checkIn.toIso8601String(),
                'checkOut': booking.checkOut.toIso8601String(),
                'activeStay': activeStay,

                // Sensitive guest identity data such as
                // phone number or CNIC is intentionally
                // excluded from Safety metadata.
              },
            ),
          );
        },
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
    bool isDanger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isWorking ? null : onPressed,
          icon: Icon(icon),
          label: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDanger ? Colors.red : yellow,
            foregroundColor: isDanger ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: yellow, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
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
    final Color color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
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

  Widget _messageState({
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
                style: const TextStyle(color: Colors.grey, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadUserData(String userId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      return snapshot.data() ?? <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _acceptBooking(HotelBooking booking) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in first.', isError: true);
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      await _bookingService.acceptBooking(
        booking: booking,
        agentUserId: user.uid,
      );

      _showMessage('Booking accepted successfully.');
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _rejectBooking(HotelBooking booking) async {
    final TextEditingController reasonController = TextEditingController();

    final String? reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Reject Booking',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter rejection reason',
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
                Navigator.pop(dialogContext, reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null || reason.isEmpty) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in first.', isError: true);
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      await _bookingService.rejectBooking(
        booking: booking,
        agentUserId: user.uid,
        reason: reason,
      );

      _showMessage('Booking rejected.');
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _checkIn(HotelBooking booking) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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

      _showMessage('Guest checked in.');
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _checkOut(HotelBooking booking) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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

      _showMessage('Guest checked out. Booking completed.');
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  bool _isPending(String status) {
    return status == 'pending' || status == 'pending_hotel_confirmation';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'checked_in':
        return Colors.blue;
      case 'completed':
        return Colors.teal;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'no_show':
        return Colors.orange;
      default:
        return yellow;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'all':
        return 'All';
      case 'pending':
      case 'pending_hotel_confirmation':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'checked_in':
        return 'Checked In';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _shortId(String id) {
    if (id.length <= 8) {
      return id.toUpperCase();
    }

    return id.substring(0, 8).toUpperCase();
  }

  Future<void> _callGuest(String guestPhone) async {
    final String cleanPhone = guestPhone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (guestPhone == 'Not available' || cleanPhone.isEmpty) {
      _showMessage('Guest phone number is not available.', isError: true);
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      final bool opened = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        _showMessage('Unable to open the phone dialer.', isError: true);
      }
    } catch (error) {
      _showMessage('Unable to call guest: $error', isError: true);
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
