import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/tour_booking.dart';
import '../models/tourism_driver_application.dart';
import '../services/tour_booking_service.dart';
import '../services/tourism_driver_application_service.dart';

import '../feedback/models/feedback_model.dart';
import '../feedback/models/feedback_reply_model.dart';
import '../feedback/partner/partner_reviews_screen.dart';
import '../feedback/partner/review_reply_screen.dart';

class TourismDriverDashboardScreen extends StatefulWidget {
  const TourismDriverDashboardScreen({super.key});

  @override
  State<TourismDriverDashboardScreen> createState() =>
      _TourismDriverDashboardScreenState();
}

class _TourismDriverDashboardScreenState
    extends State<TourismDriverDashboardScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TourismDriverApplicationService _applicationService =
      TourismDriverApplicationService();
  final TourBookingService _tourBookingService = TourBookingService();

  bool _isUpdatingAvailability = false;
  bool _isWorking = false;
  String _selectedTab = 'assigned';

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final User? user = _currentUser;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Tourism Driver Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: user == null
          ? _messageState(
              icon: Icons.lock_outline,
              title: 'Login Required',
              message: 'Please log in to open the Tourism Driver Dashboard.',
            )
          : StreamBuilder<TourismDriverApplication?>(
              stream: _applicationService.watchApplicationByUserId(user.uid),
              builder:
                  (context, AsyncSnapshot<TourismDriverApplication?> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: yellow),
                      );
                    }

                    if (snapshot.hasError) {
                      return _messageState(
                        icon: Icons.error_outline,
                        title: 'Unable to Load Dashboard',
                        message: snapshot.error.toString(),
                      );
                    }

                    final TourismDriverApplication? application = snapshot.data;

                    if (application == null) {
                      return _messageState(
                        icon: Icons.tour_outlined,
                        title: 'No Tourism Driver Application',
                        message:
                            'Submit a Tourism Driver application first. The dashboard becomes active after admin approval.',
                      );
                    }

                    if (!application.isApproved) {
                      return _applicationStatus(application);
                    }

                    return _approvedDashboard(
                      application: application,
                      userId: user.uid,
                    );
                  },
            ),
    );
  }

  Widget _applicationStatus(TourismDriverApplication application) {
    final String status = application.applicationStatus;

    String title = 'Application Status';
    String message = 'Current status: $status';
    IconData icon = Icons.info_outline;

    switch (status) {
      case 'draft':
        title = 'Draft Application';
        message =
            'Complete and submit your Tourism Driver application for admin review.';
        icon = Icons.edit_note;
        break;
      case 'submitted':
        title = 'Application Submitted';
        message = 'Your application is waiting for SWAT RIDE admin review.';
        icon = Icons.schedule;
        break;
      case 'under_review':
        title = 'Application Under Review';
        message =
            'SWAT RIDE admin is reviewing your Tourism Driver application.';
        icon = Icons.manage_search;
        break;
      case 'changes_requested':
        title = 'Changes Requested';
        message = application.adminNote.trim().isEmpty
            ? 'Admin requested changes in your application.'
            : application.adminNote;
        icon = Icons.edit_document;
        break;
      case 'rejected':
        title = 'Application Rejected';
        message = application.rejectionReason.trim().isEmpty
            ? 'Your application was rejected. Contact support for details.'
            : application.rejectionReason;
        icon = Icons.cancel_outlined;
        break;
      case 'suspended':
        title = 'Driver Access Suspended';
        message = application.adminNote.trim().isEmpty
            ? 'Your Tourism Driver access is currently suspended.'
            : application.adminNote;
        icon = Icons.block;
        break;
    }

    return _messageState(icon: icon, title: title, message: message);
  }

  Widget _approvedDashboard({
    required TourismDriverApplication application,
    required String userId,
  }) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection(TourismDriverApplicationService.collectionName)
          .doc(application.id)
          .snapshots(),
      builder:
          (
            context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
            profileSnapshot,
          ) {
            final Map<String, dynamic> profileData =
                profileSnapshot.data?.data() ?? <String, dynamic>{};

            final bool isAvailable = profileData['isAvailable'] == true;
            final bool gpsTrackingReady =
                profileData['gpsTrackingReady'] != false;
            final double rating = _readNumber(profileData['rating']);
            final int completedTours = _readInt(profileData['completedTours']);

            return RefreshIndicator(
              color: yellow,
              backgroundColor: darkCard,
              onRefresh: () async {
                await _firestore
                    .collection(TourismDriverApplicationService.collectionName)
                    .doc(application.id)
                    .get();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _profileHeader(
                    application: application,
                    isAvailable: isAvailable,
                    gpsTrackingReady: gpsTrackingReady,
                  ),

                  const SizedBox(height: 16),

                  _statsSection(
                    userId: userId,
                    application: application,
                    rating: rating,
                    completedTours: completedTours,
                  ),

                  const SizedBox(height: 18),

                  _quickActions(
                    application: application,
                    userId: userId,
                    isAvailable: isAvailable,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Tour Assignments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _assignmentTabs(userId),

                  const SizedBox(height: 12),

                  _assignmentList(application: application, userId: userId),

                  const SizedBox(height: 20),

                  _earningsCard(userId),

                  const SizedBox(height: 18),

                  _billingNotice(),
                ],
              ),
            );
          },
    );
  }

  Widget _profileHeader({
    required TourismDriverApplication application,
    required bool isAvailable,
    required bool gpsTrackingReady,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: yellow.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: yellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.tour_outlined, color: yellow, size: 31),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${application.vehicleType} â€¢ ${application.vehicleNumber}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          gpsTrackingReady ? Icons.gps_fixed : Icons.gps_off,
                          size: 14,
                          color: gpsTrackingReady
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          gpsTrackingReady ? 'GPS Ready' : 'GPS Not Ready',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _statusBadge(isAvailable ? 'available' : 'offline'),
            ],
          ),
          const SizedBox(height: 15),
          SwitchListTile(
            value: isAvailable,
            onChanged: _isUpdatingAvailability
                ? null
                : (value) {
                    _updateAvailability(
                      applicationId: application.id,
                      isAvailable: value,
                    );
                  },
            activeThumbColor: yellow,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Available for Tourism Jobs',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              isAvailable
                  ? 'You can receive new tour assignments.'
                  : 'New assignments are paused.',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsSection({
    required String userId,
    required TourismDriverApplication application,
    required double rating,
    required int completedTours,
  }) {
    return StreamBuilder<List<TourBooking>>(
      stream: _tourBookingService.driverBookingsStream(userId),
      builder: (context, snapshot) {
        final List<TourBooking> bookings = snapshot.data ?? <TourBooking>[];

        int assigned = 0;
        int active = 0;
        int completed = completedTours;

        for (final TourBooking booking in bookings) {
          if (booking.bookingStatus == 'confirmed' ||
              booking.bookingStatus == 'assigned' ||
              booking.bookingStatus == 'accepted') {
            assigned++;
          } else if (booking.bookingStatus == 'started' ||
              booking.bookingStatus == 'in_progress' ||
              booking.bookingStatus == 'arrived') {
            active++;
          } else if (booking.bookingStatus == 'completed') {
            completed++;
          }
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _statCard(
              icon: Icons.assignment_outlined,
              title: 'Assigned',
              value: '$assigned',
            ),
            _statCard(
              icon: Icons.route_outlined,
              title: 'Active Tours',
              value: '$active',
            ),
            _statCard(
              icon: Icons.task_alt,
              title: 'Completed',
              value: '$completed',
            ),
            _statCard(
              icon: Icons.star_outline,
              title: 'Rating',
              value: rating <= 0 ? 'New' : rating.toStringAsFixed(1),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: yellow, size: 26),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _quickActions({
    required TourismDriverApplication application,
    required String userId,
    required bool isAvailable,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _actionCard(
          icon: Icons.location_on_outlined,
          title: 'Update Location',
          subtitle: 'Save current GPS status',
          onTap: () {
            _updateGpsStatus(application.id);
          },
        ),
        _actionCard(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Tour alerts and updates',
          onTap: () {
            _showNotificationSummary(userId);
          },
        ),
        _actionCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Wallet',
          subtitle: 'Earnings and commission',
          onTap: () {
            _showWalletDetails(userId);
          },
        ),
        _actionCard(
          icon: Icons.rate_review_outlined,
          title: 'My Reviews',
          subtitle: 'Tour ratings and replies',
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => PartnerReviewsScreen(
                  serviceType: FeedbackServiceType.tour,
                  targetType: FeedbackTargetType.tourismDriver,
                  targetId: userId,
                  partnerName: application.fullName,
                  onReplyRequested: (review) {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => ReviewReplyScreen(
                          review: review,
                          authorId: userId,
                          authorName: application.fullName,
                          authorType: FeedbackReplyAuthorType.tourismDriver,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        _actionCard(
          icon: Icons.support_agent,
          title: 'Support',
          subtitle: 'Contact SWAT RIDE admin',
          onTap: _showSupportDialog,
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: yellow, size: 28),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assignmentTabs(String userId) {
    const List<String> tabs = <String>['assigned', 'active', 'history'];

    return Row(
      children: tabs.map((tab) {
        final bool selected = _selectedTab == tab;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: tab == 'history' ? 0 : 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                });
              },
              borderRadius: BorderRadius.circular(13),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected ? yellow : darkCard,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabLabel(tab),
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _assignmentList({
    required TourismDriverApplication application,
    required String userId,
  }) {
    return StreamBuilder<List<TourBooking>>(
      stream: _tourBookingService.driverBookingsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: yellow),
            ),
          );
        }

        if (snapshot.hasError) {
          return _messageState(
            icon: Icons.error_outline,
            title: 'Unable to Load Assignments',
            message: snapshot.error.toString(),
          );
        }

        final List<TourBooking> bookings = snapshot.data ?? <TourBooking>[];

        final List<TourBooking> filtered = bookings.where((booking) {
          if (_selectedTab == 'assigned') {
            return booking.bookingStatus == 'confirmed' ||
                booking.bookingStatus == 'assigned' ||
                booking.bookingStatus == 'accepted';
          }

          if (_selectedTab == 'active') {
            return booking.bookingStatus == 'started' ||
                booking.bookingStatus == 'in_progress' ||
                booking.bookingStatus == 'arrived';
          }

          return booking.bookingStatus == 'completed' ||
              booking.bookingStatus == 'cancelled' ||
              booking.bookingStatus == 'rejected';
        }).toList();

        if (filtered.isEmpty) {
          return _messageState(
            icon: _selectedTab == 'history'
                ? Icons.history
                : Icons.assignment_outlined,
            title: _selectedTab == 'history'
                ? 'No Tour History'
                : 'No Tour Assignments',
            message: _selectedTab == 'assigned'
                ? 'New confirmed assignments from SWAT RIDE admin will appear here.'
                : _selectedTab == 'active'
                ? 'Started and active tours will appear here.'
                : 'Completed, cancelled and rejected tours will appear here.',
          );
        }

        return Column(
          children: filtered.map((TourBooking booking) {
            return _bookingAssignmentCard(
              application: application,
              booking: booking,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _bookingAssignmentCard({
    required TourismDriverApplication application,
    required TourBooking booking,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _statusColor(booking.bookingStatus).withValues(alpha: 0.32),
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
                child: const Icon(Icons.map_outlined, color: yellow, size: 27),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.destination.isEmpty
                          ? 'Tour Destination'
                          : booking.destination,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tourTypeLabel(booking.tourType),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _statusBadge(booking.bookingStatus),
            ],
          ),
          const SizedBox(height: 13),
          _detailRow('Booking ID', _shortId(booking.id)),
          _detailRow(
            'Pickup',
            booking.startLocation.isEmpty
                ? 'Pickup location not set'
                : booking.startLocation,
          ),
          _detailRow(
            'Tour Dates',
            '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
          ),
          _detailRow('Guests', '${booking.guests}'),
          _detailRow(
            'Vehicle',
            booking.vehicleId.isEmpty
                ? application.vehicleType
                : booking.vehicleId,
          ),
          _detailRow(
            'Hotel',
            booking.hotelId.isEmpty ? 'Not included' : booking.hotelId,
          ),
          _detailRow('Payment', _statusLabel(booking.paymentStatus)),
          const SizedBox(height: 10),
          _tourBookingActions(booking: booking),
        ],
      ),
    );
  }

  Widget _tourBookingActions({required TourBooking booking}) {
    if (booking.bookingStatus == 'confirmed' ||
        booking.bookingStatus == 'assigned') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isWorking ? null : () => _rejectTourBooking(booking),
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isWorking ? null : () => _acceptTourBooking(booking),
              icon: const Icon(Icons.check),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      );
    }

    if (booking.bookingStatus == 'accepted') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isWorking ? null : () => _startTourBooking(booking),
          icon: const Icon(Icons.play_arrow),
          label: const Text(
            'Start Tour',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: yellow,
            foregroundColor: Colors.black,
          ),
        ),
      );
    }

    if (booking.bookingStatus == 'started' ||
        booking.bookingStatus == 'in_progress') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isWorking ? null : () => _markTourArrived(booking),
              icon: const Icon(Icons.location_on),
              label: const Text('Arrived'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isWorking
                  ? null
                  : () => _completeTourBooking(booking),
              icon: const Icon(Icons.task_alt),
              label: const Text(
                'Complete',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      );
    }

    if (booking.bookingStatus == 'arrived') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isWorking ? null : () => _completeTourBooking(booking),
          icon: const Icon(Icons.task_alt),
          label: const Text(
            'Complete Tour',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: yellow,
            foregroundColor: Colors.black,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _acceptTourBooking(TourBooking booking) async {
    final String actorUserId = _currentUser?.uid ?? '';

    setState(() {
      _isWorking = true;
    });

    try {
      await _tourBookingService.acceptBooking(
        bookingId: booking.id,
        actorUserId: actorUserId,
      );

      _showMessage('Tour assignment accepted.');
    } catch (error) {
      _showMessage('Unable to accept assignment: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _rejectTourBooking(TourBooking booking) async {
    final TextEditingController reasonController = TextEditingController();

    final String? reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Reject Tour Assignment',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
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
                final String value = reasonController.text.trim();
                if (value.isEmpty) {
                  return;
                }
                Navigator.pop(dialogContext, value);
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

    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    final String actorUserId = _currentUser?.uid ?? '';

    setState(() {
      _isWorking = true;
    });

    try {
      await _tourBookingService.rejectBooking(
        bookingId: booking.id,
        reason: reason.trim(),
        actorUserId: actorUserId,
      );

      _showMessage('Tour assignment rejected.');
    } catch (error) {
      _showMessage('Unable to reject assignment: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _startTourBooking(TourBooking booking) async {
    final String actorUserId = _currentUser?.uid ?? '';

    setState(() {
      _isWorking = true;
    });

    try {
      await _tourBookingService.startTour(booking.id, actorUserId: actorUserId);

      _showMessage('Tour started successfully.');
    } catch (error) {
      _showMessage('Unable to start tour: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _markTourArrived(TourBooking booking) async {
    final String actorUserId = _currentUser?.uid ?? '';

    setState(() {
      _isWorking = true;
    });

    try {
      await _tourBookingService.markArrived(
        booking.id,
        actorUserId: actorUserId,
      );

      _showMessage('Arrival status updated.');
    } catch (error) {
      _showMessage('Unable to update arrival: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _completeTourBooking(TourBooking booking) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Complete Tour',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Confirm that the assigned tour has been completed successfully?',
            style: TextStyle(color: Colors.grey, height: 1.4),
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
              child: const Text('Complete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final String actorUserId = _currentUser?.uid ?? '';

    setState(() {
      _isWorking = true;
    });

    try {
      await _tourBookingService.completeBooking(
        booking.id,
        actorUserId: actorUserId,
      );

      await _firestore
          .collection(TourismDriverApplicationService.collectionName)
          .doc(
            (await _applicationService.getApplicationByUserId(actorUserId))?.id,
          )
          .set(<String, dynamic>{
            'completedTours': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      _showMessage('Tour completed successfully.');
    } catch (error) {
      _showMessage('Unable to complete tour: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Widget _earningsCard(String userId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('tourism_driver_wallet_transactions')
          .where('driverUserId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        final documents =
            snapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        double grossEarnings = 0;
        double commission = 0;
        double availableBalance = 0;
        double pending = 0;

        for (final document in documents) {
          final Map<String, dynamic> data = document.data();

          final String type = data['type']?.toString() ?? 'earning';
          final String status = data['status']?.toString() ?? 'completed';
          final double amount = _readNumber(data['amount']);

          if (type == 'earning') {
            grossEarnings += amount;

            if (status == 'completed') {
              availableBalance += amount;
            } else if (status == 'pending') {
              pending += amount;
            }
          } else if (type == 'commission') {
            commission += amount;

            if (status == 'completed') {
              availableBalance -= amount;
            }
          } else if (type == 'payout' && status == 'completed') {
            availableBalance -= amount;
          }
        }

        if (availableBalance < 0) {
          availableBalance = 0;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: yellow),
                  SizedBox(width: 9),
                  Text(
                    'Earnings & Commission',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _detailRow(
                'Available Balance',
                'Rs. ${availableBalance.toStringAsFixed(0)}',
              ),
              _detailRow(
                'Gross Earnings',
                'Rs. ${grossEarnings.toStringAsFixed(0)}',
              ),
              _detailRow(
                'Commission Deducted',
                'Rs. ${commission.toStringAsFixed(0)}',
              ),
              _detailRow('Pending Amount', 'Rs. ${pending.toStringAsFixed(0)}'),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateAvailability({
    required String applicationId,
    required bool isAvailable,
  }) async {
    setState(() {
      _isUpdatingAvailability = true;
    });

    try {
      await _firestore
          .collection(TourismDriverApplicationService.collectionName)
          .doc(applicationId)
          .set(<String, dynamic>{
            'isAvailable': isAvailable,
            'availabilityUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      _showMessage(
        isAvailable
            ? 'You are now available for tourism jobs.'
            : 'New tourism assignments are paused.',
      );
    } catch (error) {
      _showMessage('Unable to update availability: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingAvailability = false;
        });
      }
    }
  }

  Future<void> _updateGpsStatus(String applicationId) async {
    setState(() {
      _isWorking = true;
    });

    try {
      await _firestore
          .collection(TourismDriverApplicationService.collectionName)
          .doc(applicationId)
          .set(<String, dynamic>{
            'gpsTrackingReady': true,
            'lastGpsStatusUpdate': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      _showMessage('GPS tracking status updated.');
    } catch (error) {
      _showMessage('Unable to update GPS status: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _showNotificationSummary(String userId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final int unread = snapshot.docs
          .where((document) => document.data()['isRead'] != true)
          .length;

      _showInfoDialog(
        title: 'Tourism Notifications',
        message:
            'You have $unread unread notifications. Full notification inbox will be connected in the next dashboard step.',
      );
    } catch (error) {
      _showMessage('Unable to load notifications: $error', isError: true);
    }
  }

  Future<void> _showWalletDetails(String userId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('tourism_driver_wallet_transactions')
          .where('driverUserId', isEqualTo: userId)
          .get();

      double balance = 0;

      for (final document in snapshot.docs) {
        final Map<String, dynamic> data = document.data();

        final String type = data['type']?.toString() ?? '';
        final String status = data['status']?.toString() ?? '';
        final double amount = _readNumber(data['amount']);

        if (status != 'completed') {
          continue;
        }

        if (type == 'earning' || type == 'adjustment_credit') {
          balance += amount;
        } else if (type == 'commission' ||
            type == 'payout' ||
            type == 'adjustment_debit') {
          balance -= amount;
        }
      }

      if (balance < 0) {
        balance = 0;
      }

      _showInfoDialog(
        title: 'Tourism Driver Wallet',
        message:
            'Available balance: Rs. ${balance.toStringAsFixed(0)}\n\nReal payout settlement will be enabled after payment integration.',
      );
    } catch (error) {
      _showMessage('Unable to load wallet: $error', isError: true);
    }
  }

  void _showSupportDialog() {
    _showInfoDialog(
      title: 'SWAT RIDE Support',
      message:
          'Contact support for assignment, safety, payment or account issues. Dedicated tourism support chat and helpline will be connected in the support phase.',
    );
  }

  void _showInfoDialog({required String title, required String message}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.grey, height: 1.45),
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

  Widget _statusBadge(String status) {
    final Color color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
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

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
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
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billingNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yellow.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: yellow),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Assigned tours load directly from the tour_bookings collection. Drivers can accept or reject an assignment, then start, mark arrival and complete the tour in real Firestore. Live paid navigation, online payout and automatic settlement remain bypassed.',
              style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
            ),
          ),
        ],
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

  String _tabLabel(String tab) {
    switch (tab) {
      case 'active':
        return 'Active';
      case 'history':
        return 'History';
      default:
        return 'Assigned';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
      case 'accepted':
      case 'completed':
        return Colors.green;
      case 'started':
      case 'in_progress':
      case 'arrived':
        return Colors.blue;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'offline':
        return Colors.grey;
      default:
        return yellow;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'offline':
        return 'Offline';
      case 'pending_driver_response':
      case 'assigned':
      case 'confirmed':
        return 'Assigned';
      case 'accepted':
        return 'Accepted';
      case 'started':
      case 'in_progress':
        return 'In Progress';
      case 'arrived':
        return 'Arrived';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _tourTypeLabel(String value) {
    switch (value) {
      case 'group':
        return 'Group / Sharing Tour';
      case 'family':
        return 'Family Tour';
      default:
        return 'Private Tour';
    }
  }

  String _shortId(String id) {
    if (id.length <= 10) {
      return id.toUpperCase();
    }

    return id.substring(0, 10).toUpperCase();
  }

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _readNumber(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) {
      return 'Not set';
    }

    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
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
