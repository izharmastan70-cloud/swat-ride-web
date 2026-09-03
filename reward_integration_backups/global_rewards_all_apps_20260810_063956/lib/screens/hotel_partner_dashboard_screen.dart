import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/hotel_partner_application.dart';
import '../services/hotel_partner_application_service.dart';
import 'hotel_room_management_screen.dart';
import 'hotel_room_availability_calendar_screen.dart';
import '../hotel_admin/screens/hotel_admin_housekeeping_screen.dart';
import '../services/hotel_walk_in_booking_screen.dart';
import 'hotel_booking_requests_screen.dart';
import 'hotel_guest_chat_inbox_screen.dart';
import 'hotel_agent_management_screen.dart';
import 'hotel_check_in_out_screen.dart';
import 'hotel_reports_screen.dart';
import 'hotel_profile_management_screen.dart';
import 'hotel_gallery_management_screen.dart';
import 'hotel_amenities_services_screen.dart';
import '../services/hotel_policies_management_screen.dart';
import '../services/hotel_pricing_management_screen.dart';
import 'hotel_promo_management_screen.dart';
import 'hotel_wallet_screen.dart';
import 'hotel_notifications_screen.dart';
import 'hotel_analytics_screen.dart';
import '../feedback/models/feedback_model.dart';
import '../feedback/models/feedback_reply_model.dart';
import '../feedback/partner/partner_reviews_screen.dart';
import '../feedback/partner/review_reply_screen.dart';

class HotelPartnerDashboardScreen extends StatefulWidget {
  const HotelPartnerDashboardScreen({super.key});

  @override
  State<HotelPartnerDashboardScreen> createState() =>
      _HotelPartnerDashboardScreenState();
}

class _HotelPartnerDashboardScreenState
    extends State<HotelPartnerDashboardScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final HotelPartnerApplicationService _applicationService =
      HotelPartnerApplicationService();

  bool _isUpdatingHotelStatus = false;

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
          'Hotel Partner Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (user != null)
            StreamBuilder<HotelPartnerApplication?>(
              stream: _applicationService.userApplicationStream(user.uid),
              builder:
                  (context, AsyncSnapshot<HotelPartnerApplication?> snapshot) {
                    final HotelPartnerApplication? application = snapshot.data;

                    final bool canOpenNotifications =
                        application != null &&
                        application.isApproved &&
                        application.hotelId.trim().isNotEmpty;

                    if (!canOpenNotifications) {
                      return const SizedBox.shrink();
                    }

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestore
                          .collection('hotel_notifications')
                          .where('hotelId', isEqualTo: application.hotelId)
                          .where('isRead', isEqualTo: false)
                          .snapshots(),
                      builder:
                          (
                            context,
                            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                            notificationSnapshot,
                          ) {
                            final int unreadCount =
                                notificationSnapshot.data?.docs.length ?? 0;

                            return IconButton(
                              tooltip: 'Notifications',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (context) =>
                                        HotelNotificationsScreen(
                                          hotelId: application.hotelId,
                                        ),
                                  ),
                                );
                              },
                              icon: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(
                                    Icons.notifications_outlined,
                                    color: yellow,
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: -6,
                                      top: -6,
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 17,
                                          minHeight: 17,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          unreadCount > 99
                                              ? '99+'
                                              : '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                    );
                  },
            ),
        ],
      ),
      body: user == null
          ? _buildLoginRequired()
          : StreamBuilder<HotelPartnerApplication?>(
              stream: _applicationService.userApplicationStream(user.uid),
              builder: (context, AsyncSnapshot<HotelPartnerApplication?> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: yellow),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final HotelPartnerApplication? application = snapshot.data;

                if (application == null) {
                  return _buildNoApplication();
                }

                if (!application.isApproved) {
                  return _buildApplicationStatus(application);
                }

                if (application.hotelId.trim().isEmpty) {
                  return _buildErrorState(
                    'Your application is approved, but hotel ID is missing. Please contact SWAT RIDE support.',
                  );
                }

                return _buildApprovedDashboard(application);
              },
            ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _messageCard(
          icon: Icons.lock_outline,
          title: 'Login Required',
          message: 'Please log in to open your Hotel Partner Dashboard.',
        ),
      ),
    );
  }

  Widget _buildNoApplication() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _messageCard(
          icon: Icons.hotel_outlined,
          title: 'No Hotel Application',
          message:
              'Submit a Hotel Partner application first. After admin approval, this dashboard will become active.',
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _messageCard(
          icon: Icons.error_outline,
          title: 'Unable to Load Dashboard',
          message: message,
        ),
      ),
    );
  }

  Widget _buildApplicationStatus(HotelPartnerApplication application) {
    final String status = application.applicationStatus;

    final String title;
    final String message;
    final IconData icon;

    switch (status) {
      case 'draft':
        title = 'Draft Application';
        message =
            'Your application is still saved as a draft. Complete and submit it for admin review.';
        icon = Icons.edit_note;
        break;

      case 'submitted':
        title = 'Application Submitted';
        message = 'Your hotel application is waiting for admin review.';
        icon = Icons.schedule;
        break;

      case 'under_review':
        title = 'Under Review';
        message = 'SWAT RIDE admin is reviewing your hotel application.';
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
        title = 'Partner Access Suspended';
        message = application.adminNote.trim().isEmpty
            ? 'Your Hotel Partner access is currently suspended.'
            : application.adminNote;
        icon = Icons.block;
        break;

      default:
        title = 'Application Status';
        message = 'Current status: ${application.applicationStatus}';
        icon = Icons.info_outline;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _messageCard(icon: icon, title: title, message: message),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Customer App'),
              style: OutlinedButton.styleFrom(
                foregroundColor: yellow,
                side: const BorderSide(color: yellow),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedDashboard(HotelPartnerApplication application) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('hotels')
          .doc(application.hotelId)
          .snapshots(),
      builder:
          (
            context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> hotelSnapshot,
          ) {
            final Map<String, dynamic> hotelData =
                hotelSnapshot.data?.data() ?? <String, dynamic>{};

            final String hotelName =
                hotelData['name']?.toString().trim().isNotEmpty == true
                ? hotelData['name'].toString()
                : application.hotelName;

            final String location =
                hotelData['location']?.toString().trim().isNotEmpty == true
                ? hotelData['location'].toString()
                : application.location;

            final bool isActive = hotelData['isActive'] != false;

            return RefreshIndicator(
              color: yellow,
              backgroundColor: darkCard,
              onRefresh: () async {
                await _firestore
                    .collection('hotels')
                    .doc(application.hotelId)
                    .get();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHotelHeader(
                    hotelName: hotelName,
                    location: location,
                    isActive: isActive,
                    hotelId: application.hotelId,
                  ),

                  const SizedBox(height: 20),

                  _buildStats(hotelId: application.hotelId),

                  const SizedBox(height: 22),

                  const Text(
                    'Hotel Management',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.04,
                    children: [
                      _dashboardCard(
                        icon: Icons.hotel_outlined,
                        title: 'Hotel Profile',
                        subtitle: 'View and update hotel information',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  HotelProfileManagementScreen(
                                    hotelId: application.hotelId,
                                  ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.photo_library_outlined,
                        title: 'Images / Gallery',
                        subtitle: 'Manage logo, cover and hotel photos',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  HotelGalleryManagementScreen(
                                    hotelId: application.hotelId,
                                  ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.room_service_outlined,
                        title: 'Amenities & Services',
                        subtitle: 'Manage hotel facilities and guest services',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  HotelAmenitiesServicesScreen(
                                    hotelId: application.hotelId,
                                  ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.policy_outlined,
                        title: 'Hotel Policies',
                        subtitle: 'Manage booking rules and guest policies',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  HotelPoliciesManagementScreen(
                                    hotelId: application.hotelId,
                                  ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.price_change_outlined,
                        title: 'Hotel Pricing',
                        subtitle: 'Manage room pricing and seasonal rates',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  HotelPricingManagementScreen(
                                    hotelId: application.hotelId,
                                  ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.local_offer_outlined,
                        title: 'Promo Codes',
                        subtitle: 'Create discounts and promotional offers',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => HotelPromoManagementScreen(
                                hotelId: application.hotelId,
                              ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Wallet',
                        subtitle: 'View earnings, payouts and commission',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => HotelWalletScreen(
                                hotelId: application.hotelId,
                              ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.meeting_room_outlined,
                        title: 'Rooms',
                        subtitle: 'Add rooms, prices and facilities',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => HotelRoomManagementScreen(
                                hotelId: application.hotelId,
                              ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.event_available_outlined,
                        title: 'Room Availability',
                        subtitle: 'Calendar, occupancy and room status',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  HotelRoomAvailabilityCalendarScreen(
                                    hotelId: application.hotelId,
                                  ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.cleaning_services_outlined,
                        title: 'Housekeeping',
                        subtitle:
                            'Cleaning tasks, inspections and room readiness',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => HotelHousekeepingScreen(
                                hotelId: application.hotelId,
                              ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.person_add_alt_1_outlined,
                        title: 'Walk-in Booking',
                        subtitle: 'Create a direct reception booking',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => HotelWalkInBookingScreen(
                                hotelId: application.hotelId,
                              ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.book_online_outlined,
                        title: 'Booking Requests',
                        subtitle: 'Accept or reject guest bookings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => HotelBookingRequestsScreen(
                                hotelId: application.hotelId,
                              ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.chat_bubble_outline,
                        title: 'Guest Chat',
                        subtitle: 'Chat with booked customers',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => HotelGuestChatInboxScreen(
                                hotelId: application.hotelId,
                              ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.people_outline,
                        title: 'Agents',
                        subtitle: 'Manage hotel staff and permissions',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => HotelAgentManagementScreen(
                                hotelId: application.hotelId,
                              ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.login,
                        title: 'Check-in / Out',
                        subtitle: 'Manage guest arrival and departure',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => HotelCheckInOutScreen(
                                hotelId: application.hotelId,
                              ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.rate_review_outlined,
                        title: 'Guest Reviews',
                        subtitle: 'Ratings, feedback and public replies',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => PartnerReviewsScreen(
                                serviceType: FeedbackServiceType.hotel,
                                targetType: FeedbackTargetType.hotel,
                                targetId: application.hotelId,
                                partnerName: application.hotelName,
                                onReplyRequested: (FeedbackModel review) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (context) => ReviewReplyScreen(
                                        review: review,
                                        authorId: application.applicantUserId,
                                        authorName: application.hotelName,
                                        authorType:
                                            FeedbackReplyAuthorType.hotelOwner,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.analytics_outlined,
                        title: 'Reports',
                        subtitle: 'Bookings, occupancy and earnings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => HotelReportsScreen(
                                hotelId: application.hotelId,
                              ),
                            ),
                          );
                        },
                      ),
                      _dashboardCard(
                        icon: Icons.insights_outlined,
                        title: 'Analytics',
                        subtitle: 'View bookings, revenue and occupancy trends',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => HotelAnalyticsScreen(
                                hotelId: application.hotelId,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  _buildBillingNotice(),

                  const SizedBox(height: 22),

                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Return to Customer Mode'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: yellow,
                      side: const BorderSide(color: yellow),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
    );
  }

  Widget _buildHotelHeader({
    required String hotelName,
    required String location,
    required bool isActive,
    required String hotelId,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: yellow.withValues(alpha: 0.25)),
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
                child: const Icon(Icons.hotel, color: yellow, size: 30),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotelName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey,
                          size: 17,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
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

          const SizedBox(height: 16),

          SwitchListTile(
            value: isActive,
            onChanged: _isUpdatingHotelStatus
                ? null
                : (value) {
                    _updateHotelActiveStatus(hotelId: hotelId, isActive: value);
                  },
            activeThumbColor: yellow,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Accept New Bookings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              isActive
                  ? 'Hotel is visible and accepting bookings.'
                  : 'Hotel remains registered but new bookings are paused.',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats({required String hotelId}) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('hotel_bookings')
          .where('hotelId', isEqualTo: hotelId)
          .snapshots(),
      builder:
          (
            context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
          ) {
            final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents =
                snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            int pending = 0;
            int confirmed = 0;
            int completed = 0;

            for (final document in documents) {
              final String status =
                  document.data()['bookingStatus']?.toString() ?? 'pending';

              if (status == 'confirmed') {
                confirmed++;
              } else if (status == 'completed') {
                completed++;
              } else if (status == 'pending' ||
                  status == 'pending_hotel_confirmation') {
                pending++;
              }
            }

            return Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: 'Pending',
                    value: '$pending',
                    icon: Icons.schedule,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    title: 'Confirmed',
                    value: '$confirmed',
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    title: 'Completed',
                    value: '$completed',
                    icon: Icons.task_alt,
                  ),
                ),
              ],
            );
          },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: yellow, size: 23),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _dashboardCard({
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
            Icon(icon, color: yellow, size: 30),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingNotice() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: yellow.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: yellow),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Booking, chat, inventory and partner controls use real app structure. Online payment settlement and Firebase Storage uploads remain paused until billing is enabled.',
              style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: yellow, size: 44),
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
    );
  }

  Future<void> _updateHotelActiveStatus({
    required String hotelId,
    required bool isActive,
  }) async {
    setState(() {
      _isUpdatingHotelStatus = true;
    });

    try {
      await _firestore.collection('hotels').doc(hotelId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      _showMessage(
        isActive
            ? 'Hotel is now accepting new bookings.'
            : 'New hotel bookings have been paused.',
      );
    } catch (error) {
      _showMessage('Unable to update hotel status: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingHotelStatus = false;
        });
      }
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
