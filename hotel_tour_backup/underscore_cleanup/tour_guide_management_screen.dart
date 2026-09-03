import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TourGuideManagementScreen extends StatefulWidget {
  const TourGuideManagementScreen({
    super.key,
  });

  @override
  State<TourGuideManagementScreen> createState() =>
      _TourGuideManagementScreenState();
}

class _TourGuideManagementScreenState
    extends State<TourGuideManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedStatus = 'all';
  String _searchText = '';
  String _workingGuideId = '';

  CollectionReference<Map<String, dynamic>>
      get _applicationsCollection =>
          _firestore.collection(
            'tour_guide_applications',
          );

  CollectionReference<Map<String, dynamic>>
      get _auditCollection =>
          _firestore.collection(
            'tour_guide_audit_logs',
          );

  final List<String> _statuses = const <String>[
    'all',
    'pending',
    'approved',
    'rejected',
    'suspended',
    'inactive',
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
          'Tour Guide Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream:
              _applicationsCollection.snapshots(),
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
                title:
                    'Unable to Load Guides',
                message:
                    snapshot.error.toString(),
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
                    _guideStatus(data);

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
                  data['guideId']?.toString() ?? '',
                  data['userId']?.toString() ?? '',
                  data['fullName']?.toString() ?? '',
                  data['name']?.toString() ?? '',
                  data['phone']?.toString() ?? '',
                  data['email']?.toString() ?? '',
                  data['cnic']?.toString() ?? '',
                  ..._readStringList(
                    data['languages'],
                  ),
                  ..._readStringList(
                    data['specializations'],
                  ),
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
                              Icons.person_search_outlined,
                          title: 'No Guides Found',
                          message:
                              'No guide matches the selected search and status.',
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
                            return _guideCard(
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
    int approved = 0;
    int suspended = 0;
    int featured = 0;

    for (final document in documents) {
      final data = document.data();
      final status = _guideStatus(data);

      if (status == 'pending') {
        pending++;
      } else if (status == 'approved') {
        approved++;
      } else if (status == 'suspended') {
        suspended++;
      }

      if (data['isFeatured'] == true) {
        featured++;
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
            'Approved',
            approved,
            Colors.green,
          ),
          _summaryItem(
            'Suspended',
            suspended,
            Colors.red,
          ),
          _summaryItem(
            'Featured',
            featured,
            yellow,
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
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 9,
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
              'Search guide, phone, CNIC, language or skill...',
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
        separatorBuilder: (_, __) =>
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
              _capitalize(status),
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

  Widget _guideCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final data = document.data();
    final name =
        data['fullName']?.toString() ??
            data['name']?.toString() ??
            'Tour Guide';
    final phone =
        data['phone']?.toString() ?? '';
    final status = _guideStatus(data);
    final experience = _readInt(
      data['experienceYears'] ??
          data['experience'],
    );
    final dailyPrice = _readDouble(
      data['dailyPrice'] ??
          data['pricePerDay'],
    );
    final rating = _readDouble(
      data['averageRating'],
    );
    final reviewCount = _readInt(
      data['reviewCount'],
    );
    final languages = _readStringList(
      data['languages'],
    );
    final specializations =
        _readStringList(
      data['specializations'],
    );
    final isFeatured =
        data['isFeatured'] == true;
    final isAvailable =
        data['isAvailable'] != false;
    final policeVerified =
        data['policeVerified'] == true;
    final documentsVerified =
        data['documentsVerified'] == true;
    final working =
        _workingGuideId == document.id;

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
                  Icons.person_pin_circle_outlined,
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
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone.isEmpty
                          ? 'Guide Application'
                          : phone,
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
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isFeatured)
                _smallBadge(
                  'Featured',
                  yellow,
                ),
              _smallBadge(
                isAvailable
                    ? 'Available'
                    : 'Unavailable',
                isAvailable
                    ? Colors.green
                    : Colors.grey,
              ),
              if (policeVerified)
                _smallBadge(
                  'Police Verified',
                  Colors.blue,
                ),
              if (documentsVerified)
                _smallBadge(
                  'Documents Verified',
                  Colors.teal,
                ),
              if (rating > 0)
                _smallBadge(
                  '${rating.toStringAsFixed(1)} ($reviewCount)',
                  Colors.orange,
                ),
            ],
          ),
          const SizedBox(height: 11),
          _detailRow(
            'Experience',
            experience > 0
                ? '$experience years'
                : 'Not added',
          ),
          _detailRow(
            'Daily Price',
            dailyPrice > 0
                ? 'PKR ${_money(dailyPrice)}'
                : 'Not set',
          ),
          _detailRow(
            'Languages',
            languages.isEmpty
                ? 'Not added'
                : languages.join(', '),
          ),
          _detailRow(
            'Specializations',
            specializations.isEmpty
                ? 'Not added'
                : specializations.join(', '),
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
                          _openEditGuideSheet(
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
                    if (status == 'approved')
                      const PopupMenuItem(
                        value: 'suspend',
                        child: Text('Suspend'),
                      ),
                    if (<String>{
                      'suspended',
                      'inactive',
                    }.contains(status))
                      const PopupMenuItem(
                        value: 'activate',
                        child: Text('Activate'),
                      ),
                    PopupMenuItem(
                      value: 'featured',
                      child: Text(
                        isFeatured
                            ? 'Remove Featured'
                            : 'Mark Featured',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'availability',
                      child: Text(
                        isAvailable
                            ? 'Mark Unavailable'
                            : 'Mark Available',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'verify_documents',
                      child: Text(
                        'Verify Documents',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'verify_police',
                      child: Text(
                        'Police Verification',
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

  Future<void> _openEditGuideSheet(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final data = document.data();

    final priceController =
        TextEditingController(
      text: _readDouble(
        data['dailyPrice'] ??
            data['pricePerDay'],
      ).toStringAsFixed(0),
    );
    final experienceController =
        TextEditingController(
      text: _readInt(
        data['experienceYears'] ??
            data['experience'],
      ).toString(),
    );
    final languagesController =
        TextEditingController(
      text: _readStringList(
        data['languages'],
      ).join(', '),
    );
    final specializationsController =
        TextEditingController(
      text: _readStringList(
        data['specializations'],
      ).join(', '),
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
                  'Edit Tour Guide',
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
                      experienceController,
                  label:
                      'Experience Years',
                  keyboardType:
                      TextInputType.number,
                ),
                const SizedBox(height: 10),
                _field(
                  controller:
                      priceController,
                  label:
                      'Daily Price (PKR)',
                  keyboardType:
                      TextInputType.number,
                ),
                const SizedBox(height: 10),
                _field(
                  controller:
                      languagesController,
                  label:
                      'Languages (comma separated)',
                ),
                const SizedBox(height: 10),
                _field(
                  controller:
                      specializationsController,
                  label:
                      'Specializations (comma separated)',
                  maxLines: 2,
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
                          'experienceYears':
                              int.tryParse(
                                    experienceController
                                        .text
                                        .trim(),
                                  ) ??
                                  0,
                          'dailyPrice':
                              double.tryParse(
                                    priceController
                                        .text
                                        .trim(),
                                  ) ??
                                  0,
                          'languages':
                              _splitValues(
                            languagesController
                                .text,
                          ),
                          'specializations':
                              _splitValues(
                            specializationsController
                                .text,
                          ),
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

    priceController.dispose();
    experienceController.dispose();
    languagesController.dispose();
    specializationsController.dispose();
    noteController.dispose();

    if (result == null) {
      return;
    }

    await _updateGuide(
      document: document,
      update: result,
      action: 'guide_edited',
      details:
          'Tour guide details edited by admin.',
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
        await _updateGuide(
          document: document,
          update: <String, dynamic>{
            'applicationStatus':
                'approved',
            'status': 'approved',
            'isActive': true,
            'approvedAt':
                FieldValue.serverTimestamp(),
          },
          action: 'guide_approved',
          details:
              'Tour guide application approved.',
        );
        break;
      case 'reject':
        final reason =
            await _reasonDialog(
          title: 'Reject Guide',
          label: 'Rejection Reason',
        );
        if (reason != null) {
          await _updateGuide(
            document: document,
            update: <String, dynamic>{
              'applicationStatus':
                  'rejected',
              'status': 'rejected',
              'rejectionReason': reason,
              'rejectedAt':
                  FieldValue
                      .serverTimestamp(),
            },
            action: 'guide_rejected',
            details:
                'Guide rejected: $reason',
          );
        }
        break;
      case 'suspend':
        final reason =
            await _reasonDialog(
          title: 'Suspend Guide',
          label: 'Suspension Reason',
        );
        if (reason != null) {
          await _updateGuide(
            document: document,
            update: <String, dynamic>{
              'applicationStatus':
                  'suspended',
              'status': 'suspended',
              'isActive': false,
              'suspensionReason': reason,
              'suspendedAt':
                  FieldValue
                      .serverTimestamp(),
            },
            action: 'guide_suspended',
            details:
                'Guide suspended: $reason',
          );
        }
        break;
      case 'activate':
        await _updateGuide(
          document: document,
          update: <String, dynamic>{
            'applicationStatus':
                'approved',
            'status': 'approved',
            'isActive': true,
            'activatedAt':
                FieldValue.serverTimestamp(),
          },
          action: 'guide_activated',
          details: 'Guide activated.',
        );
        break;
      case 'featured':
        final newValue =
            document.data()['isFeatured'] ==
                    true
                ? false
                : true;
        await _updateGuide(
          document: document,
          update: <String, dynamic>{
            'isFeatured': newValue,
          },
          action: newValue
              ? 'guide_featured'
              : 'guide_unfeatured',
          details: newValue
              ? 'Guide marked featured.'
              : 'Guide removed from featured.',
        );
        break;
      case 'availability':
        final newValue =
            document.data()['isAvailable'] ==
                    false
                ? true
                : false;
        await _updateGuide(
          document: document,
          update: <String, dynamic>{
            'isAvailable': newValue,
          },
          action:
              'guide_availability_changed',
          details: newValue
              ? 'Guide marked available.'
              : 'Guide marked unavailable.',
        );
        break;
      case 'verify_documents':
        await _updateGuide(
          document: document,
          update: <String, dynamic>{
            'documentsVerified': true,
            'documentsVerifiedAt':
                FieldValue.serverTimestamp(),
          },
          action:
              'guide_documents_verified',
          details:
              'Guide documents verified.',
        );
        break;
      case 'verify_police':
        await _updateGuide(
          document: document,
          update: <String, dynamic>{
            'policeVerified': true,
            'policeVerifiedAt':
                FieldValue.serverTimestamp(),
          },
          action:
              'guide_police_verified',
          details:
              'Guide police verification completed.',
        );
        break;
      case 'history':
        _showHistory(document);
        break;
    }
  }

  Future<void> _updateGuide({
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
            'guideApplicationId':
                document.id,
            'guideId':
                document.data()['guideId']
                        ?.toString() ??
                    document.id,
            'userId':
                document.data()['userId']
                        ?.toString() ??
                    '',
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
      'Guide updated successfully.',
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
                    'guideApplicationId',
                    isEqualTo: document.id,
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
                            'Guide Audit History',
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
                                'No guide history yet.',
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
    String guideId,
    Future<void> Function() action,
  ) async {
    setState(() {
      _workingGuideId = guideId;
    });

    try {
      await action();
    } catch (error) {
      _showMessage(
        'Unable to update guide: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _workingGuideId = '';
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

  Widget _smallBadge(
    String label,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.12,
        ),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    return _smallBadge(
      _capitalize(status),
      _statusColor(status),
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

  String _guideStatus(
    Map<String, dynamic> data,
  ) {
    return data['applicationStatus']
            ?.toString() ??
        data['status']?.toString() ??
        'pending';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'suspended':
        return Colors.deepOrange;
      case 'inactive':
        return Colors.grey;
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

  List<String> _readStringList(
    dynamic value,
  ) {
    if (value is List) {
      return value
          .map(
            (item) =>
                item.toString().trim(),
          )
          .where(
            (item) => item.isNotEmpty,
          )
          .toList();
    }
    return const <String>[];
  }

  static List<String> _splitValues(
    String value,
  ) {
    return value
        .split(',')
        .map(
          (item) => item.trim(),
        )
        .where(
          (item) => item.isNotEmpty,
        )
        .toList();
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

  String _formatDateTime(
    DateTime date,
  ) {
    if (date.millisecondsSinceEpoch ==
        0) {
      return '';
    }
    final day =
        date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');
    final hour =
        date.hour.toString().padLeft(2, '0');
    final minute = date.minute
        .toString()
        .padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
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
