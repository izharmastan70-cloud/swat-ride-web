import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TourBookingManagementScreen extends StatefulWidget {
  const TourBookingManagementScreen({
    super.key,
  });

  @override
  State<TourBookingManagementScreen> createState() =>
      _TourBookingManagementScreenState();
}

class _TourBookingManagementScreenState
    extends State<TourBookingManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedStatus = 'all';
  String _searchText = '';
  String _workingBookingId = '';

  CollectionReference<Map<String, dynamic>>
      get _bookingsCollection =>
          _firestore.collection('tour_bookings');

  CollectionReference<Map<String, dynamic>>
      get _auditCollection =>
          _firestore.collection(
            'tour_booking_audit_logs',
          );

  final List<String> _statuses = const <String>[
    'all',
    'pending',
    'confirmed',
    'assigned',
    'in_progress',
    'completed',
    'cancelled',
    'refund_requested',
    'refunded',
  ];

  @override
  void dispose() {
    _searchController.dispose();
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
          'Tour Booking Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _bookingsCollection.snapshots(),
          builder: (
            context,
            AsyncSnapshot<
                    QuerySnapshot<Map<String, dynamic>>>
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
              return _messageState(
                icon: Icons.error_outline,
                title: 'Unable to Load Bookings',
                message: snapshot.error.toString(),
              );
            }

            final allDocuments =
                snapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            final visibleDocuments =
                allDocuments.where(
              (document) {
                final data = document.data();
                final status =
                    _bookingStatus(data);

                if (_selectedStatus != 'all' &&
                    status != _selectedStatus) {
                  return false;
                }

                final query =
                    _searchText.trim().toLowerCase();

                if (query.isEmpty) {
                  return true;
                }

                final values = <String>[
                  document.id,
                  data['bookingId']?.toString() ?? '',
                  data['customerName']?.toString() ?? '',
                  data['userName']?.toString() ?? '',
                  data['customerPhone']?.toString() ?? '',
                  data['packageName']?.toString() ?? '',
                  data['destinationName']?.toString() ?? '',
                  data['driverName']?.toString() ?? '',
                  data['guideName']?.toString() ?? '',
                  data['vehicleName']?.toString() ?? '',
                ];

                return values.any(
                  (value) => value
                      .toLowerCase()
                      .contains(query),
                );
              },
            ).toList();

            visibleDocuments.sort(
              (a, b) => _readDateTime(
                b.data()['updatedAt'] ??
                    b.data()['createdAt'],
              ).compareTo(
                _readDateTime(
                  a.data()['updatedAt'] ??
                      a.data()['createdAt'],
                ),
              ),
            );

            return Column(
              children: [
                _summaryHeader(allDocuments),
                _searchBox(),
                _statusFilters(),
                Expanded(
                  child: visibleDocuments.isEmpty
                      ? _messageState(
                          icon:
                              Icons.book_online_outlined,
                          title: 'No Bookings Found',
                          message:
                              'No booking matches the selected search and status.',
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            24,
                          ),
                          itemCount:
                              visibleDocuments.length,
                          itemBuilder: (
                            context,
                            index,
                          ) {
                            return _bookingCard(
                              visibleDocuments[index],
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

  Widget _summaryHeader(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
  ) {
    int pending = 0;
    int confirmed = 0;
    int active = 0;
    int completed = 0;
    int cancelled = 0;

    for (final document in documents) {
      final status =
          _bookingStatus(document.data());

      switch (status) {
        case 'pending':
          pending++;
          break;
        case 'confirmed':
        case 'assigned':
          confirmed++;
          break;
        case 'in_progress':
          active++;
          break;
        case 'completed':
          completed++;
          break;
        case 'cancelled':
          cancelled++;
          break;
      }
    }

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        8,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        children: [
          _summaryItem(
            'Pending',
            pending,
            Colors.orange,
          ),
          _summaryItem(
            'Confirmed',
            confirmed,
            Colors.blue,
          ),
          _summaryItem(
            'Active',
            active,
            Colors.purple,
          ),
          _summaryItem(
            'Completed',
            completed,
            Colors.green,
          ),
          _summaryItem(
            'Cancelled',
            cancelled,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String title,
    int value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        8,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText:
              'Search booking, customer, package, guide or driver...',
          hintStyle: const TextStyle(
            color: Colors.grey,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: yellow,
          ),
          suffixIcon: _searchText.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchText = '';
                    });
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.grey,
                  ),
                ),
          filled: true,
          fillColor: darkCard,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _statusFilters() {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        scrollDirection:
            Axis.horizontal,
        itemCount: _statuses.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: 8),
        itemBuilder: (
          context,
          index,
        ) {
          final status = _statuses[index];
          final selected =
              status == _selectedStatus;

          return ChoiceChip(
            selected: selected,
            label: Text(
              _statusLabel(status),
            ),
            selectedColor:
                yellow.withValues(
              alpha: 0.24,
            ),
            checkmarkColor: yellow,
            labelStyle: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
            onSelected: (_) {
              setState(() {
                _selectedStatus = status;
              });
            },
          );
        },
      ),
    );
  }

  Widget _bookingCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final data = document.data();
    final bookingId =
        data['bookingId']?.toString() ??
            document.id;
    final customer =
        data['customerName']?.toString() ??
            data['userName']?.toString() ??
            'Customer';
    final packageName =
        data['packageName']?.toString() ??
            'Tour Package';
    final destination =
        data['destinationName']?.toString() ??
            data['destination']?.toString() ??
            'Destination';
    final status = _bookingStatus(data);
    final amount = _readDouble(
      data['totalAmount'] ??
          data['finalPrice'] ??
          data['estimatedPrice'],
    );
    final travellers = _readInt(
      data['travellers'] ??
          data['totalPersons'],
      fallback: 1,
    );
    final driver =
        data['driverName']?.toString() ?? '';
    final guide =
        data['guideName']?.toString() ?? '';
    final vehicle =
        data['vehicleName']?.toString() ??
            data['vehicleType']?.toString() ??
            '';
    final startDate = _readDateTime(
      data['startDate'] ??
          data['tourDate'],
    );
    final working =
        _workingBookingId == document.id;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: _statusColor(status)
              .withValues(
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
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: yellow.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.tour_outlined,
                  color: yellow,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      packageName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$customer â€¢ $destination',
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow('Booking ID', bookingId),
          _detailRow(
            'Travellers',
            '$travellers',
          ),
          if (startDate
                  .millisecondsSinceEpoch !=
              0)
            _detailRow(
              'Start Date',
              _formatDate(startDate),
            ),
          if (driver.isNotEmpty)
            _detailRow('Driver', driver),
          if (guide.isNotEmpty)
            _detailRow('Guide', guide),
          if (vehicle.isNotEmpty)
            _detailRow('Vehicle', vehicle),
          _detailRow(
            'Payment',
            data['paymentStatus']
                    ?.toString() ??
                'pending',
          ),
          if (amount > 0)
            _detailRow(
              'Total',
              'PKR ${_money(amount)}',
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: working
                      ? null
                      : () =>
                          _openEditBookingSheet(
                            document,
                          ),
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label: const Text('Edit'),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor: yellow,
                    side: const BorderSide(
                      color: yellow,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (working)
                const SizedBox(
                  width: 42,
                  height: 42,
                  child:
                      CircularProgressIndicator(
                    color: yellow,
                    strokeWidth: 2,
                  ),
                )
              else
                PopupMenuButton<String>(
                  color: darkCard,
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                  onSelected: (action) {
                    _handleAction(
                      action: action,
                      document: document,
                    );
                  },
                  itemBuilder: (_) =>
                      <PopupMenuEntry<String>>[
                    if (status == 'pending')
                      const PopupMenuItem(
                        value: 'approve',
                        child: Text('Approve'),
                      ),
                    if (status == 'pending')
                      const PopupMenuItem(
                        value: 'reject',
                        child: Text('Reject'),
                      ),
                    if (<String>{
                      'confirmed',
                      'assigned',
                    }.contains(status))
                      const PopupMenuItem(
                        value: 'start',
                        child: Text(
                          'Start Tour',
                        ),
                      ),
                    if (status ==
                        'in_progress')
                      const PopupMenuItem(
                        value: 'complete',
                        child: Text(
                          'Complete Tour',
                        ),
                      ),
                    if (!<String>{
                      'completed',
                      'cancelled',
                      'refunded',
                    }.contains(status))
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Text(
                          'Cancel Booking',
                        ),
                      ),
                    if (status ==
                        'refund_requested')
                      const PopupMenuItem(
                        value: 'refund',
                        child: Text(
                          'Approve Refund',
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'history',
                      child: Text(
                        'View Audit History',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openEditBookingSheet(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final data = document.data();

    final travellersController =
        TextEditingController(
      text: _readInt(
        data['travellers'] ??
            data['totalPersons'],
        fallback: 1,
      ).toString(),
    );
    final driverController =
        TextEditingController(
      text:
          data['driverName']?.toString() ??
              '',
    );
    final driverIdController =
        TextEditingController(
      text:
          data['driverId']?.toString() ??
              '',
    );
    final guideController =
        TextEditingController(
      text:
          data['guideName']?.toString() ??
              '',
    );
    final guideIdController =
        TextEditingController(
      text:
          data['guideId']?.toString() ??
              '',
    );
    final vehicleController =
        TextEditingController(
      text: data['vehicleName']
              ?.toString() ??
          data['vehicleType']
              ?.toString() ??
          '',
    );
    final vehicleIdController =
        TextEditingController(
      text:
          data['vehicleId']?.toString() ??
              '',
    );
    final hotelController =
        TextEditingController(
      text:
          data['hotelName']?.toString() ??
              '',
    );
    final amountController =
        TextEditingController(
      text: _readDouble(
        data['totalAmount'] ??
            data['finalPrice'],
      ).toStringAsFixed(0),
    );
    final noteController =
        TextEditingController(
      text:
          data['adminNote']?.toString() ??
              '',
    );

    final result =
        await showModalBottomSheet<
            Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: darkCard,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            18,
            16,
            MediaQuery.of(context)
                    .viewInsets
                    .bottom +
                24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Tour Booking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _field(
                  controller:
                      travellersController,
                  label: 'Travellers',
                  keyboardType:
                      TextInputType.number,
                ),
                const SizedBox(height: 10),
                _field(
                  controller:
                      driverController,
                  label: 'Driver Name',
                ),
                const SizedBox(height: 10),
                _field(
                  controller:
                      driverIdController,
                  label: 'Driver ID',
                ),
                const SizedBox(height: 10),
                _field(
                  controller:
                      guideController,
                  label: 'Guide Name',
                ),
                const SizedBox(height: 10),
                _field(
                  controller:
                      guideIdController,
                  label: 'Guide ID',
                ),
                const SizedBox(height: 10),
                _field(
                  controller:
                      vehicleController,
                  label: 'Vehicle',
                ),
                const SizedBox(height: 10),
                _field(
                  controller:
                      vehicleIdController,
                  label: 'Vehicle ID',
                ),
                const SizedBox(height: 10),
                _field(
                  controller:
                      hotelController,
                  label:
                      'Hotel / Stay',
                ),
                const SizedBox(height: 10),
                _field(
                  controller:
                      amountController,
                  label:
                      'Final Amount',
                  keyboardType:
                      TextInputType.number,
                ),
                const SizedBox(height: 10),
                _field(
                  controller:
                      noteController,
                  label: 'Admin Note',
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child:
                      ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        sheetContext,
                        <String, dynamic>{
                          'travellers':
                              int.tryParse(
                                    travellersController
                                        .text
                                        .trim(),
                                  ) ??
                                  1,
                          'totalPersons':
                              int.tryParse(
                                    travellersController
                                        .text
                                        .trim(),
                                  ) ??
                                  1,
                          'driverName':
                              driverController
                                  .text
                                  .trim(),
                          'driverId':
                              driverIdController
                                  .text
                                  .trim(),
                          'guideName':
                              guideController
                                  .text
                                  .trim(),
                          'guideId':
                              guideIdController
                                  .text
                                  .trim(),
                          'vehicleName':
                              vehicleController
                                  .text
                                  .trim(),
                          'vehicleId':
                              vehicleIdController
                                  .text
                                  .trim(),
                          'hotelName':
                              hotelController
                                  .text
                                  .trim(),
                          'totalAmount':
                              double.tryParse(
                                    amountController
                                        .text
                                        .trim(),
                                  ) ??
                                  0,
                          'adminNote':
                              noteController
                                  .text
                                  .trim(),
                        },
                      );
                    },
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          yellow,
                      foregroundColor:
                          Colors.black,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    travellersController.dispose();
    driverController.dispose();
    driverIdController.dispose();
    guideController.dispose();
    guideIdController.dispose();
    vehicleController.dispose();
    vehicleIdController.dispose();
    hotelController.dispose();
    amountController.dispose();
    noteController.dispose();

    if (result == null) {
      return;
    }

    await _updateBooking(
      document: document,
      update: result,
      action: 'booking_edited',
      details:
          'Tour booking details edited by admin.',
    );
  }

  Future<void> _handleAction({
    required String action,
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  }) async {
    switch (action) {
      case 'approve':
        await _updateBooking(
          document: document,
          update: <String, dynamic>{
            'bookingStatus': 'confirmed',
            'status': 'confirmed',
            'confirmedAt':
                FieldValue.serverTimestamp(),
          },
          action: 'booking_approved',
          details:
              'Tour booking approved.',
        );
        break;
      case 'reject':
        final reason =
            await _reasonDialog(
          title: 'Reject Booking',
          label: 'Rejection Reason',
        );
        if (reason != null) {
          await _updateBooking(
            document: document,
            update: <String, dynamic>{
              'bookingStatus':
                  'cancelled',
              'status': 'cancelled',
              'cancellationReason':
                  reason,
              'cancelledAt':
                  FieldValue
                      .serverTimestamp(),
            },
            action: 'booking_rejected',
            details:
                'Booking rejected: $reason',
          );
        }
        break;
      case 'start':
        await _updateBooking(
          document: document,
          update: <String, dynamic>{
            'bookingStatus':
                'in_progress',
            'status': 'in_progress',
            'startedAt':
                FieldValue.serverTimestamp(),
          },
          action: 'tour_started',
          details: 'Tour started.',
        );
        break;
      case 'complete':
        await _updateBooking(
          document: document,
          update: <String, dynamic>{
            'bookingStatus':
                'completed',
            'status': 'completed',
            'completedAt':
                FieldValue.serverTimestamp(),
          },
          action: 'tour_completed',
          details: 'Tour completed.',
        );
        break;
      case 'cancel':
        final reason =
            await _reasonDialog(
          title: 'Cancel Booking',
          label: 'Cancellation Reason',
        );
        if (reason != null) {
          await _updateBooking(
            document: document,
            update: <String, dynamic>{
              'bookingStatus':
                  'cancelled',
              'status': 'cancelled',
              'cancellationReason':
                  reason,
              'cancelledAt':
                  FieldValue
                      .serverTimestamp(),
            },
            action: 'booking_cancelled',
            details:
                'Booking cancelled: $reason',
          );
        }
        break;
      case 'refund':
        final reason =
            await _reasonDialog(
          title: 'Approve Refund',
          label: 'Refund Note',
        );
        if (reason != null) {
          await _updateBooking(
            document: document,
            update: <String, dynamic>{
              'bookingStatus':
                  'refunded',
              'status': 'refunded',
              'paymentStatus':
                  'refunded',
              'refundReason':
                  reason,
              'refundedAt':
                  FieldValue
                      .serverTimestamp(),
            },
            action: 'refund_approved',
            details:
                'Refund approved: $reason',
          );
        }
        break;
      case 'history':
        _showHistory(document);
        break;
    }
  }

  Future<void> _updateBooking({
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
    required Map<String, dynamic>
        update,
    required String action,
    required String details,
  }) async {
    await _setWorking(
      document.id,
      () async {
        await document.reference.set(
          <String, dynamic>{
            ...update,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _auditCollection.add(
          <String, dynamic>{
            'bookingId':
                document.data()['bookingId']
                        ?.toString() ??
                    document.id,
            'bookingDocumentId':
                document.id,
            'action': action,
            'details': details,
            'performedByRole':
                'tourism_admin',
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );

    _showMessage(
      'Booking updated successfully.',
    );
  }

  Future<String?> _reasonDialog({
    required String title,
    required String label,
  }) async {
    final controller =
        TextEditingController();

    final result =
        await showDialog<String>(
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
          content: _field(
            controller: controller,
            label: label,
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text
                    .trim()
                    .isEmpty) {
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor:
                    Colors.black,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  void _showHistory(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final bookingId =
        document.data()['bookingId']
                ?.toString() ??
            document.id;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: darkBackground,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height:
                MediaQuery.of(context)
                        .size
                        .height *
                    0.72,
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: _auditCollection
                  .where(
                    'bookingId',
                    isEqualTo: bookingId,
                  )
                  .snapshots(),
              builder: (
                context,
                snapshot,
              ) {
                final logs =
                    snapshot.data?.docs ??
                        <QueryDocumentSnapshot<
                            Map<String,
                                dynamic>>>[];

                logs.sort(
                  (a, b) => _readDateTime(
                    b.data()['createdAt'],
                  ).compareTo(
                    _readDateTime(
                      a.data()['createdAt'],
                    ),
                  ),
                );

                return Column(
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: yellow,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Booking Audit History',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: logs.isEmpty
                          ? const Center(
                              child: Text(
                                'No booking history yet.',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                20,
                              ),
                              itemCount:
                                  logs.length,
                              itemBuilder: (
                                context,
                                index,
                              ) {
                                final data =
                                    logs[index]
                                        .data();

                                return Container(
                                  margin:
                                      const EdgeInsets.only(
                                    bottom: 9,
                                  ),
                                  padding:
                                      const EdgeInsets.all(
                                    13,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: darkCard,
                                    borderRadius:
                                        BorderRadius.circular(
                                      14,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['action']
                                                ?.toString() ??
                                            'Action',
                                        style: const TextStyle(
                                          color: yellow,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        data['details']
                                                ?.toString() ??
                                            '',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _formatDateTime(
                                          _readDateTime(
                                            data['createdAt'],
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
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
      },
    );
  }

  Future<void> _setWorking(
    String bookingId,
    Future<void> Function() action,
  ) async {
    setState(() {
      _workingBookingId = bookingId;
    });

    try {
      await action();
    } catch (error) {
      _showMessage(
        'Unable to update booking: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _workingBookingId = '';
        });
      }
    }
  }

  Widget _field({
    required TextEditingController
        controller,
    required String label,
    TextInputType keyboardType =
        TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.grey,
        ),
        filled: true,
        fillColor: darkBackground,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
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
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    final color = _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.13,
        ),
        borderRadius:
            BorderRadius.circular(15),
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
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              color: yellow,
              size: 48,
            ),
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
    );
  }

  String _bookingStatus(
    Map<String, dynamic> data,
  ) {
    final raw =
        data['bookingStatus']?.toString() ??
            data['status']?.toString() ??
            'pending';

    if (<String>{
      'pending_admin_review',
      'pending_confirmation',
    }.contains(raw)) {
      return 'pending';
    }

    if (<String>{
      'driver_assigned',
      'guide_assigned',
    }.contains(raw)) {
      return 'assigned';
    }

    if (<String>{
      'active',
      'started',
    }.contains(raw)) {
      return 'in_progress';
    }

    if (<String>{
      'finished',
    }.contains(raw)) {
      return 'completed';
    }

    return raw;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'all':
        return 'All';
      case 'in_progress':
        return 'In Progress';
      case 'refund_requested':
        return 'Refund Requested';
      default:
        return status
            .split('_')
            .map(_capitalize)
            .join(' ');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'refund_requested':
      case 'refunded':
        return Colors.teal;
      default:
        return Colors.orange;
    }
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

  double _readDouble(
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

  String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch ==
        0) {
      return '';
    }
    final day =
        date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatDateTime(
    DateTime date,
  ) {
    if (date.millisecondsSinceEpoch ==
        0) {
      return '';
    }
    final hour =
        date.hour.toString().padLeft(2, '0');
    final minute = date.minute
        .toString()
        .padLeft(2, '0');
    return '${_formatDate(date)} $hour:$minute';
  }

  String _money(num amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(
            r'\B(?=(\d{3})+(?!\d))',
          ),
          (_) => ',',
        );
  }

  static String _capitalize(
    String value,
  ) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() +
        value.substring(1);
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
              isError
                  ? Colors.red
                  : darkCard,
        ),
      );
  }
}

