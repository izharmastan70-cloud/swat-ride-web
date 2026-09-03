import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DriverApplicationStatusScreen
    extends StatefulWidget {
  final String applicationId;

  const DriverApplicationStatusScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<DriverApplicationStatusScreen>
      createState() =>
          _DriverApplicationStatusScreenState();
}

class _DriverApplicationStatusScreenState
    extends State<DriverApplicationStatusScreen> {
  static const Color yellow =
      Color(0xFFFFD60A);

  static const Color darkBackground =
      Color(0xFF0D0D0D);

  static const Color darkCard =
      Color(0xFF1A1A1A);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool isLoading = true;

  Map<String, dynamic>? applicationData;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    _loadApplicationStatus();
  }

  // =========================================================
  // LOAD DRIVER APPLICATION
  // =========================================================

  Future<void> _loadApplicationStatus() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final DocumentSnapshot<
              Map<String, dynamic>>
          document =
          await _firestore
              .collection(
                  'driver_applications')
              .doc(widget.applicationId)
              .get();

      if (!mounted) return;

      if (!document.exists) {
        setState(() {
          isLoading = false;
          errorMessage =
              'Driver application not found.';
        });

        return;
      }

      setState(() {
        applicationData =
            document.data();

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;

        errorMessage =
            'Unable to load application status.';
      });
    }
  }

  // =========================================================
  // GET APPLICATION STATUS
  // =========================================================

  String get applicationStatus {
    return applicationData?['status']
            ?.toString()
            .toLowerCase() ??
        'pending';
  }

  // =========================================================
  // GET DRIVER NAME
  // =========================================================

  String get driverName {
    return (applicationData?['fullName'] ?? applicationData?['name'])
            ?.toString() ??
        'Driver';
  }

  // =========================================================
  // GET PHONE NUMBER
  // =========================================================

  String get phoneNumber {
    return (applicationData?['phoneNumber'] ?? applicationData?['phone'])
            ?.toString() ??
        '';
  }

  // =========================================================
  // GET VEHICLE TYPE
  // =========================================================

  String get vehicleType {
    return applicationData?['vehicleType']
            ?.toString() ??
        '';
  }

  // =========================================================
  // GET VEHICLE NUMBER
  // =========================================================

  String get vehicleNumber {
    return applicationData?['vehicleNumber']
            ?.toString() ??
        '';
  }

  // =========================================================
  // GET REJECTION REASON
  // =========================================================

  String get rejectionReason {
    final adminReview =
        applicationData?['adminReview'];

    if (adminReview is Map) {
      return adminReview[
                  'rejectionReason']
              ?.toString() ??
          '';
    }

    return '';
  }

  // =========================================================
  // STATUS COLOR
  // =========================================================

  Color get statusColor {
    switch (applicationStatus) {
      case 'approved':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      case 'pending':
      default:
        return Colors.orange;
    }
  }

  // =========================================================
  // STATUS ICON
  // =========================================================

  IconData get statusIcon {
    switch (applicationStatus) {
      case 'approved':
        return Icons.check_circle;

      case 'rejected':
        return Icons.cancel;

      case 'pending':
      default:
        return Icons.hourglass_top;
    }
  }

  // =========================================================
  // STATUS TITLE
  // =========================================================

  String get statusTitle {
    switch (applicationStatus) {
      case 'approved':
        return 'Application Approved';

      case 'rejected':
        return 'Application Rejected';

      case 'pending':
      default:
        return 'Application Under Review';
    }
  }

  // =========================================================
  // STATUS DESCRIPTION
  // =========================================================

  String get statusDescription {
    switch (applicationStatus) {
      case 'approved':
        return
            'Congratulations! Your SWAT RIDE driver application has been approved.';

      case 'rejected':
        return
            'Your driver application was not approved. Please review the reason below.';

      case 'pending':
      default:
        return
            'Your application has been submitted successfully. Our admin team is reviewing your documents.';
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          darkBackground,

      appBar: AppBar(
        backgroundColor:
            darkBackground,

        title: const Text(
          'Application Status',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: yellow,
            ),
            onPressed:
                isLoading
                    ? null
                    : _loadApplicationStatus,
          ),
        ],
      ),

      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  // =========================================================
  // BODY
  // =========================================================

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color: yellow,
        ),
      );
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (applicationData == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color: yellow,

      onRefresh:
          _loadApplicationStatus,

      child:
          SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(20),

        child: Column(
          children: [

            const SizedBox(height: 20),

            // =================================================
            // STATUS ICON
            // =================================================

            Container(
              width: 100,
              height: 100,

              decoration:
                  BoxDecoration(
                color:
                    statusColor
                        .withValues(
                  alpha: 0.15,
                ),

                shape:
                    BoxShape.circle,
              ),

              child:
                  Icon(
                statusIcon,

                color:
                    statusColor,

                size: 60,
              ),
            ),

            const SizedBox(height: 25),

            // =================================================
            // STATUS TITLE
            // =================================================

            Text(
              statusTitle,

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    statusColor,

                fontSize:
                    24,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // =================================================
            // STATUS DESCRIPTION
            // =================================================

            Text(
              statusDescription,

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    Colors.grey.shade400,

                fontSize:
                    14,

                height:
                    1.5,
              ),
            ),

            const SizedBox(height: 30),

            // =================================================
            // APPLICATION INFORMATION
            // =================================================

            _buildInformationCard(),

            const SizedBox(height: 20),

            // =================================================
            // REJECTION REASON
            // =================================================

            if (applicationStatus ==
                    'rejected' &&
                rejectionReason
                    .isNotEmpty)
              _buildRejectionCard(),

            const SizedBox(height: 20),

            // =================================================
            // NEXT STEP
            // =================================================

            _buildNextStepCard(),

          ],
        ),
      ),
    );
  }

  // =========================================================
  // INFORMATION CARD
  // =========================================================

  Widget _buildInformationCard() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(20),

      decoration:
          BoxDecoration(
        color:
            darkCard,

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(
            'Application Details',

            style:
                TextStyle(
              fontSize:
                  18,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _infoRow(
            icon:
                Icons.person,
            title:
                'Driver Name',
            value:
                driverName,
          ),

          _infoRow(
            icon:
                Icons.phone,
            title:
                'Phone Number',
            value:
                phoneNumber,
          ),

          _infoRow(
            icon:
                Icons.directions_car,
            title:
                'Vehicle Type',
            value:
                vehicleType,
          ),

          _infoRow(
            icon:
                Icons.confirmation_number,
            title:
                'Vehicle Number',
            value:
                vehicleNumber,
          ),

          _infoRow(
            icon:
                statusIcon,
            title:
                'Status',
            value:
                applicationStatus
                    .toUpperCase(),
            valueColor:
                statusColor,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INFO ROW
  // =========================================================

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 16,
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(
            icon,

            color:
                yellow,

            size:
                22,
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  title,

                  style:
                      TextStyle(
                    color:
                        Colors.grey.shade500,

                    fontSize:
                        12,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  value.isEmpty
                      ? 'Not available'
                      : value,

                  style:
                      TextStyle(
                    color:
                        valueColor ??
                            Colors.white,

                    fontSize:
                        15,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // REJECTION CARD
  // =========================================================

  Widget _buildRejectionCard() {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color:
            Colors.red.withValues(
          alpha: 0.10,
        ),

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              Colors.red.withValues(
            alpha: 0.30,
          ),
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Row(
            children: [

              Icon(
                Icons.warning,
                color:
                    Colors.red,
              ),

              SizedBox(
                width: 10,
              ),

              Text(
                'Admin Review',

                style:
                    TextStyle(
                  color:
                      Colors.red,

                  fontSize:
                      17,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            rejectionReason,

            style:
                const TextStyle(
              color:
                  Colors.white,

              height:
                  1.5,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // NEXT STEP CARD
  // =========================================================

  Widget _buildNextStepCard() {
    String message;

    IconData icon;

    if (applicationStatus ==
        'approved') {
      message =
          'Your driver account can now be activated. You will be able to use Driver Mode and switch between Online and Offline status.';

      icon =
          Icons.verified;
    } else if (applicationStatus ==
        'rejected') {
      message =
          'Please review the rejection reason. You may submit a new application after correcting the required information or documents.';

      icon =
          Icons.refresh;
    } else {
      message =
          'Please wait while our admin team reviews your application and documents. You can refresh this page to check for updates.';

      icon =
          Icons.access_time;
    }

    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color:
            yellow.withValues(
          alpha: 0.08,
        ),

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(
            icon,

            color:
                yellow,

            size:
                28,
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
                Text(
              message,

              style:
                  TextStyle(
                color:
                    Colors.grey.shade300,

                fontSize:
                    13,

                height:
                    1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ERROR STATE
  // =========================================================

  Widget _buildErrorState() {
    return Center(
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),

        child:
            Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            const Icon(
              Icons.error_outline,

              color:
                  Colors.red,

              size:
                  60,
            ),

            const SizedBox(
              height:
                  20,
            ),

            Text(
              errorMessage ??
                  'Something went wrong.',

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                fontSize:
                    16,
              ),
            ),

            const SizedBox(
              height:
                  20,
            ),

            ElevatedButton(
              onPressed:
                  _loadApplicationStatus,

              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    yellow,

                foregroundColor:
                    Colors.black,
              ),

              child:
                  const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

