import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HotelHousekeepingScreen extends StatefulWidget {
  const HotelHousekeepingScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelHousekeepingScreen> createState() =>
      _HotelHousekeepingScreenState();
}

class _HotelHousekeepingScreenState
    extends State<HotelHousekeepingScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String _selectedFilter = 'all';
  bool _isWorking = false;

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
          'Housekeeping Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('hotel_rooms')
              .where(
                'hotelId',
                isEqualTo: widget.hotelId,
              )
              .snapshots(),
          builder: (
            context,
            AsyncSnapshot<
                    QuerySnapshot<Map<String, dynamic>>>
                roomSnapshot,
          ) {
            if (roomSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: yellow,
                ),
              );
            }

            if (roomSnapshot.hasError) {
              return _messageState(
                icon: Icons.error_outline,
                title: 'Unable to Load Rooms',
                message:
                    roomSnapshot.error.toString(),
              );
            }

            final List<QueryDocumentSnapshot<
                    Map<String, dynamic>>>
                rooms =
                roomSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            rooms.sort(
              (a, b) {
                final String aNumber =
                    a.data()['roomNumber']
                            ?.toString() ??
                        a.id;

                final String bNumber =
                    b.data()['roomNumber']
                            ?.toString() ??
                        b.id;

                return aNumber.compareTo(
                  bNumber,
                );
              },
            );

            final filtered =
                rooms.where(
              (room) {
                final String status =
                    _housekeepingStatus(
                  room.data(),
                );

                return _selectedFilter == 'all' ||
                    status == _selectedFilter;
              },
            ).toList();

            return RefreshIndicator(
              color: yellow,
              backgroundColor: darkCard,
              onRefresh: () async {
                await _firestore
                    .collection('hotel_rooms')
                    .where(
                      'hotelId',
                      isEqualTo: widget.hotelId,
                    )
                    .get();
              },
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  30,
                ),
                children: [
                  _summaryCard(rooms),

                  const SizedBox(height: 16),

                  _guestReminderCard(),

                  const SizedBox(height: 16),

                  _filterChips(),

                  const SizedBox(height: 18),

                  if (filtered.isEmpty)
                    _messageState(
                      icon:
                          Icons.cleaning_services_outlined,
                      title:
                          'No Housekeeping Tasks',
                      message:
                          'No rooms match the selected housekeeping status.',
                    )
                  else
                    ...filtered.map(
                      _roomCard,
                    ),

                  const SizedBox(height: 16),

                  _noticeCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        rooms,
  ) {
    int dirty = 0;
    int cleaning = 0;
    int ready = 0;
    int inspected = 0;

    for (final room in rooms) {
      switch (_housekeepingStatus(
        room.data(),
      )) {
        case 'dirty':
          dirty++;
          break;
        case 'cleaning':
          cleaning++;
          break;
        case 'ready':
          ready++;
          break;
        case 'inspected':
          inspected++;
          break;
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _summaryTile(
          title: 'Dirty',
          value: '$dirty',
          icon: Icons.warning_amber_outlined,
          color: Colors.orange,
        ),
        _summaryTile(
          title: 'Cleaning',
          value: '$cleaning',
          icon:
              Icons.cleaning_services_outlined,
          color: Colors.blue,
        ),
        _summaryTile(
          title: 'Ready',
          value: '$ready',
          icon:
              Icons.check_circle_outline,
          color: Colors.green,
        ),
        _summaryTile(
          title: 'Inspected',
          value: '$inspected',
          icon:
              Icons.verified_outlined,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _summaryTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
          ),
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _guestReminderCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: yellow,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Polite Guest Check-out Reminder',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Before leaving, please take a quick moment to check your personal belongings such as your phone, charger, wallet, documents and valuables. We also kindly request that room keys and hotel-provided items remain in the room or are returned to reception. Thank you for staying with us, and we wish you a pleasant journey.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    const List<String> filters =
        <String>[
      'all',
      'dirty',
      'cleaning',
      'ready',
      'inspected',
    ];

    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,
      child: Row(
        children: filters.map(
          (String filter) {
            final bool selected =
                _selectedFilter == filter;

            return Padding(
              padding:
                  const EdgeInsets.only(
                right: 8,
              ),
              child: ChoiceChip(
                selected: selected,
                label: Text(
                  _statusLabel(filter),
                ),
                selectedColor:
                    yellow.withValues(
                  alpha: 0.25,
                ),
                checkmarkColor: yellow,
                labelStyle: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.grey,
                  fontWeight:
                      FontWeight.bold,
                ),
                side: BorderSide(
                  color: selected
                      ? yellow
                      : Colors.white.withValues(
                          alpha: 0.06,
                        ),
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _roomCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        room,
  ) {
    final Map<String, dynamic> data =
        room.data();

    final String roomId =
        data['roomId']?.toString() ??
            room.id;

    final String roomNumber =
        data['roomNumber']?.toString() ??
            roomId;

    final String roomName =
        data['name']?.toString() ??
            data['roomName']?.toString() ??
            data['roomType']?.toString() ??
            'Room';

    final String status =
        _housekeepingStatus(data);

    final String assignedStaff =
        data['housekeepingStaffName']
                ?.toString() ??
            '';

    final String priority =
        data['housekeepingPriority']
                ?.toString() ??
            'normal';

    final String notes =
        data['housekeepingNotes']
                ?.toString() ??
            '';

    final Color statusColor =
        _statusColor(status);

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
          color: statusColor.withValues(
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
                  color:
                      statusColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  _statusIcon(status),
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room $roomNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roomName,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow(
            'Assigned Staff',
            assignedStaff.isEmpty
                ? 'Not assigned'
                : assignedStaff,
          ),
          _detailRow(
            'Priority',
            _capitalize(priority),
          ),
          if (notes.trim().isNotEmpty)
            _detailRow(
              'Notes',
              notes,
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: _isWorking
                      ? null
                      : () {
                          _openTaskSheet(
                            roomId: roomId,
                            roomNumber:
                                roomNumber,
                            currentStatus:
                                status,
                            currentStaff:
                                assignedStaff,
                            currentPriority:
                                priority,
                            currentNotes:
                                notes,
                          );
                        },
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label: const Text(
                    'Update Task',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child:
                    ElevatedButton.icon(
                  onPressed: _isWorking
                      ? null
                      : () {
                          _openInspectionSheet(
                            roomId: roomId,
                            roomNumber:
                                roomNumber,
                          );
                        },
                  icon: const Icon(
                    Icons.fact_check_outlined,
                  ),
                  label: const Text(
                    'Inspect',
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor:
                        Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openTaskSheet({
    required String roomId,
    required String roomNumber,
    required String currentStatus,
    required String currentStaff,
    required String currentPriority,
    required String currentNotes,
  }) async {
    String status = currentStatus;
    String priority = currentPriority;

    final TextEditingController
        staffController =
        TextEditingController(
      text: currentStaff,
    );

    final TextEditingController
        notesController =
        TextEditingController(
      text: currentNotes,
    );

    final bool? saved =
        await showModalBottomSheet<bool>(
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
      builder: (context) {
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room $roomNumber Task',
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    DropdownButtonFormField<
                        String>(
                      initialValue: status,
                      dropdownColor: darkCard,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Housekeeping Status',
                      ),
                      items:
                          const <String>[
                        'dirty',
                        'cleaning',
                        'ready',
                        'inspected',
                      ]
                              .map(
                                (value) =>
                                    DropdownMenuItem<
                                        String>(
                                  value: value,
                                  child: Text(
                                    _statusLabel(
                                      value,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setSheetState(() {
                          status = value;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    DropdownButtonFormField<
                        String>(
                      initialValue: priority,
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
                                (value) =>
                                    DropdownMenuItem<
                                        String>(
                                  value: value,
                                  child: Text(
                                    _capitalize(
                                      value,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setSheetState(() {
                          priority = value;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller:
                          staffController,
                      style:
                          const TextStyle(
                        color: Colors.white,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Assigned staff name',
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller:
                          notesController,
                      maxLines: 3,
                      style:
                          const TextStyle(
                        color: Colors.white,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Task notes',
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            true,
                          );
                        },
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              yellow,
                          foregroundColor:
                              Colors.black,
                        ),
                        child: const Text(
                          'Save Task',
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

    if (saved == true) {
      await _saveTask(
        roomId: roomId,
        status: status,
        priority: priority,
        staffName:
            staffController.text.trim(),
        notes:
            notesController.text.trim(),
      );
    }

    staffController.dispose();
    notesController.dispose();
  }

  Future<void> _openInspectionSheet({
    required String roomId,
    required String roomNumber,
  }) async {
    bool guestItemsFound = false;
    bool hotelItemsMissing = false;
    bool damageFound = false;
    bool minibarUsed = false;

    final TextEditingController
        notesController =
        TextEditingController();

    final bool? save =
        await showModalBottomSheet<bool>(
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
      builder: (context) {
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room $roomNumber Inspection',
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    SwitchListTile(
                      value:
                          guestItemsFound,
                      onChanged: (value) {
                        setSheetState(() {
                          guestItemsFound =
                              value;
                        });
                      },
                      activeThumbColor:
                          yellow,
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Guest belongings found',
                      ),
                    ),
                    SwitchListTile(
                      value:
                          hotelItemsMissing,
                      onChanged: (value) {
                        setSheetState(() {
                          hotelItemsMissing =
                              value;
                        });
                      },
                      activeThumbColor:
                          yellow,
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Hotel item appears missing',
                      ),
                    ),
                    SwitchListTile(
                      value: damageFound,
                      onChanged: (value) {
                        setSheetState(() {
                          damageFound =
                              value;
                        });
                      },
                      activeThumbColor:
                          yellow,
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Room damage found',
                      ),
                    ),
                    SwitchListTile(
                      value: minibarUsed,
                      onChanged: (value) {
                        setSheetState(() {
                          minibarUsed =
                              value;
                        });
                      },
                      activeThumbColor:
                          yellow,
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Mini-bar usage reported',
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller:
                          notesController,
                      maxLines: 4,
                      style:
                          const TextStyle(
                        color: Colors.white,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Inspection notes',
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            true,
                          );
                        },
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              yellow,
                          foregroundColor:
                              Colors.black,
                        ),
                        child: const Text(
                          'Save Inspection',
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

    if (save == true) {
      await _saveInspection(
        roomId: roomId,
        roomNumber: roomNumber,
        guestItemsFound:
            guestItemsFound,
        hotelItemsMissing:
            hotelItemsMissing,
        damageFound: damageFound,
        minibarUsed: minibarUsed,
        notes:
            notesController.text.trim(),
      );
    }

    notesController.dispose();
  }

  Future<void> _saveTask({
    required String roomId,
    required String status,
    required String priority,
    required String staffName,
    required String notes,
  }) async {
    setState(() {
      _isWorking = true;
    });

    try {
      await _firestore
          .collection('hotel_rooms')
          .doc(roomId)
          .set(
        <String, dynamic>{
          'housekeepingStatus': status,
          'housekeepingPriority':
              priority,
          'housekeepingStaffName':
              staffName,
          'housekeepingNotes': notes,
          'housekeepingUpdatedAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (status == 'ready' ||
          status == 'inspected') {
        await _firestore
            .collection('hotel_rooms')
            .doc(roomId)
            .set(
          <String, dynamic>{
            'manualStatus': 'available',
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      _showMessage(
        'Housekeeping task updated.',
      );
    } catch (error) {
      _showMessage(
        'Unable to update housekeeping task: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _saveInspection({
    required String roomId,
    required String roomNumber,
    required bool guestItemsFound,
    required bool hotelItemsMissing,
    required bool damageFound,
    required bool minibarUsed,
    required String notes,
  }) async {
    setState(() {
      _isWorking = true;
    });

    try {
      final DocumentReference<Map<String, dynamic>>
          inspectionReference =
          _firestore
              .collection(
                'hotel_housekeeping_inspections',
              )
              .doc();

      await inspectionReference.set(
        <String, dynamic>{
          'inspectionId':
              inspectionReference.id,
          'hotelId': widget.hotelId,
          'roomId': roomId,
          'roomNumber': roomNumber,
          'guestItemsFound':
              guestItemsFound,
          'hotelItemsMissing':
              hotelItemsMissing,
          'damageFound': damageFound,
          'minibarUsed': minibarUsed,
          'notes': notes,
          'reviewStatus':
              hotelItemsMissing ||
                      damageFound
                  ? 'needs_review'
                  : 'completed',
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      await _firestore
          .collection('hotel_rooms')
          .doc(roomId)
          .set(
        <String, dynamic>{
          'housekeepingStatus':
              'inspected',
          'manualStatus':
              hotelItemsMissing ||
                      damageFound
                  ? 'maintenance'
                  : 'available',
          'lastInspectionId':
              inspectionReference.id,
          'lastInspectionAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (guestItemsFound) {
        await _firestore
            .collection(
              'hotel_lost_and_found',
            )
            .add(
          <String, dynamic>{
            'hotelId': widget.hotelId,
            'roomId': roomId,
            'roomNumber': roomNumber,
            'status': 'found',
            'notes': notes,
            'createdAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      _showMessage(
        'Room inspection saved.',
      );
    } catch (error) {
      _showMessage(
        'Unable to save inspection: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }

    // Real damage or missing-item charges remain disabled.
    // No guest wallet or payment is changed automatically.
  }

  String _housekeepingStatus(
    Map<String, dynamic> data,
  ) {
    return data['housekeepingStatus']
            ?.toString() ??
        'ready';
  }

  Widget _statusBadge(
    String status,
  ) {
    final Color color =
        _statusColor(status);

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
            BorderRadius.circular(18),
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

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
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
                fontSize: 11,
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
                fontSize: 11,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticeCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: yellow,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Inspection records are saved to Firestore. Missing-item or damage reports never charge the guest automatically. Hotel/admin review and evidence are required before any future billing action.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                height: 1.4,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: yellow,
            size: 46,
          ),
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
            style: const TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'dirty':
        return Colors.orange;
      case 'cleaning':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'inspected':
        return Colors.purple;
      default:
        return yellow;
    }
  }

  IconData _statusIcon(
    String status,
  ) {
    switch (status) {
      case 'dirty':
        return Icons.warning_amber_outlined;
      case 'cleaning':
        return Icons.cleaning_services_outlined;
      case 'ready':
        return Icons.check_circle_outline;
      case 'inspected':
        return Icons.verified_outlined;
      default:
        return Icons.meeting_room_outlined;
    }
  }

  static String _statusLabel(
    String status,
  ) {
    switch (status) {
      case 'all':
        return 'All';
      case 'dirty':
        return 'Dirty';
      case 'cleaning':
        return 'Cleaning';
      case 'ready':
        return 'Ready';
      case 'inspected':
        return 'Inspected';
      default:
        return status;
    }
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
              isError ? Colors.red : darkCard,
        ),
      );
  }
}
