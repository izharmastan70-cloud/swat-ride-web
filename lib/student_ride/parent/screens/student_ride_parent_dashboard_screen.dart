import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../feedback/models/feedback_model.dart';
import '../../../feedback/screens/complaint_screen.dart';
import '../../../feedback/screens/submit_feedback_screen.dart';

import '../../models/student_ride_invoice_model.dart';
import '../../models/student_ride_package_model.dart';
import '../../models/student_ride_settings_model.dart';
import '../../models/student_ride_student_model.dart';
import '../../models/student_ride_subscription_model.dart';
import '../../services/student_ride_invoice_service.dart';
import '../../services/student_ride_package_service.dart';
import '../../services/student_ride_parent_service.dart';
import '../../services/student_ride_settings_service.dart';
import '../../services/student_ride_subscription_service.dart';
import '../../../safety/models/safety_models.dart';
import '../../../safety/screens/safety_center_screen.dart';
import '../../../rewards/widgets/reward_access_action.dart';

class StudentRideParentDashboardScreen extends StatefulWidget {
  const StudentRideParentDashboardScreen({
    super.key,
    this.onAddStudent,
    this.onManageGuardians,
    this.onBrowsePackages,
    this.onOpenInvoices,
  });

  final VoidCallback? onAddStudent;
  final VoidCallback? onManageGuardians;
  final VoidCallback? onBrowsePackages;
  final VoidCallback? onOpenInvoices;

  @override
  State<StudentRideParentDashboardScreen> createState() =>
      _StudentRideParentDashboardScreenState();
}

class _StudentRideParentDashboardScreenState
    extends State<StudentRideParentDashboardScreen> {
  final StudentRideSettingsService _settingsService =
      StudentRideSettingsService();
  final StudentRideParentService _parentService = StudentRideParentService();
  final StudentRideSubscriptionService _subscriptionService =
      StudentRideSubscriptionService();
  final StudentRideInvoiceService _invoiceService = StudentRideInvoiceService();
  final StudentRidePackageService _packageService = StudentRidePackageService();

  static const Color _primary = Color(0xFF123C69);
  static const Color _accent = Color(0xFFF5A623);
  static const Color _background = Color(0xFFF4F7FB);

  void _runOrExplain(VoidCallback? callback, String message) {
    if (callback != null) {
      callback();
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StudentRideSettingsModel>(
      stream: _settingsService.watchSettings(),
      builder: (context, settingsSnapshot) {
        if (settingsSnapshot.connectionState == ConnectionState.waiting &&
            !settingsSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final settings =
            settingsSnapshot.data ?? StudentRideSettingsModel.defaults();

        if (!settings.moduleEnabled) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Student Ride'),
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
            body: _ModuleUnavailableView(message: settings.disabledMessage),
          );
        }

        return Scaffold(
          backgroundColor: _background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Ride',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Safe school transport',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            actions: [
              const RewardAccessAction(moduleName: 'studentRide'),
              IconButton(
                tooltip: 'Payments',
                onPressed: () => _runOrExplain(
                  widget.onOpenInvoices,
                  'Payment screen will be connected next.',
                ),
                icon: const Icon(Icons.receipt_long_rounded),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: _accent,
            foregroundColor: Colors.black,
            onPressed: () => _runOrExplain(
              widget.onAddStudent,
              'Student registration screen will be connected next.',
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text(
              'Add Student',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future<void>.delayed(const Duration(milliseconds: 350));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 16),
                _buildSummaryGrid(),
                const SizedBox(height: 22),
                _SectionHeader(
                  title: 'My Children',
                  actionLabel: 'Add',
                  onAction: () => _runOrExplain(
                    widget.onAddStudent,
                    'Student registration screen will be connected next.',
                  ),
                ),
                const SizedBox(height: 10),
                _buildStudentsSection(),
                const SizedBox(height: 22),
                const _SectionHeader(title: 'Subscriptions'),
                const SizedBox(height: 10),
                _buildSubscriptionsSection(),
                const SizedBox(height: 22),
                _SectionHeader(
                  title: 'Monthly Payments',
                  actionLabel: 'View all',
                  onAction: () => _runOrExplain(
                    widget.onOpenInvoices,
                    'Invoice screen will be connected next.',
                  ),
                ),
                const SizedBox(height: 10),
                _buildInvoicesSection(),
                const SizedBox(height: 22),
                _SectionHeader(
                  title: 'Available Packages',
                  actionLabel: 'View all',
                  onAction: () => _runOrExplain(
                    widget.onBrowsePackages,
                    'Package selection screen will be connected next.',
                  ),
                ),
                const SizedBox(height: 10),
                _buildPackagesSection(),
                const SizedBox(height: 22),
                _buildGuardianCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF123C69), Color(0xFF1E5A92)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33123C69),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'School journeys,\nmade safer.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Monthly transport, verified drivers and '
                  'morning/afternoon route assignments.',
                  style: TextStyle(
                    color: Color(0xFFDCEAFF),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14),
          CircleAvatar(
            radius: 34,
            backgroundColor: Color(0x22FFFFFF),
            child: Icon(
              Icons.directions_bus_rounded,
              color: Color(0xFFFFC857),
              size: 38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<List<StudentRideStudentModel>>(
            stream: _parentService.watchMyStudents(),
            builder: (context, snapshot) {
              return _SummaryTile(
                icon: Icons.school_rounded,
                label: 'Children',
                value: '${snapshot.data?.length ?? 0}',
                color: const Color(0xFF2878B5),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StreamBuilder<List<StudentRideSubscriptionModel>>(
            stream: _subscriptionService.watchMySubscriptions(),
            builder: (context, snapshot) {
              final activeCount =
                  snapshot.data?.where((item) => item.isActive).length ?? 0;

              return _SummaryTile(
                icon: Icons.route_rounded,
                label: 'Active',
                value: '$activeCount',
                color: const Color(0xFF1C9B68),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StreamBuilder<List<StudentRideInvoiceModel>>(
            stream: _invoiceService.watchMyInvoices(),
            builder: (context, snapshot) {
              final dueCount =
                  snapshot.data?.where((item) => !item.isPaid).length ?? 0;

              return _SummaryTile(
                icon: Icons.payments_rounded,
                label: 'Due',
                value: '$dueCount',
                color: const Color(0xFFE08B22),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openStudentSafety(StudentRideStudentModel student) {
    final SafetyLocation pickup = SafetyLocation(
      latitude: student.morningPickupLatitude,
      longitude: student.morningPickupLongitude,
      address: student.morningPickupAddress,
      placeName: student.fullName,
    );

    final SafetyLocation drop = SafetyLocation(
      latitude: student.afternoonDropLatitude,
      longitude: student.afternoonDropLongitude,
      address: student.afternoonDropAddress,
      placeName: student.fullName,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return SafetyCenterScreen(
            contextData: SafetyContext(
              serviceType: SafetyServiceType.studentRide,
              referenceId: student.assignedRouteId.isNotEmpty
                  ? student.assignedRouteId
                  : student.studentId,
              initiatedByUserId: student.parentUserId,
              initiatedByRole: SafetyUserRole.parent,
              sourcePage: SafetySourcePage.studentTracking,
              referenceStatus: student.status.name,
              pickupLocation: pickup,
              destinationLocation: drop,
              serviceTitle: 'Student Ride Safety',
              serviceSubtitle: student.fullName.trim().isEmpty
                  ? 'Child safety'
                  : '${student.fullName} - safety',
              metadata: <String, dynamic>{
                'studentId': student.studentId,
                'schoolId': student.schoolId,
                'schoolName': student.schoolName,
                'assignedRouteId': student.assignedRouteId,
                'assignedDriverId': student.assignedDriverId,
                'assignedVehicleId': student.assignedVehicleId,

                // Security-sensitive pickup/handover credentials
                // and medical profile are intentionally excluded.
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentsSection() {
    return StreamBuilder<List<StudentRideStudentModel>>(
      stream: _parentService.watchMyStudents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ErrorCard(message: 'Unable to load student profiles.');
        }

        if (!snapshot.hasData) {
          return const _LoadingCard();
        }

        final students = snapshot.data!;

        if (students.isEmpty) {
          return _EmptyCard(
            icon: Icons.person_add_alt_1_rounded,
            title: 'No student added',
            message: 'Add your child profile before selecting a package.',
            buttonLabel: 'Add Student',
            onPressed: () => _runOrExplain(
              widget.onAddStudent,
              'Student registration screen will be connected next.',
            ),
          );
        }

        return Column(
          children: students
              .map(
                (student) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StudentCard(
                    student: student,
                    onSafetyPressed: () {
                      _openStudentSafety(student);
                    },
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  String _studentRideDriverId(StudentRideSubscriptionModel subscription) {
    if (subscription.morningDriverId.trim().isNotEmpty) {
      return subscription.morningDriverId.trim();
    }
    if (subscription.afternoonDriverId.trim().isNotEmpty) {
      return subscription.afternoonDriverId.trim();
    }
    return subscription.driverId.trim();
  }

  FeedbackTargetType _studentRideTargetType(
    StudentRideSubscriptionModel subscription,
  ) {
    return _studentRideDriverId(subscription).isEmpty
        ? FeedbackTargetType.service
        : FeedbackTargetType.studentRideDriver;
  }

  String _studentRideTargetId(StudentRideSubscriptionModel subscription) {
    final driverId = _studentRideDriverId(subscription);
    return driverId.isEmpty ? 'swat_ride_student_service' : driverId;
  }

  String _studentRideTargetName(StudentRideSubscriptionModel subscription) {
    return _studentRideDriverId(subscription).isEmpty
        ? 'SWAT RIDE Student Service'
        : 'Assigned Student Ride Driver';
  }

  Future<void> _openStudentRideFeedback(
    StudentRideSubscriptionModel subscription,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final reviewerId = user?.uid.trim() ?? '';
    if (reviewerId.isEmpty) {
      _feedbackMessage('Please sign in to submit Student Ride feedback.');
      return;
    }
    if (subscription.parentId.trim().isNotEmpty &&
        subscription.parentId.trim() != reviewerId) {
      _feedbackMessage('Only the subscription parent can rate this service.');
      return;
    }
    final eligible =
        subscription.isActive ||
        subscription.status == StudentRideSubscriptionStatus.expired;
    if (!eligible) {
      _feedbackMessage('Rating is available for active or completed service.');
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => SubmitFeedbackScreen(
          serviceType: FeedbackServiceType.studentRide,
          targetType: _studentRideTargetType(subscription),
          sourceId: subscription.subscriptionId,
          sourceReference: subscription.packageName,
          reviewerId: reviewerId,
          reviewerName: user?.displayName?.trim() ?? '',
          reviewerPhotoUrl: user?.photoURL?.trim() ?? '',
          targetId: _studentRideTargetId(subscription),
          targetName: _studentRideTargetName(subscription),
          serviceCompleted: true,
        ),
      ),
    );
  }

  Future<void> _openStudentRideComplaint(
    StudentRideSubscriptionModel subscription,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final reporterId = user?.uid.trim() ?? '';
    if (reporterId.isEmpty) {
      _feedbackMessage('Please sign in to report a Student Ride problem.');
      return;
    }
    if (subscription.parentId.trim().isNotEmpty &&
        subscription.parentId.trim() != reporterId) {
      _feedbackMessage('Only the subscription parent can report this service.');
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ComplaintScreen(
          serviceType: FeedbackServiceType.studentRide,
          sourceId: subscription.subscriptionId,
          sourceReference: subscription.packageName,
          reporterId: reporterId,
          reporterName: user?.displayName?.trim() ?? '',
          reporterPhone: user?.phoneNumber?.trim() ?? '',
          targetType: _studentRideTargetType(subscription),
          targetId: _studentRideTargetId(subscription),
          targetName: _studentRideTargetName(subscription),
        ),
      ),
    );
  }

  void _feedbackMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Widget _buildSubscriptionsSection() {
    return StreamBuilder<List<StudentRideSubscriptionModel>>(
      stream: _subscriptionService.watchMySubscriptions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ErrorCard(message: 'Unable to load subscriptions.');
        }

        if (!snapshot.hasData) {
          return const _LoadingCard();
        }

        final subscriptions = snapshot.data!;

        if (subscriptions.isEmpty) {
          return _EmptyCard(
            icon: Icons.route_outlined,
            title: 'No subscription',
            message: 'Choose a Student Ride package after student approval.',
            buttonLabel: 'Browse Packages',
            onPressed: () => _runOrExplain(
              widget.onBrowsePackages,
              'Package selection screen will be connected next.',
            ),
          );
        }

        return Column(
          children: subscriptions
              .take(3)
              .map(
                (subscription) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SubscriptionCard(
                    subscription: subscription,
                    onRate: () => _openStudentRideFeedback(subscription),
                    onComplaint: () => _openStudentRideComplaint(subscription),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildInvoicesSection() {
    return StreamBuilder<List<StudentRideInvoiceModel>>(
      stream: _invoiceService.watchMyInvoices(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ErrorCard(message: 'Unable to load monthly invoices.');
        }

        if (!snapshot.hasData) {
          return const _LoadingCard();
        }

        final invoices = snapshot.data!;

        if (invoices.isEmpty) {
          return const _EmptyCard(
            icon: Icons.receipt_long_outlined,
            title: 'No invoice yet',
            message: 'Your monthly invoice will appear after route approval.',
          );
        }

        return Column(
          children: invoices
              .take(2)
              .map(
                (invoice) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _InvoiceCard(invoice: invoice),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildPackagesSection() {
    return StreamBuilder<List<StudentRidePackageModel>>(
      stream: _packageService.watchEnabledPackages(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ErrorCard(
            message: 'Unable to load Student Ride packages.',
          );
        }

        if (!snapshot.hasData) {
          return const _LoadingCard();
        }

        final packages = snapshot.data!;

        if (packages.isEmpty) {
          return const _EmptyCard(
            icon: Icons.inventory_2_outlined,
            title: 'No package available',
            message: 'Admin has not enabled a Student Ride package yet.',
          );
        }

        return SizedBox(
          height: 186,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: packages.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _PackageCard(
                package: packages[index],
                onTap: () => _runOrExplain(
                  widget.onBrowsePackages,
                  'Package selection screen will be connected next.',
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGuardianCard() {
    return Card(
      elevation: 0,
      color: const Color(0xFFEAF3FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          child: Icon(Icons.family_restroom_rounded),
        ),
        title: const Text(
          'Authorized Guardians',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: const Text('Manage people allowed to receive your child.'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _runOrExplain(
          widget.onManageGuardians,
          'Guardian management screen will be connected next.',
        ),
      ),
    );
  }
}

class _ModuleUnavailableView extends StatelessWidget {
  const _ModuleUnavailableView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_bus_outlined,
              size: 72,
              color: Color(0xFF9AA8B8),
            ),
            const SizedBox(height: 18),
            const Text(
              'Student Ride is unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message.trim().isEmpty ? 'Please check again later.' : message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF657385), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF17263A),
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6C7888), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student, required this.onSafetyPressed});

  final StudentRideStudentModel student;
  final VoidCallback onSafetyPressed;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (student.status) {
      StudentRideStudentStatus.approved => const Color(0xFF18895A),
      StudentRideStudentStatus.rejected => const Color(0xFFD14343),
      StudentRideStudentStatus.suspended => const Color(0xFFD14343),
      StudentRideStudentStatus.draft => const Color(0xFF68778A),
      _ => const Color(0xFFE08B22),
    };

    final classText = [
      student.className,
      student.sectionName,
    ].where((item) => item.trim().isNotEmpty).join(' - ');

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE5EAF1)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: const Color(0xFFEAF3FF),
              backgroundImage: student.profilePhotoUrl.isNotEmpty
                  ? NetworkImage(student.profilePhotoUrl)
                  : null,
              child: student.profilePhotoUrl.isEmpty
                  ? Text(
                      student.fullName.trim().isEmpty
                          ? 'S'
                          : student.fullName
                                .trim()
                                .substring(0, 1)
                                .toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF123C69),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName.trim().isEmpty
                        ? 'Student'
                        : student.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.schoolName.trim().isEmpty
                        ? 'School not added'
                        : student.schoolName,
                    style: const TextStyle(color: Color(0xFF657385)),
                  ),
                  if (classText.isNotEmpty)
                    Text(
                      classText,
                      style: const TextStyle(
                        color: Color(0xFF8A95A4),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Safety & SOS',
              onPressed: onSafetyPressed,
              color: Colors.red,
              icon: const Icon(Icons.shield_outlined),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _readableName(student.status.name),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.onRate,
    required this.onComplaint,
  });

  final StudentRideSubscriptionModel subscription;
  final VoidCallback onRate;
  final VoidCallback onComplaint;

  @override
  Widget build(BuildContext context) {
    final statusColor = subscription.isActive
        ? const Color(0xFF18895A)
        : subscription.status == StudentRideSubscriptionStatus.rejected
        ? const Color(0xFFD14343)
        : const Color(0xFFE08B22);
    final canReview =
        subscription.isActive ||
        subscription.status == StudentRideSubscriptionStatus.expired;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE5EAF1)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFEAF3FF),
                  foregroundColor: Color(0xFF123C69),
                  child: Icon(Icons.route_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subscription.packageName.trim().isEmpty
                        ? 'Student Ride Package'
                        : subscription.packageName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  _readableName(subscription.status.name),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SmallInfo(
                    label: 'Trip',
                    value: _readableName(subscription.tripType),
                  ),
                ),
                Expanded(
                  child: _SmallInfo(
                    label: 'Payment',
                    value: _readableName(subscription.paymentStatus),
                  ),
                ),
                Expanded(
                  child: _SmallInfo(
                    label: 'Monthly',
                    value:
                        'PKR ${subscription.monthlyAmount.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
            if (canReview) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRate,
                      icon: const Icon(Icons.star_rounded),
                      label: const Text('Rate Student Ride'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onComplaint,
                      icon: const Icon(Icons.support_agent_rounded),
                      label: const Text('Report Problem'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice});

  final StudentRideInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    final color = invoice.isPaid
        ? const Color(0xFF18895A)
        : invoice.isOverdue
        ? const Color(0xFFD14343)
        : const Color(0xFFE08B22);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE5EAF1)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.10),
          foregroundColor: color,
          child: const Icon(Icons.receipt_long_rounded),
        ),
        title: Text(
          invoice.studentName.trim().isEmpty
              ? 'Monthly Student Ride'
              : invoice.studentName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'Billing ${invoice.billingPeriodLabel} â€¢ '
          '${_readableName(invoice.status.name)}',
        ),
        trailing: Text(
          'PKR ${invoice.remainingAmount.toStringAsFixed(0)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package, required this.onTap});

  final StudentRidePackageModel package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 245,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5EAF1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.directions_bus_filled_rounded,
                  color: Color(0xFF123C69),
                  size: 28,
                ),
                const SizedBox(height: 10),
                Text(
                  package.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _readableName(package.tripType.name),
                  style: const TextStyle(
                    color: Color(0xFF657385),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${package.currencyCode} '
                  '${package.basePrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF123C69),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _readableName(package.priceMode.name),
                  style: const TextStyle(
                    color: Color(0xFF8A95A4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  const _SmallInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8A95A4), fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFEEEE),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFD14343)),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE5EAF1)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 38, color: const Color(0xFF91A0B2)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6C7888), height: 1.35),
            ),
            if (buttonLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onPressed, child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _readableName(String value) {
  if (value.trim().isEmpty) return 'Not set';

  final spaced = value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );

  return spaced
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map(
        (word) =>
            '${word[0].toUpperCase()}'
            '${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}
