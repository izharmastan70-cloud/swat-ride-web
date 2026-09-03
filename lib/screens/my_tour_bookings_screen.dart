import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/tour_booking.dart';
import '../services/tour_booking_service.dart';

import '../safety/models/safety_models.dart';
import '../safety/screens/safety_center_screen.dart';

import '../feedback/models/feedback_model.dart';
import '../feedback/screens/complaint_screen.dart';
import '../feedback/screens/submit_feedback_screen.dart';

class MyTourBookingsScreen extends StatefulWidget {
  const MyTourBookingsScreen({super.key});

  @override
  State<MyTourBookingsScreen> createState() => _MyTourBookingsScreenState();
}

class _MyTourBookingsScreenState extends State<MyTourBookingsScreen> {
  static const yellow = Color(0xFFFFD60A);
  static const darkCard = Color(0xFF1A1A1A);
  static const darkBackground = Color(0xFF0D0D0D);

  final TourBookingService _service = TourBookingService();
  final TextEditingController _searchController = TextEditingController();

  String _filter = 'all';
  String _search = '';
  String _workingId = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Tour Bookings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: user == null
          ? _empty(
              Icons.lock_outline,
              'Login Required',
              'Please log in to view your tour bookings.',
            )
          : StreamBuilder<List<TourBooking>>(
              stream: _service.userBookingsStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: yellow),
                  );
                }

                if (snapshot.hasError) {
                  return _empty(
                    Icons.error_outline,
                    'Unable to Load Bookings',
                    snapshot.error.toString(),
                  );
                }

                final bookings = snapshot.data ?? <TourBooking>[];
                final visible = _applyFilters(bookings);

                return RefreshIndicator(
                  color: yellow,
                  backgroundColor: darkCard,
                  onRefresh: () => _service.getUserBookings(user.uid),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _summary(bookings),
                      const SizedBox(height: 16),
                      _searchBox(),
                      const SizedBox(height: 12),
                      _filters(),
                      const SizedBox(height: 18),
                      if (visible.isEmpty)
                        _empty(
                          Icons.tour_outlined,
                          'No Tour Bookings',
                          _emptyMessage(),
                        )
                      else
                        ...visible.map(_bookingCard),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _summary(List<TourBooking> bookings) {
    final upcoming = bookings
        .where(
          (b) =>
              (b.isPending || b.isConfirmed) &&
              b.startDate.isAfter(DateTime.now()),
        )
        .length;
    final active = bookings.where((b) => b.isActive).length;
    final completed = bookings.where((b) => b.isCompleted).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: yellow.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          _summaryItem('Total', '${bookings.length}', Icons.receipt_long),
          _summaryItem('Upcoming', '$upcoming', Icons.event_available),
          _summaryItem('Active', '$active', Icons.directions_bus),
          _summaryItem('Completed', '$completed', Icons.task_alt),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: yellow, size: 22),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _search = value),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search destination, type or booking ID...',
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: yellow),
        suffixIcon: _search.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _search = '');
                },
                icon: const Icon(Icons.close, color: Colors.grey),
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

  Widget _filters() {
    const values = ['all', 'upcoming', 'active', 'completed', 'cancelled'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: values.map((value) {
          final selected = _filter == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text(_label(value)),
              selectedColor: yellow.withValues(alpha: 0.25),
              checkmarkColor: yellow,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (_) => setState(() => _filter = value),
            ),
          );
        }).toList(),
      ),
    );
  }

  FeedbackTargetType _tourFeedbackTargetType(TourBooking booking) {
    if (booking.guideId.trim().isNotEmpty) {
      return FeedbackTargetType.tourGuide;
    }
    if (booking.driverId.trim().isNotEmpty) {
      return FeedbackTargetType.tourismDriver;
    }
    return FeedbackTargetType.service;
  }

  String _tourFeedbackTargetId(TourBooking booking) {
    if (booking.guideId.trim().isNotEmpty) {
      return booking.guideId.trim();
    }
    if (booking.driverId.trim().isNotEmpty) {
      return booking.driverId.trim();
    }
    return 'swat_ride_tour_service';
  }

  String _tourFeedbackTargetName(TourBooking booking) {
    if (booking.guideId.trim().isNotEmpty) {
      return 'Assigned Tour Guide';
    }
    if (booking.driverId.trim().isNotEmpty) {
      return 'Assigned Tourism Driver';
    }
    return 'SWAT RIDE Tour Service';
  }

  Future<void> _openUniversalTourFeedback(TourBooking booking) async {
    final user = FirebaseAuth.instance.currentUser;
    final reviewerId = user?.uid.trim() ?? '';

    if (reviewerId.isEmpty) {
      _showFeedbackMessage('Please sign in to rate your Tour experience.');
      return;
    }
    if (!booking.isCompleted) {
      _showFeedbackMessage('Feedback is available after Tour completion.');
      return;
    }
    if (booking.userId.trim().isNotEmpty &&
        booking.userId.trim() != reviewerId) {
      _showFeedbackMessage('Only the booking customer can submit this review.');
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => SubmitFeedbackScreen(
          serviceType: FeedbackServiceType.tour,
          targetType: _tourFeedbackTargetType(booking),
          sourceId: booking.id,
          sourceReference: 'Tour ${_shortId(booking.id)}',
          reviewerId: reviewerId,
          reviewerName: user?.displayName?.trim() ?? '',
          reviewerPhotoUrl: user?.photoURL?.trim() ?? '',
          targetId: _tourFeedbackTargetId(booking),
          targetName: _tourFeedbackTargetName(booking),
          serviceCompleted: booking.isCompleted,
        ),
      ),
    );
  }

  Future<void> _openUniversalTourComplaint(TourBooking booking) async {
    final user = FirebaseAuth.instance.currentUser;
    final reporterId = user?.uid.trim() ?? '';

    if (reporterId.isEmpty) {
      _showFeedbackMessage('Please sign in to report a Tour problem.');
      return;
    }
    if (booking.userId.trim().isNotEmpty &&
        booking.userId.trim() != reporterId) {
      _showFeedbackMessage('Only the booking customer can report this Tour.');
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ComplaintScreen(
          serviceType: FeedbackServiceType.tour,
          sourceId: booking.id,
          sourceReference: 'Tour ${_shortId(booking.id)}',
          reporterId: reporterId,
          reporterName: user?.displayName?.trim() ?? '',
          reporterPhone: user?.phoneNumber?.trim() ?? '',
          targetType: _tourFeedbackTargetType(booking),
          targetId: _tourFeedbackTargetId(booking),
          targetName: _tourFeedbackTargetName(booking),
        ),
      ),
    );
  }

  void _showFeedbackMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _openUniversalTourSafety(TourBooking booking) {
    final user = FirebaseAuth.instance.currentUser;

    final SafetyPersonSnapshot? driver = booking.driverId.trim().isEmpty
        ? null
        : SafetyPersonSnapshot(
            userId: booking.driverId.trim(),
            role: SafetyUserRole.tourismDriver,
          );

    final SafetyPersonSnapshot? guide = booking.guideId.trim().isEmpty
        ? null
        : SafetyPersonSnapshot(
            userId: booking.guideId.trim(),
            role: SafetyUserRole.tourGuide,
          );

    final List<SafetyPersonSnapshot> relatedPeople = <SafetyPersonSnapshot>[
      ?driver,
      ?guide,
    ];

    final SafetyContext safetyContext = SafetyContext(
      serviceType: booking.isActive
          ? SafetyServiceType.activeTour
          : SafetyServiceType.tourBooking,
      referenceId: booking.id,
      initiatedByUserId: user?.uid ?? booking.userId,
      initiatedByRole: SafetyUserRole.tourCustomer,
      referenceStatus: booking.bookingStatus,
      primaryPerson: driver ?? guide,
      relatedPeople: relatedPeople,
      serviceTitle: booking.destination.trim().isEmpty
          ? 'Swat Tour'
          : booking.destination.trim(),
      serviceSubtitle: booking.tourType,
      metadata: <String, dynamic>{
        'packageId': booking.packageId,
        'startLocation': booking.startLocation,
        'destination': booking.destination,
        'startDate': booking.startDate.toIso8601String(),
        'endDate': booking.endDate.toIso8601String(),
        'guests': booking.guests,
        'vehicleId': booking.vehicleId,
        'hotelId': booking.hotelId,
        'driverId': booking.driverId,
        'guideId': booking.guideId,
        'totalAmount': booking.totalAmount,
        'advanceAmount': booking.advanceAmount,
        'remainingAmount': booking.remainingAmount,
        'paymentStatus': booking.paymentStatus,
      },
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SafetyCenterScreen(contextData: safetyContext),
      ),
    );
  }

  Widget _bookingCard(TourBooking booking) {
    final color = _statusColor(booking.bookingStatus);
    final working = _workingId == booking.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0x22FFD60A),
                child: Icon(Icons.landscape_outlined, color: yellow),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.destination.isEmpty
                          ? 'Swat Tour'
                          : booking.destination,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _tourType(booking.tourType),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _badge(booking.bookingStatus),
            ],
          ),
          const SizedBox(height: 14),
          _row('Booking ID', _shortId(booking.id)),
          _row('Start', _date(booking.startDate)),
          _row('End', _date(booking.endDate)),
          _row(
            'Pickup',
            booking.startLocation.isEmpty ? 'Not set' : booking.startLocation,
          ),
          _row('Guests', '${booking.guests}'),
          _row('Assignments', _assignmentSummary(booking)),
          _row('Payment', _label(booking.paymentStatus)),
          _row(
            'Total',
            booking.totalAmount <= 0
                ? 'Not available'
                : 'PKR ${_money(booking.totalAmount)}',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _details(booking),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Details'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openUniversalTourSafety(booking),
                icon: const Icon(Icons.shield_outlined),
                label: const Text('Safety & SOS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _timeline(booking),
                icon: const Icon(Icons.timeline),
                label: const Text('Timeline'),
              ),
              if (booking.isCompleted)
                OutlinedButton.icon(
                  onPressed: () => _openUniversalTourFeedback(booking),
                  icon: const Icon(Icons.star_rounded),
                  label: const Text('Rate Tour Experience'),
                  style: OutlinedButton.styleFrom(foregroundColor: yellow),
                ),
              if (booking.isCompleted)
                OutlinedButton.icon(
                  onPressed: () => _openUniversalTourComplaint(booking),
                  icon: const Icon(Icons.support_agent_rounded),
                  label: const Text('Report Tour Problem'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              if (_canCancel(booking))
                OutlinedButton.icon(
                  onPressed: working ? null : () => _cancel(booking),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(working ? 'Cancelling...' : 'Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(TourBooking booking) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: darkCard,
        title: const Text(
          'Cancel Tour Booking',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Cancellation reason (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      controller.dispose();
      return;
    }

    setState(() => _workingId = booking.id);

    try {
      await _service.cancelBooking(
        booking.id,
        reason: controller.text.trim(),
        actorUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
      );
      _message('Tour booking cancelled.');
    } catch (error) {
      _message('Unable to cancel booking: $error', error: true);
    } finally {
      controller.dispose();
      if (mounted) setState(() => _workingId = '');
    }
  }

  void _details(TourBooking booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Tour Booking Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              _row('Booking ID', booking.id),
              _row('Destination', booking.destination),
              _row('Tour Type', _tourType(booking.tourType)),
              _row('Pickup', booking.startLocation),
              _row('Start Date', _date(booking.startDate)),
              _row('End Date', _date(booking.endDate)),
              _row('Guests', '${booking.guests}'),
              const Divider(color: Colors.white12),
              _row(
                'Driver',
                booking.driverId.isEmpty ? 'Not assigned' : booking.driverId,
              ),
              _row(
                'Guide',
                booking.guideId.isEmpty ? 'Not assigned' : booking.guideId,
              ),
              _row(
                'Vehicle',
                booking.vehicleId.isEmpty ? 'Not assigned' : booking.vehicleId,
              ),
              _row(
                'Hotel',
                booking.hotelId.isEmpty ? 'Not assigned' : booking.hotelId,
              ),
              const Divider(color: Colors.white12),
              _row('Total', 'PKR ${_money(booking.totalAmount)}'),
              _row('Advance', 'PKR ${_money(booking.advanceAmount)}'),
              _row('Remaining', 'PKR ${_money(booking.remainingAmount)}'),
              _row('Payment', _label(booking.paymentStatus)),
              _row('Status', _label(booking.bookingStatus)),
              if (booking.specialRequest.isNotEmpty)
                _row('Request', booking.specialRequest),
              if (booking.cancellationReason.isNotEmpty)
                _row('Cancellation', booking.cancellationReason),
              if (booking.rejectionReason.isNotEmpty)
                _row('Rejection', booking.rejectionReason),
              const SizedBox(height: 14),
              const Text(
                'Testing mode is active. Firebase Storage and real payment gateway remain bypassed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _timeline(TourBooking booking) {
    const steps = ['pending', 'confirmed', 'started', 'arrived', 'completed'];
    int current = steps.indexOf(booking.bookingStatus);

    if (booking.bookingStatus == 'pending_admin_review') current = 0;
    if (booking.bookingStatus == 'in_progress') current = 2;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tour Timeline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              for (int index = 0; index < steps.length; index++)
                ListTile(
                  leading: Icon(
                    index <= current
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: index <= current ? yellow : Colors.grey,
                  ),
                  title: Text(
                    _label(steps[index]),
                    style: TextStyle(
                      color: index <= current ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              if (booking.isCancelled)
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.redAccent),
                  title: Text(
                    _label(booking.bookingStatus),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<TourBooking> _applyFilters(List<TourBooking> bookings) {
    final query = _search.trim().toLowerCase();

    return bookings.where((booking) {
      final searchMatch =
          query.isEmpty ||
          booking.destination.toLowerCase().contains(query) ||
          booking.tourType.toLowerCase().contains(query) ||
          booking.id.toLowerCase().contains(query);

      bool filterMatch = true;

      if (_filter == 'upcoming') {
        filterMatch =
            (booking.isPending || booking.isConfirmed) &&
            booking.startDate.isAfter(DateTime.now());
      } else if (_filter == 'active') {
        filterMatch = booking.isActive;
      } else if (_filter == 'completed') {
        filterMatch = booking.isCompleted;
      } else if (_filter == 'cancelled') {
        filterMatch = booking.isCancelled;
      }

      return searchMatch && filterMatch;
    }).toList();
  }

  bool _canCancel(TourBooking booking) {
    return (booking.isPending || booking.isConfirmed) &&
        booking.startDate.isAfter(DateTime.now());
  }

  String _assignmentSummary(TourBooking booking) {
    int count = 0;
    if (booking.driverId.isNotEmpty) count++;
    if (booking.guideId.isNotEmpty) count++;
    if (booking.vehicleId.isNotEmpty) count++;
    if (booking.hotelId.isNotEmpty) count++;
    return '$count of 4 assigned';
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
          const SizedBox(width: 12),
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

  Widget _empty(IconData icon, String title, String message) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: yellow, size: 46),
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
              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  String _emptyMessage() {
    switch (_filter) {
      case 'upcoming':
        return 'No upcoming tour booking found.';
      case 'active':
        return 'No active tour found.';
      case 'completed':
        return 'No completed tour found.';
      case 'cancelled':
        return 'No cancelled tour booking found.';
      default:
        return 'Your tour bookings will appear here after booking confirmation.';
    }
  }

  String _label(String value) {
    switch (value) {
      case 'all':
        return 'All';
      case 'upcoming':
        return 'Upcoming';
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
      case 'pending_admin_review':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'started':
      case 'in_progress':
        return 'Tour Started';
      case 'arrived':
        return 'Arrived';
      case 'rejected':
        return 'Rejected';
      case 'paid':
      case 'paid_testing':
        return 'Paid (Testing)';
      default:
        return value.replaceAll('_', ' ');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'started':
      case 'in_progress':
      case 'arrived':
        return Colors.blue;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'pending':
      case 'pending_admin_review':
        return Colors.orange;
      default:
        return yellow;
    }
  }

  String _tourType(String value) {
    switch (value) {
      case 'group':
        return 'Group / Sharing Tour';
      case 'family':
        return 'Family Tour';
      default:
        return 'Private Tour';
    }
  }

  String _date(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _money(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  String _shortId(String id) {
    return id.length <= 10
        ? id.toUpperCase()
        : id.substring(0, 10).toUpperCase();
  }

  void _message(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red : darkCard,
        ),
      );
  }
}
