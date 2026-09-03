import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TourismNotificationManagementScreen extends StatefulWidget {
  const TourismNotificationManagementScreen({
    super.key,
  });

  @override
  State<TourismNotificationManagementScreen> createState() =>
      _TourismNotificationManagementScreenState();
}

class _TourismNotificationManagementScreenState
    extends State<TourismNotificationManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';
  String _selectedStatus = 'all';
  String _selectedType = 'all';
  String _selectedTarget = 'all';
  String _workingNotificationId = '';

  CollectionReference<Map<String, dynamic>>
      get _notificationsCollection =>
          _firestore.collection(
            'tourism_notifications',
          );

  CollectionReference<Map<String, dynamic>>
      get _auditCollection =>
          _firestore.collection(
            'tourism_notification_audit_logs',
          );

  final List<String> _statuses = const <String>[
    'all',
    'draft',
    'scheduled',
    'queued',
    'sent',
    'failed',
    'cancelled',
    'disabled',
  ];

  final List<String> _types = const <String>[
    'all',
    'general',
    'promotion',
    'emergency',
    'tour_reminder',
    'booking_update',
    'driver_alert',
    'guide_alert',
    'weather_alert',
    'system',
  ];

  final List<String> _targets = const <String>[
    'all',
    'all_tourists',
    'selected_tourists',
    'all_drivers',
    'selected_drivers',
    'all_guides',
    'selected_guides',
    'booking_participants',
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
          'Tourism Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Create notification',
            onPressed:
                _workingNotificationId.isNotEmpty
                    ? null
                    : _openCreateNotificationSheet,
            icon: const Icon(
              Icons.add_alert_outlined,
              color: yellow,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream:
              _notificationsCollection.snapshots(),
          builder: (
            context,
            AsyncSnapshot<
                    QuerySnapshot<
                        Map<String, dynamic>>>
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
                    'Unable to Load Notifications',
                message:
                    snapshot.error.toString(),
              );
            }

            final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>
                allDocuments =
                snapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>
                visibleDocuments =
                allDocuments.where(
              (
                QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    document,
              ) {
                final Map<String, dynamic>
                    data = document.data();

                final String status =
                    data['status']
                            ?.toString() ??
                        'draft';

                final String type =
                    data['type']
                            ?.toString() ??
                        'general';

                final String target =
                    data['target']
                            ?.toString() ??
                        'all_tourists';

                if (_selectedStatus !=
                        'all' &&
                    status !=
                        _selectedStatus) {
                  return false;
                }

                if (_selectedType != 'all' &&
                    type != _selectedType) {
                  return false;
                }

                if (_selectedTarget !=
                        'all' &&
                    target !=
                        _selectedTarget) {
                  return false;
                }

                final String query =
                    _searchText
                        .trim()
                        .toLowerCase();

                if (query.isEmpty) {
                  return true;
                }

                final List<String> values =
                    <String>[
                  document.id,
                  data['notificationId']
                          ?.toString() ??
                      '',
                  data['title']
                          ?.toString() ??
                      '',
                  data['body']
                          ?.toString() ??
                      '',
                  type,
                  target,
                  status,
                  data['bookingId']
                          ?.toString() ??
                      '',
                  data['adminNote']
                          ?.toString() ??
                      '',
                ];

                return values.any(
                  (String value) =>
                      value
                          .toLowerCase()
                          .contains(query),
                );
              },
            ).toList();

            visibleDocuments.sort(
              (
                QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    a,
                QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    b,
              ) {
                return _readDateTime(
                  b.data()['updatedAt'] ??
                      b.data()['createdAt'],
                ).compareTo(
                  _readDateTime(
                    a.data()['updatedAt'] ??
                        a.data()['createdAt'],
                  ),
                );
              },
            );

            return Column(
              children: [
                _summaryHeader(
                  allDocuments,
                ),
                _searchBox(),
                _filterBars(),
                Expanded(
                  child:
                      visibleDocuments.isEmpty
                          ? _messageState(
                              icon:
                                  Icons.notifications_off_outlined,
                              title:
                                  'No Notifications Found',
                              message:
                                  'No notification matches the selected filters.',
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
                                  visibleDocuments
                                      .length,
                              itemBuilder: (
                                context,
                                index,
                              ) {
                                return _notificationCard(
                                  visibleDocuments[
                                      index],
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _workingNotificationId.isNotEmpty
                ? null
                : _openCreateNotificationSheet,
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        icon: const Icon(
          Icons.add_alert,
        ),
        label: const Text(
          'Create',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _summaryHeader(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
  ) {
    int draft = 0;
    int scheduled = 0;
    int sent = 0;
    int failed = 0;
    int emergency = 0;

    for (final document in documents) {
      final Map<String, dynamic> data =
          document.data();

      final String status =
          data['status']?.toString() ??
              'draft';

      final String type =
          data['type']?.toString() ??
              'general';

      switch (status) {
        case 'draft':
          draft++;
          break;
        case 'scheduled':
        case 'queued':
          scheduled++;
          break;
        case 'sent':
          sent++;
          break;
        case 'failed':
          failed++;
          break;
      }

      if (type == 'emergency') {
        emergency++;
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
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
            'Draft',
            draft,
            Colors.grey,
          ),
          _summaryItem(
            'Scheduled',
            scheduled,
            Colors.blue,
          ),
          _summaryItem(
            'Sent',
            sent,
            Colors.green,
          ),
          _summaryItem(
            'Failed',
            failed,
            Colors.red,
          ),
          _summaryItem(
            'Emergency',
            emergency,
            Colors.orange,
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
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        8,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (String value) {
          setState(() {
            _searchText = value;
          });
        },
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText:
              'Search notification, booking or admin note...',
          hintStyle: const TextStyle(
            color: Colors.grey,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: yellow,
          ),
          suffixIcon:
              _searchText.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController
                            .clear();

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
                BorderRadius.circular(
              15,
            ),
            borderSide:
                BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _filterBars() {
    return Column(
      children: [
        _choiceBar(
          items: _statuses,
          selected:
              _selectedStatus,
          labelBuilder:
              _statusLabel,
          onSelected: (String value) {
            setState(() {
              _selectedStatus = value;
            });
          },
        ),
        const SizedBox(height: 5),
        _choiceBar(
          items: _types,
          selected: _selectedType,
          labelBuilder: _typeLabel,
          onSelected: (String value) {
            setState(() {
              _selectedType = value;
            });
          },
        ),
        const SizedBox(height: 5),
        _choiceBar(
          items: _targets,
          selected: _selectedTarget,
          labelBuilder: _targetLabel,
          onSelected: (String value) {
            setState(() {
              _selectedTarget = value;
            });
          },
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _choiceBar({
    required List<String> items,
    required String selected,
    required String Function(String)
        labelBuilder,
    required ValueChanged<String>
        onSelected,
  }) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        scrollDirection:
            Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: 8),
        itemBuilder: (
          context,
          index,
        ) {
          final String value =
              items[index];

          final bool isSelected =
              value == selected;

          return ChoiceChip(
            selected: isSelected,
            label: Text(
              labelBuilder(value),
            ),
            selectedColor:
                yellow.withValues(
              alpha: 0.24,
            ),
            checkmarkColor: yellow,
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.grey,
              fontWeight:
                  FontWeight.bold,
              fontSize: 10,
            ),
            onSelected: (_) {
              onSelected(value);
            },
          );
        },
      ),
    );
  }

  Widget _notificationCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final String title =
        data['title']?.toString() ??
            'Notification';

    final String body =
        data['body']?.toString() ??
            '';

    final String status =
        data['status']?.toString() ??
            'draft';

    final String type =
        data['type']?.toString() ??
            'general';

    final String target =
        data['target']?.toString() ??
            'all_tourists';

    final bool enabled =
        data['isEnabled'] != false;

    final int estimatedRecipients =
        _readInt(
      data['estimatedRecipients'],
    );

    final int sentCount =
        _readInt(
      data['sentCount'],
    );

    final int failedCount =
        _readInt(
      data['failedCount'],
    );

    final int openedCount =
        _readInt(
      data['openedCount'],
    );

    final DateTime scheduledAt =
        _readDateTime(
      data['scheduledAt'],
    );

    final DateTime createdAt =
        _readDateTime(
      data['createdAt'],
    );

    final List<String> recipientIds =
        _readStringList(
      data['recipientIds'],
    );

    final bool working =
        _workingNotificationId ==
            document.id;

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
                  color: _typeColor(type)
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  _typeIcon(type),
                  color: _typeColor(type),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_typeLabel(type)} â€¢ ${_targetLabel(target)}',
                      style:
                          const TextStyle(
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
          if (body.trim().isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(
              body,
              maxLines: 4,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _smallBadge(
                enabled
                    ? 'Enabled'
                    : 'Disabled',
                enabled
                    ? Colors.green
                    : Colors.grey,
              ),
              if (scheduledAt
                      .millisecondsSinceEpoch !=
                  0)
                _smallBadge(
                  _formatDateTime(
                    scheduledAt,
                  ),
                  Colors.blue,
                ),
              if (recipientIds.isNotEmpty)
                _smallBadge(
                  '${recipientIds.length} selected',
                  Colors.purple,
                ),
            ],
          ),
          const SizedBox(height: 11),
          _detailRow(
            'Estimated Recipients',
            '$estimatedRecipients',
          ),
          _detailRow(
            'Sent',
            '$sentCount',
          ),
          _detailRow(
            'Failed',
            '$failedCount',
          ),
          _detailRow(
            'Opened',
            '$openedCount',
          ),
          if (createdAt
                  .millisecondsSinceEpoch !=
              0)
            _detailRow(
              'Created',
              _formatDateTime(
                createdAt,
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: working
                      ? null
                      : () {
                          _openEditNotificationSheet(
                            document,
                          );
                        },
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label: const Text(
                    'Edit',
                  ),
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
                    strokeWidth: 2,
                    color: yellow,
                  ),
                )
              else
                PopupMenuButton<String>(
                  color: darkCard,
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                  onSelected: (
                    String action,
                  ) {
                    _handleAction(
                      action: action,
                      document: document,
                    );
                  },
                  itemBuilder: (
                    context,
                  ) =>
                      <PopupMenuEntry<
                          String>>[
                    if (<String>{
                      'draft',
                      'failed',
                      'cancelled',
                    }.contains(status))
                      const PopupMenuItem(
                        value: 'queue',
                        child: Text(
                          'Queue for Sending',
                        ),
                      ),
                    if (<String>{
                      'queued',
                      'scheduled',
                    }.contains(status))
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Text(
                          'Cancel Notification',
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'resend',
                      child: Text(
                        'Duplicate / Resend',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_enabled',
                      child: Text(
                        enabled
                            ? 'Disable'
                            : 'Enable',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'history',
                      child: Text(
                        'View Audit History',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
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

  Future<void>
      _openCreateNotificationSheet() async {
    final _NotificationFormResult? result =
        await _showNotificationForm();

    if (result == null) {
      return;
    }

    await _createNotification(result);
  }

  Future<void>
      _openEditNotificationSheet(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final _NotificationFormResult? result =
        await _showNotificationForm(
      existing: document.data(),
    );

    if (result == null) {
      return;
    }

    await _updateNotification(
      document: document,
      result: result,
    );
  }

  Future<_NotificationFormResult?>
      _showNotificationForm({
    Map<String, dynamic>? existing,
  }) async {
    final TextEditingController
        titleController =
        TextEditingController(
      text:
          existing?['title']?.toString() ??
              '',
    );

    final TextEditingController
        bodyController =
        TextEditingController(
      text:
          existing?['body']?.toString() ??
              '',
    );

    final TextEditingController
        bookingIdController =
        TextEditingController(
      text:
          existing?['bookingId']
                  ?.toString() ??
              '',
    );

    final TextEditingController
        recipientIdsController =
        TextEditingController(
      text: _readStringList(
        existing?['recipientIds'],
      ).join(', '),
    );

    final TextEditingController
        deepLinkController =
        TextEditingController(
      text:
          existing?['deepLink']
                  ?.toString() ??
              '',
    );

    final TextEditingController
        imageUrlController =
        TextEditingController(
      text:
          existing?['imageUrl']
                  ?.toString() ??
              '',
    );

    final TextEditingController
        localImagePathController =
        TextEditingController(
      text:
          existing?['localImagePath']
                  ?.toString() ??
              '',
    );

    final TextEditingController
        adminNoteController =
        TextEditingController(
      text:
          existing?['adminNote']
                  ?.toString() ??
              '',
    );

    final TextEditingController
        estimatedRecipientsController =
        TextEditingController(
      text: _readInt(
        existing?[
            'estimatedRecipients'],
      ).toString(),
    );

    String type =
        existing?['type']?.toString() ??
            'general';

    String target =
        existing?['target']?.toString() ??
            'all_tourists';

    String priority =
        existing?['priority']
                ?.toString() ??
            'normal';

    bool isEnabled =
        existing?['isEnabled'] != false;

    bool pushEnabled =
        existing?['pushEnabled'] != false;

    bool inAppEnabled =
        existing?['inAppEnabled'] != false;

    bool emailEnabled =
        existing?['emailEnabled'] == true;

    bool smsEnabled =
        existing?['smsEnabled'] == true;

    bool saveAsDraft =
        (existing?['status']
                    ?.toString() ??
                'draft') ==
            'draft';

    DateTime? scheduledAt =
        _readDateTimeNullable(
      existing?['scheduledAt'],
    );

    final _NotificationFormResult? result =
        await showModalBottomSheet<
            _NotificationFormResult>(
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
      builder: (
        BuildContext sheetContext,
      ) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
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
              child:
                  SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      existing == null
                          ? 'Create Tourism Notification'
                          : 'Edit Tourism Notification',
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    _sectionTitle(
                      'Message',
                    ),
                    _field(
                      controller:
                          titleController,
                      label:
                          'Notification Title',
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _field(
                      controller:
                          bodyController,
                      label:
                          'Notification Message',
                      maxLines: 5,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    _sectionTitle(
                      'Audience',
                    ),
                    DropdownButtonFormField<
                        String>(
                      initialValue: target,
                      dropdownColor: darkCard,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Target Audience',
                      ),
                      items: _targets
                          .where(
                            (String item) =>
                                item != 'all',
                          )
                          .map(
                            (String item) =>
                                DropdownMenuItem<
                                    String>(
                              value: item,
                              child: Text(
                                _targetLabel(
                                  item,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged:
                          (String? value) {
                        if (value == null) {
                          return;
                        }

                        setSheetState(() {
                          target = value;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (target.startsWith(
                      'selected_',
                    ))
                      _field(
                        controller:
                            recipientIdsController,
                        label:
                            'Recipient IDs (comma separated)',
                        maxLines: 3,
                      ),
                    if (target ==
                        'booking_participants') ...[
                      const SizedBox(
                        height: 10,
                      ),
                      _field(
                        controller:
                            bookingIdController,
                        label:
                            'Tour Booking ID',
                      ),
                    ],
                    const SizedBox(
                      height: 10,
                    ),
                    _field(
                      controller:
                          estimatedRecipientsController,
                      label:
                          'Estimated Recipients',
                      keyboardType:
                          TextInputType.number,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    _sectionTitle(
                      'Notification Type',
                    ),
                    DropdownButtonFormField<
                        String>(
                      initialValue: type,
                      dropdownColor: darkCard,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Notification Type',
                      ),
                      items: _types
                          .where(
                            (String item) =>
                                item != 'all',
                          )
                          .map(
                            (String item) =>
                                DropdownMenuItem<
                                    String>(
                              value: item,
                              child: Text(
                                _typeLabel(
                                  item,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged:
                          (String? value) {
                        if (value == null) {
                          return;
                        }

                        setSheetState(() {
                          type = value;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    DropdownButtonFormField<
                        String>(
                      initialValue:
                          priority,
                      dropdownColor: darkCard,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Priority',
                      ),
                      items:
                          const <String>[
                        'low',
                        'normal',
                        'high',
                        'urgent',
                      ]
                              .map(
                                (String item) =>
                                    DropdownMenuItem<
                                        String>(
                                  value: item,
                                  child: Text(
                                    _capitalize(
                                      item,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (String? value) {
                        if (value == null) {
                          return;
                        }

                        setSheetState(() {
                          priority = value;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    _sectionTitle(
                      'Schedule',
                    ),
                    InkWell(
                      onTap: () async {
                        final DateTime now =
                            DateTime.now();

                        final DateTime? date =
                            await showDatePicker(
                          context: context,
                          initialDate:
                              scheduledAt ??
                                  now,
                          firstDate: now,
                          lastDate: now.add(
                            const Duration(
                              days: 730,
                            ),
                          ),
                        );

                        if (date == null) {
                          return;
                        }

                        if (!context.mounted) {
                          return;
                        }

                        final TimeOfDay? time =
                            await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay.fromDateTime(
                            scheduledAt ??
                                now.add(
                                  const Duration(
                                    hours: 1,
                                  ),
                                ),
                          ),
                        );

                        if (time == null) {
                          return;
                        }

                        setSheetState(() {
                          scheduledAt =
                              DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                          saveAsDraft = false;
                        });
                      },
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Scheduled Date & Time',
                        ),
                        child: Text(
                          scheduledAt == null
                              ? 'Send when queued'
                              : _formatDateTime(
                                  scheduledAt!,
                                ),
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (scheduledAt !=
                        null)
                      Align(
                        alignment: Alignment
                            .centerRight,
                        child:
                            TextButton.icon(
                          onPressed: () {
                            setSheetState(
                              () {
                                scheduledAt =
                                    null;
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.close,
                            color: yellow,
                          ),
                          label: const Text(
                            'Clear Schedule',
                            style:
                                TextStyle(
                              color: yellow,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    _switchTile(
                      title:
                          'Save as Draft',
                      value: saveAsDraft,
                      onChanged:
                          (bool value) {
                        setSheetState(() {
                          saveAsDraft =
                              value;

                          if (value) {
                            scheduledAt =
                                null;
                          }
                        });
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    _sectionTitle(
                      'Delivery Channels',
                    ),
                    _switchTile(
                      title:
                          'In-app Notification',
                      value: inAppEnabled,
                      onChanged:
                          (bool value) {
                        setSheetState(() {
                          inAppEnabled =
                              value;
                        });
                      },
                    ),
                    _switchTile(
                      title:
                          'Push Notification',
                      value: pushEnabled,
                      onChanged:
                          (bool value) {
                        setSheetState(() {
                          pushEnabled =
                              value;
                        });
                      },
                    ),
                    _switchTile(
                      title:
                          'Email Notification',
                      value: emailEnabled,
                      onChanged:
                          (bool value) {
                        setSheetState(() {
                          emailEnabled =
                              value;
                        });
                      },
                    ),
                    _switchTile(
                      title:
                          'SMS Notification',
                      value: smsEnabled,
                      onChanged:
                          (bool value) {
                        setSheetState(() {
                          smsEnabled =
                              value;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    _sectionTitle(
                      'Optional Data',
                    ),
                    _field(
                      controller:
                          deepLinkController,
                      label:
                          'Deep Link / Screen Route',
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _field(
                      controller:
                          imageUrlController,
                      label:
                          'Remote Image URL',
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _field(
                      controller:
                          localImagePathController,
                      label:
                          'Local Image Path (Storage bypass)',
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _field(
                      controller:
                          adminNoteController,
                      label:
                          'Admin Note',
                      maxLines: 3,
                    ),
                    _switchTile(
                      title: 'Enabled',
                      value: isEnabled,
                      onChanged:
                          (bool value) {
                        setSheetState(() {
                          isEnabled =
                              value;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton(
                        onPressed: () {
                          if (titleController
                                  .text
                                  .trim()
                                  .isEmpty ||
                              bodyController
                                  .text
                                  .trim()
                                  .isEmpty) {
                            return;
                          }

                          Navigator.pop(
                            sheetContext,
                            _NotificationFormResult(
                              title:
                                  titleController
                                      .text
                                      .trim(),
                              body:
                                  bodyController
                                      .text
                                      .trim(),
                              target: target,
                              recipientIds:
                                  _splitValues(
                                recipientIdsController
                                    .text,
                              ),
                              bookingId:
                                  bookingIdController
                                      .text
                                      .trim(),
                              type: type,
                              priority:
                                  priority,
                              scheduledAt:
                                  scheduledAt,
                              saveAsDraft:
                                  saveAsDraft,
                              inAppEnabled:
                                  inAppEnabled,
                              pushEnabled:
                                  pushEnabled,
                              emailEnabled:
                                  emailEnabled,
                              smsEnabled:
                                  smsEnabled,
                              deepLink:
                                  deepLinkController
                                      .text
                                      .trim(),
                              imageUrl:
                                  imageUrlController
                                      .text
                                      .trim(),
                              localImagePath:
                                  localImagePathController
                                      .text
                                      .trim(),
                              adminNote:
                                  adminNoteController
                                      .text
                                      .trim(),
                              estimatedRecipients:
                                  int.tryParse(
                                        estimatedRecipientsController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              isEnabled:
                                  isEnabled,
                            ),
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
                        child: Text(
                          existing == null
                              ? 'Create Notification'
                              : 'Save Changes',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
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
      },
    );

    for (final TextEditingController controller
        in <TextEditingController>[
      titleController,
      bodyController,
      bookingIdController,
      recipientIdsController,
      deepLinkController,
      imageUrlController,
      localImagePathController,
      adminNoteController,
      estimatedRecipientsController,
    ]) {
      controller.dispose();
    }

    return result;
  }

  Future<void> _createNotification(
    _NotificationFormResult result,
  ) async {
    final DocumentReference<
            Map<String, dynamic>>
        reference =
        _notificationsCollection.doc();

    await _setWorking(
      reference.id,
      () async {
        final String status =
            result.saveAsDraft
                ? 'draft'
                : result.scheduledAt !=
                        null
                    ? 'scheduled'
                    : 'queued';

        await reference.set(
          <String, dynamic>{
            'notificationId':
                reference.id,
            ...result.toMap(),
            'status': status,
            'sentCount': 0,
            'failedCount': 0,
            'openedCount': 0,
            'deliveryProvider':
                'not_configured',
            'realPushSent': false,
            'storageUploadUsed': false,
            'createdByRole':
                'tourism_admin',
            'createdAt':
                FieldValue
                    .serverTimestamp(),
            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
        );

        await _saveAudit(
          notificationId:
              reference.id,
          action:
              'notification_created',
          details:
              'Tourism notification created with status $status.',
        );
      },
    );

    _showMessage(
      'Tourism notification created.',
    );
  }

  Future<void> _updateNotification({
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
    required _NotificationFormResult result,
  }) async {
    await _setWorking(
      document.id,
      () async {
        final String currentStatus =
            document.data()['status']
                    ?.toString() ??
                'draft';

        final String newStatus =
            result.saveAsDraft
                ? 'draft'
                : result.scheduledAt !=
                        null
                    ? 'scheduled'
                    : currentStatus ==
                            'sent'
                        ? 'sent'
                        : 'queued';

        await document.reference.set(
          <String, dynamic>{
            ...result.toMap(),
            'status': newStatus,
            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _saveAudit(
          notificationId:
              document.id,
          action:
              'notification_updated',
          details:
              'Tourism notification updated.',
        );
      },
    );

    _showMessage(
      'Notification updated.',
    );
  }

  Future<void> _handleAction({
    required String action,
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  }) async {
    switch (action) {
      case 'queue':
        await _updateSimpleField(
          document: document,
          update: <String, dynamic>{
            'status': 'queued',
            'queuedAt':
                FieldValue
                    .serverTimestamp(),
          },
          action:
              'notification_queued',
          details:
              'Notification queued for backend delivery.',
        );
        break;
      case 'cancel':
        await _updateSimpleField(
          document: document,
          update: <String, dynamic>{
            'status': 'cancelled',
            'cancelledAt':
                FieldValue
                    .serverTimestamp(),
          },
          action:
              'notification_cancelled',
          details:
              'Notification cancelled.',
        );
        break;
      case 'resend':
        await _duplicateNotification(
          document,
        );
        break;
      case 'toggle_enabled':
        final bool newValue =
            document.data()['isEnabled'] ==
                    false
                ? true
                : false;

        await _updateSimpleField(
          document: document,
          update: <String, dynamic>{
            'isEnabled': newValue,
            if (!newValue)
              'status': 'disabled',
          },
          action: newValue
              ? 'notification_enabled'
              : 'notification_disabled',
          details: newValue
              ? 'Notification enabled.'
              : 'Notification disabled.',
        );
        break;
      case 'history':
        _showHistory(document);
        break;
      case 'delete':
        await _deleteNotification(
          document,
        );
        break;
    }
  }

  Future<void> _duplicateNotification(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(
      document.data(),
    );

    final DocumentReference<
            Map<String, dynamic>>
        reference =
        _notificationsCollection.doc();

    data.remove('createdAt');
    data.remove('updatedAt');
    data.remove('sentAt');
    data.remove('cancelledAt');
    data.remove('queuedAt');
    data.remove('notificationId');

    await _setWorking(
      document.id,
      () async {
        await reference.set(
          <String, dynamic>{
            ...data,
            'notificationId':
                reference.id,
            'title':
                '${data['title']?.toString() ?? 'Notification'} Copy',
            'status': 'draft',
            'sentCount': 0,
            'failedCount': 0,
            'openedCount': 0,
            'realPushSent': false,
            'createdByRole':
                'tourism_admin',
            'createdAt':
                FieldValue
                    .serverTimestamp(),
            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
        );

        await _saveAudit(
          notificationId:
              reference.id,
          action:
              'notification_duplicated',
          details:
              'Notification duplicated from ${document.id}.',
        );
      },
    );

    _showMessage(
      'Notification duplicated as draft.',
    );
  }

  Future<void> _deleteNotification(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final bool confirmed =
        await _confirmAction(
      title:
          'Delete Notification',
      message:
          'Permanently delete this tourism notification?',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (!confirmed) {
      return;
    }

    await _setWorking(
      document.id,
      () async {
        await document.reference.delete();

        await _saveAudit(
          notificationId:
              document.id,
          action:
              'notification_deleted',
          details:
              'Tourism notification permanently deleted.',
        );
      },
    );

    _showMessage(
      'Notification deleted.',
    );
  }

  Future<void> _updateSimpleField({
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
                FieldValue
                    .serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _saveAudit(
          notificationId:
              document.id,
          action: action,
          details: details,
        );
      },
    );

    _showMessage(
      'Notification updated.',
    );
  }

  Future<void> _saveAudit({
    required String notificationId,
    required String action,
    required String details,
  }) async {
    await _auditCollection.add(
      <String, dynamic>{
        'notificationId':
            notificationId,
        'action': action,
        'details': details,
        'performedByRole':
            'tourism_admin',
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _setWorking(
    String notificationId,
    Future<void> Function() action,
  ) async {
    setState(() {
      _workingNotificationId =
          notificationId;
    });

    try {
      await action();
    } catch (error) {
      _showMessage(
        'Unable to update notification: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _workingNotificationId = '';
        });
      }
    }
  }

  void _showHistory(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          darkBackground,
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
                    'notificationId',
                    isEqualTo:
                        document.id,
                  )
                  .snapshots(),
              builder: (
                context,
                snapshot,
              ) {
                final List<
                        QueryDocumentSnapshot<
                            Map<String,
                                dynamic>>>
                    logs =
                    snapshot.data?.docs ??
                        <QueryDocumentSnapshot<
                            Map<String,
                                dynamic>>>[];

                logs.sort(
                  (a, b) =>
                      _readDateTime(
                        b.data()[
                            'createdAt'],
                      ).compareTo(
                        _readDateTime(
                          a.data()[
                              'createdAt'],
                        ),
                      ),
                );

                return Column(
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.all(
                        18,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: yellow,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Notification Audit History',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 19,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: logs.isEmpty
                          ? const Center(
                              child: Text(
                                'No notification history yet.',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets
                                      .fromLTRB(
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
                                final Map<
                                        String,
                                        dynamic>
                                    data =
                                    logs[index]
                                        .data();

                                return Container(
                                  margin:
                                      const EdgeInsets
                                          .only(
                                    bottom: 9,
                                  ),
                                  padding:
                                      const EdgeInsets
                                          .all(
                                    13,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        darkCard,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      14,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        data['action']
                                                ?.toString() ??
                                            'Action',
                                        style:
                                            const TextStyle(
                                          color:
                                              yellow,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        data['details']
                                                ?.toString() ??
                                            '',
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.grey,
                                          fontSize:
                                              11,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        _formatDateTime(
                                          _readDateTime(
                                            data[
                                                'createdAt'],
                                          ),
                                        ),
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.grey,
                                          fontSize:
                                              9,
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
        labelStyle:
            const TextStyle(
          color: Colors.grey,
        ),
        filled: true,
        fillColor: darkBackground,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            13,
          ),
          borderSide:
              BorderSide.none,
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool>
        onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      value: value,
      activeThumbColor: yellow,
      onChanged: onChanged,
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: yellow,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (
            BuildContext dialogContext,
          ) =>
              AlertDialog(
            backgroundColor: darkCard,
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(
                color: Colors.grey,
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
                child:
                    const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      destructive
                          ? Colors.red
                          : yellow,
                  foregroundColor:
                      destructive
                          ? Colors.white
                          : Colors.black,
                ),
                child: Text(
                  confirmLabel,
                ),
              ),
            ],
          ),
        ) ??
        false;
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
      _statusLabel(status),
      _statusColor(status),
    );
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 7,
      ),
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
              textAlign:
                  TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight:
                    FontWeight.bold,
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
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(
    String status,
  ) {
    switch (status) {
      case 'all':
        return 'All Status';
      default:
        return status
            .split('_')
            .map(_capitalize)
            .join(' ');
    }
  }

  String _typeLabel(
    String type,
  ) {
    switch (type) {
      case 'all':
        return 'All Types';
      default:
        return type
            .split('_')
            .map(_capitalize)
            .join(' ');
    }
  }

  String _targetLabel(
    String target,
  ) {
    switch (target) {
      case 'all':
        return 'All Targets';
      case 'all_tourists':
        return 'All Tourists';
      case 'selected_tourists':
        return 'Selected Tourists';
      case 'all_drivers':
        return 'All Drivers';
      case 'selected_drivers':
        return 'Selected Drivers';
      case 'all_guides':
        return 'All Guides';
      case 'selected_guides':
        return 'Selected Guides';
      case 'booking_participants':
        return 'Booking Participants';
      default:
        return target
            .split('_')
            .map(_capitalize)
            .join(' ');
    }
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'sent':
        return Colors.green;
      case 'scheduled':
      case 'queued':
        return Colors.blue;
      case 'failed':
        return Colors.red;
      case 'cancelled':
      case 'disabled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  Color _typeColor(
    String type,
  ) {
    switch (type) {
      case 'emergency':
        return Colors.redAccent;
      case 'promotion':
        return Colors.purple;
      case 'tour_reminder':
        return Colors.blue;
      case 'booking_update':
        return Colors.teal;
      case 'driver_alert':
        return Colors.indigo;
      case 'guide_alert':
        return Colors.deepPurple;
      case 'weather_alert':
        return Colors.cyan;
      case 'system':
        return Colors.grey;
      default:
        return yellow;
    }
  }

  IconData _typeIcon(
    String type,
  ) {
    switch (type) {
      case 'emergency':
        return Icons.warning_amber_outlined;
      case 'promotion':
        return Icons.campaign_outlined;
      case 'tour_reminder':
        return Icons.alarm_outlined;
      case 'booking_update':
        return Icons.book_online_outlined;
      case 'driver_alert':
        return Icons.airport_shuttle_outlined;
      case 'guide_alert':
        return Icons.person_pin_circle_outlined;
      case 'weather_alert':
        return Icons.cloud_outlined;
      case 'system':
        return Icons.settings_outlined;
      default:
        return Icons.notifications_active_outlined;
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

  List<String> _readStringList(
    dynamic value,
  ) {
    if (value is List) {
      return value
          .map(
            (dynamic item) =>
                item.toString().trim(),
          )
          .where(
            (String item) =>
                item.isNotEmpty,
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
          (String item) => item.trim(),
        )
        .where(
          (String item) =>
              item.isNotEmpty,
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

    return DateTime
        .fromMillisecondsSinceEpoch(
      0,
    );
  }

  DateTime? _readDateTimeNullable(
    dynamic value,
  ) {
    final DateTime result =
        _readDateTime(value);

    if (result.millisecondsSinceEpoch ==
        0) {
      return null;
    }

    return result;
  }

  String _formatDateTime(
    DateTime date,
  ) {
    final String day =
        date.day
            .toString()
            .padLeft(2, '0');

    final String month =
        date.month
            .toString()
            .padLeft(2, '0');

    final String hour =
        date.hour
            .toString()
            .padLeft(2, '0');

    final String minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    return '$day/$month/${date.year} $hour:$minute';
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

class _NotificationFormResult {
  const _NotificationFormResult({
    required this.title,
    required this.body,
    required this.target,
    required this.recipientIds,
    required this.bookingId,
    required this.type,
    required this.priority,
    required this.scheduledAt,
    required this.saveAsDraft,
    required this.inAppEnabled,
    required this.pushEnabled,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.deepLink,
    required this.imageUrl,
    required this.localImagePath,
    required this.adminNote,
    required this.estimatedRecipients,
    required this.isEnabled,
  });

  final String title;
  final String body;
  final String target;
  final List<String> recipientIds;
  final String bookingId;
  final String type;
  final String priority;
  final DateTime? scheduledAt;
  final bool saveAsDraft;
  final bool inAppEnabled;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final String deepLink;
  final String imageUrl;
  final String localImagePath;
  final String adminNote;
  final int estimatedRecipients;
  final bool isEnabled;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'body': body,
      'target': target,
      'recipientIds': recipientIds,
      'bookingId': bookingId,
      'type': type,
      'priority': priority,
      'scheduledAt':
          scheduledAt == null
              ? null
              : Timestamp.fromDate(
                  scheduledAt!,
                ),
      'saveAsDraft': saveAsDraft,
      'inAppEnabled': inAppEnabled,
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'smsEnabled': smsEnabled,
      'deepLink': deepLink,
      'imageUrl': imageUrl,
      'localImagePath':
          localImagePath,
      'adminNote': adminNote,
      'estimatedRecipients':
          estimatedRecipients,
      'isEnabled': isEnabled,
    };
  }
}

