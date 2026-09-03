import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/tour_booking.dart';
import '../services/tour_booking_service.dart';
import '../services/tour_guide_application_service.dart';

import '../feedback/models/feedback_model.dart';
import '../feedback/models/feedback_reply_model.dart';
import '../feedback/partner/partner_reviews_screen.dart';
import '../feedback/partner/review_reply_screen.dart';

class TourGuideDashboardScreen extends StatefulWidget {
  const TourGuideDashboardScreen({super.key});

  @override
  State<TourGuideDashboardScreen> createState() =>
      _TourGuideDashboardScreenState();
}

class _TourGuideDashboardScreenState extends State<TourGuideDashboardScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TourBookingService _tourBookingService = TourBookingService();

  String _selectedTab = 'assigned';
  bool _isWorking = false;
  bool _isUpdatingAvailability = false;

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
          'Tour Guide Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: user == null
          ? _messageState(
              icon: Icons.lock_outline,
              title: 'Login Required',
              message: 'Please log in to open the Tour Guide Dashboard.',
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection(TourGuideApplicationService.collectionName)
                  .where('userId', isEqualTo: user.uid)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
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

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return _messageState(
                    icon: Icons.badge_outlined,
                    title: 'No Tour Guide Application',
                    message:
                        'Submit a Tour Guide application first. Dashboard access becomes active after admin approval.',
                  );
                }

                final QueryDocumentSnapshot<Map<String, dynamic>> document =
                    snapshot.data!.docs.first;
                final Map<String, dynamic> data = document.data();

                final String status =
                    data['applicationStatus']?.toString() ?? 'draft';

                if (status != 'approved') {
                  return _applicationStatus(data);
                }

                return _approvedDashboard(
                  applicationId: document.id,
                  applicationData: data,
                  userId: user.uid,
                );
              },
            ),
    );
  }

  Widget _applicationStatus(Map<String, dynamic> data) {
    final String status = data['applicationStatus']?.toString() ?? 'draft';
    final String adminNote = data['adminNote']?.toString() ?? '';
    final String rejectionReason = data['rejectionReason']?.toString() ?? '';

    String title = 'Application Status';
    String message = 'Current status: $status';
    IconData icon = Icons.info_outline;

    switch (status) {
      case 'draft':
        title = 'Draft Application';
        message =
            'Complete and submit your Tour Guide application for admin review.';
        icon = Icons.edit_note;
        break;
      case 'submitted':
        title = 'Application Submitted';
        message = 'Your application is waiting for SWAT RIDE admin review.';
        icon = Icons.schedule;
        break;
      case 'under_review':
        title = 'Application Under Review';
        message = 'SWAT RIDE admin is reviewing your Tour Guide application.';
        icon = Icons.manage_search;
        break;
      case 'changes_requested':
        title = 'Changes Requested';
        message = adminNote.trim().isEmpty
            ? 'Admin requested changes in your application.'
            : adminNote;
        icon = Icons.edit_document;
        break;
      case 'rejected':
        title = 'Application Rejected';
        message = rejectionReason.trim().isEmpty
            ? 'Your application was rejected. Contact support for details.'
            : rejectionReason;
        icon = Icons.cancel_outlined;
        break;
      case 'suspended':
        title = 'Guide Access Suspended';
        message = adminNote.trim().isEmpty
            ? 'Your Tour Guide access is currently suspended.'
            : adminNote;
        icon = Icons.block;
        break;
    }

    return _messageState(icon: icon, title: title, message: message);
  }

  Widget _approvedDashboard({
    required String applicationId,
    required Map<String, dynamic> applicationData,
    required String userId,
  }) {
    final String fullName =
        applicationData['fullName']?.toString() ?? 'Tour Guide';
    final List<String> guideTypes = _stringList(applicationData['guideTypes']);
    final List<String> languages = _stringList(applicationData['languages']);
    final bool isAvailable = applicationData['isAvailable'] == true;
    final double rating = _readNumber(applicationData['rating']);
    final int completedTours = _readInt(applicationData['completedTours']);

    return RefreshIndicator(
      color: yellow,
      backgroundColor: darkCard,
      onRefresh: () async {
        await _firestore
            .collection(TourGuideApplicationService.collectionName)
            .doc(applicationId)
            .get();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _profileHeader(
            applicationId: applicationId,
            fullName: fullName,
            guideTypes: guideTypes,
            languages: languages,
            isAvailable: isAvailable,
          ),
          const SizedBox(height: 16),
          _statsSection(
            userId: userId,
            rating: rating,
            completedTours: completedTours,
          ),
          const SizedBox(height: 18),
          _quickActions(userId: userId, guideName: fullName),
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
          _assignmentTabs(),
          const SizedBox(height: 12),
          _assignmentList(
            userId: userId,
            applicationId: applicationId,
            guideName: fullName,
          ),
          const SizedBox(height: 20),
          _earningsCard(userId),
          const SizedBox(height: 18),
          _billingNotice(),
        ],
      ),
    );
  }

  Widget _profileHeader({
    required String applicationId,
    required String fullName,
    required List<String> guideTypes,
    required List<String> languages,
    required bool isAvailable,
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
                child: const Icon(
                  Icons.badge_outlined,
                  color: yellow,
                  size: 31,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guideTypes.isEmpty
                          ? 'Approved Tour Guide'
                          : guideTypes.join(' â€¢ '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      languages.isEmpty
                          ? 'Languages not listed'
                          : languages.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
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
                      applicationId: applicationId,
                      isAvailable: value,
                    );
                  },
            activeThumbColor: yellow,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Available for Guide Jobs',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              isAvailable
                  ? 'You can receive new tour assignments.'
                  : 'New guide assignments are paused.',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsSection({
    required String userId,
    required double rating,
    required int completedTours,
  }) {
    return StreamBuilder<List<TourBooking>>(
      stream: _tourBookingService.guideBookingsStream(userId),
      builder: (context, snapshot) {
        final List<TourBooking> bookings = snapshot.data ?? <TourBooking>[];

        int assigned = 0;
        int active = 0;
        int completed = completedTours;

        for (final TourBooking booking in bookings) {
          if (booking.bookingStatus == 'confirmed' ||
              booking.bookingStatus == 'assigned') {
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

  Widget _quickActions({required String userId, required String guideName}) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
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
          subtitle: 'Guide earnings',
          onTap: () {
            _showWalletDetails(userId);
          },
        ),
        _actionCard(
          icon: Icons.language,
          title: 'Languages',
          subtitle: 'Approved language profile',
          onTap: () {
            _showInfoDialog(
              title: 'Guide Languages',
              message:
                  'Languages are controlled from the approved Tour Guide application.',
            );
          },
        ),
        _actionCard(
          icon: Icons.rate_review_outlined,
          title: 'My Reviews',
          subtitle: 'Guest ratings and replies',
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => PartnerReviewsScreen(
                  serviceType: FeedbackServiceType.tour,
                  targetType: FeedbackTargetType.tourGuide,
                  targetId: userId,
                  partnerName: guideName,
                  onReplyRequested: (review) {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => ReviewReplyScreen(
                          review: review,
                          authorId: userId,
                          authorName: guideName,
                          authorType: FeedbackReplyAuthorType.tourGuide,
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

  Widget _assignmentTabs() {
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
    required String userId,
    required String applicationId,
    required String guideName,
  }) {
    return StreamBuilder<List<TourBooking>>(
      stream: _tourBookingService.guideBookingsStream(userId),
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
                booking.bookingStatus == 'assigned';
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
                ? 'No Guide History'
                : 'No Guide Assignments',
            message: _selectedTab == 'assigned'
                ? 'New guide assignments from SWAT RIDE admin will appear here.'
                : _selectedTab == 'active'
                ? 'Active guided tours will appear here.'
                : 'Completed, cancelled and rejected tours will appear here.',
          );
        }

        return Column(
          children: filtered.map((booking) {
            return _assignmentCard(
              booking: booking,
              applicationId: applicationId,
              guideName: guideName,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _assignmentCard({
    required TourBooking booking,
    required String applicationId,
    required String guideName,
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
                child: const Icon(
                  Icons.explore_outlined,
                  color: yellow,
                  size: 27,
                ),
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
            'Dates',
            '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
          ),
          _detailRow('Guests', '${booking.guests}'),
          _detailRow(
            'Driver',
            booking.driverId.isEmpty ? 'Not assigned' : booking.driverId,
          ),
          _detailRow(
            'Hotel',
            booking.hotelId.isEmpty ? 'Not included' : booking.hotelId,
          ),
          _detailRow('Payment', _statusLabel(booking.paymentStatus)),
          const SizedBox(height: 10),
          _assignmentActions(
            booking: booking,
            applicationId: applicationId,
            guideName: guideName,
          ),
        ],
      ),
    );
  }

  Widget _assignmentActions({
    required TourBooking booking,
    required String applicationId,
    required String guideName,
  }) {
    if (booking.bookingStatus == 'confirmed' ||
        booking.bookingStatus == 'assigned') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isWorking ? null : () => _rejectAssignment(booking),
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
              onPressed: _isWorking
                  ? null
                  : () => _acceptAssignment(
                      booking: booking,
                      applicationId: applicationId,
                      guideName: guideName,
                    ),
              icon: const Icon(Icons.check),
              label: const Text(
                'Accept',
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

    if (booking.bookingStatus == 'started' ||
        booking.bookingStatus == 'in_progress') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isWorking ? null : () => _markGuideArrived(booking),
          icon: const Icon(Icons.location_on),
          label: const Text('Mark Guide Arrived'),
        ),
      );
    }

    if (booking.bookingStatus == 'arrived') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isWorking ? null : () => _markGuideCompleted(booking),
          icon: const Icon(Icons.task_alt),
          label: const Text(
            'Complete Guide Duty',
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

  Future<void> _acceptAssignment({
    required TourBooking booking,
    required String applicationId,
    required String guideName,
  }) async {
    setState(() {
      _isWorking = true;
    });

    try {
      await _firestore
          .collection('tour_bookings')
          .doc(booking.id)
          .set(<String, dynamic>{
            'guideAccepted': true,
            'guideApplicationId': applicationId,
            'guideName': guideName,
            'guideAcceptedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      _showMessage('Guide assignment accepted.');
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

  Future<void> _rejectAssignment(TourBooking booking) async {
    final TextEditingController reasonController = TextEditingController();

    final String? reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Reject Guide Assignment',
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

    setState(() {
      _isWorking = true;
    });

    try {
      await _firestore
          .collection('tour_bookings')
          .doc(booking.id)
          .set(<String, dynamic>{
            'guideRejected': true,
            'guideRejectionReason': reason,
            'guideRejectedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      _showMessage('Guide assignment rejected.');
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

  Future<void> _markGuideArrived(TourBooking booking) async {
    setState(() {
      _isWorking = true;
    });

    try {
      await _firestore
          .collection('tour_bookings')
          .doc(booking.id)
          .set(<String, dynamic>{
            'guideDutyStatus': 'arrived',
            'guideArrivedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      _showMessage('Guide arrival marked.');
    } catch (error) {
      _showMessage('Unable to mark arrival: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _markGuideCompleted(TourBooking booking) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Complete Guide Duty',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Confirm that your guide duty for this tour is complete?',
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

    setState(() {
      _isWorking = true;
    });

    try {
      await _firestore
          .collection('tour_bookings')
          .doc(booking.id)
          .set(<String, dynamic>{
            'guideDutyStatus': 'completed',
            'guideCompletedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      final User? user = _currentUser;

      if (user != null) {
        final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
            .collection(TourGuideApplicationService.collectionName)
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          await snapshot.docs.first.reference.set(<String, dynamic>{
            'completedTours': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      _showMessage('Guide duty completed.');
    } catch (error) {
      _showMessage('Unable to complete guide duty: $error', isError: true);
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
          .collection('tour_guide_wallet_transactions')
          .where('guideUserId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        final documents =
            snapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        double grossEarnings = 0;
        double availableBalance = 0;
        double pending = 0;

        for (final document in documents) {
          final data = document.data();
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
                    'Guide Earnings',
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
          .collection(TourGuideApplicationService.collectionName)
          .doc(applicationId)
          .set(<String, dynamic>{
            'isAvailable': isAvailable,
            'availabilityUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      _showMessage(
        isAvailable
            ? 'You are now available for guide jobs.'
            : 'New guide assignments are paused.',
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

  Future<void> _showNotificationSummary(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final int unread = snapshot.docs
          .where((document) => document.data()['isRead'] != true)
          .length;

      _showInfoDialog(
        title: 'Tour Guide Notifications',
        message: 'You have $unread unread notifications.',
      );
    } catch (error) {
      _showMessage('Unable to load notifications: $error', isError: true);
    }
  }

  Future<void> _showWalletDetails(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('tour_guide_wallet_transactions')
          .where('guideUserId', isEqualTo: userId)
          .get();

      double balance = 0;

      for (final document in snapshot.docs) {
        final data = document.data();
        final String type = data['type']?.toString() ?? '';
        final String status = data['status']?.toString() ?? '';
        final double amount = _readNumber(data['amount']);

        if (status != 'completed') {
          continue;
        }

        if (type == 'earning' || type == 'adjustment_credit') {
          balance += amount;
        } else if (type == 'payout' || type == 'adjustment_debit') {
          balance -= amount;
        }
      }

      if (balance < 0) {
        balance = 0;
      }

      _showInfoDialog(
        title: 'Tour Guide Wallet',
        message:
            'Available balance: Rs. ${balance.toStringAsFixed(0)}\n\nReal payout settlement remains bypassed until payment integration.',
      );
    } catch (error) {
      _showMessage('Unable to load wallet: $error', isError: true);
    }
  }

  void _showSupportDialog() {
    _showInfoDialog(
      title: 'SWAT RIDE Support',
      message:
          'Contact support for assignment, safety, payment or account issues.',
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
              'Assigned tours load from the real tour_bookings collection. Guide acceptance, arrival and duty completion are saved in Firestore. Firebase Storage, live paid navigation and payout settlement remain bypassed.',
              style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
      case 'confirmed':
      case 'assigned':
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
      case 'confirmed':
      case 'assigned':
        return 'Assigned';
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
      case 'paid':
      case 'paid_testing':
        return 'Paid (Testing)';
      case 'testing_bypassed':
        return 'Testing Bypass';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _readNumber(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

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
