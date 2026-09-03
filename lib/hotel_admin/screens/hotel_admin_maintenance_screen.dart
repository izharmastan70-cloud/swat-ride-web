import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HotelAdminMaintenanceScreen extends StatefulWidget {
  const HotelAdminMaintenanceScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelAdminMaintenanceScreen> createState() =>
      _HotelAdminMaintenanceScreenState();
}

class _HotelAdminMaintenanceScreenState
    extends State<HotelAdminMaintenanceScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String _selectedFilter = 'all';
  bool _isWorking = false;
  String _workingTaskId = '';

  CollectionReference<Map<String, dynamic>>
      get _tasksCollection =>
          _firestore.collection(
            'hotel_maintenance_tasks',
          );

  CollectionReference<Map<String, dynamic>>
      get _auditCollection =>
          _firestore.collection(
            'hotel_maintenance_audit_logs',
          );

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
          'Maintenance Manager',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Create maintenance task',
            onPressed: _isWorking
                ? null
                : _openCreateTaskSheet,
            icon: const Icon(
              Icons.add_circle_outline,
              color: yellow,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _tasksCollection
              .where(
                'hotelId',
                isEqualTo: widget.hotelId,
              )
              .snapshots(),
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
                    'Unable to Load Maintenance',
                message:
                    snapshot.error.toString(),
              );
            }

            final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>
                tasks =
                snapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            tasks.sort(
              (
                QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    a,
                QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    b,
              ) {
                final int priorityCompare =
                    _priorityWeight(
                      b.data()['priority']
                              ?.toString() ??
                          'normal',
                    ).compareTo(
                      _priorityWeight(
                        a.data()['priority']
                                ?.toString() ??
                            'normal',
                      ),
                    );

                if (priorityCompare != 0) {
                  return priorityCompare;
                }

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

            final filtered = tasks.where(
              (
                QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    task,
              ) {
                final String status =
                    task.data()['status']
                            ?.toString() ??
                        'open';

                return _selectedFilter ==
                        'all' ||
                    status ==
                        _selectedFilter;
              },
            ).toList();

            return RefreshIndicator(
              color: yellow,
              backgroundColor: darkCard,
              onRefresh: () async {
                await _tasksCollection
                    .where(
                      'hotelId',
                      isEqualTo:
                          widget.hotelId,
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
                  _summaryCard(tasks),
                  const SizedBox(height: 16),
                  _filterChips(),
                  const SizedBox(height: 16),
                  _safetyNotice(),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    _messageState(
                      icon:
                          Icons.build_circle_outlined,
                      title:
                          'No Maintenance Tasks',
                      message:
                          'No maintenance task matches the selected status.',
                    )
                  else
                    ...filtered.map(
                      _taskCard,
                    ),
                  const SizedBox(height: 14),
                  _storageBypassNotice(),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _isWorking
            ? null
            : _openCreateTaskSheet,
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'New Task',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        tasks,
  ) {
    int open = 0;
    int inProgress = 0;
    int awaitingInspection = 0;
    int completed = 0;
    int urgent = 0;

    for (final task in tasks) {
      final Map<String, dynamic> data =
          task.data();

      final String status =
          data['status']?.toString() ??
              'open';

      switch (status) {
        case 'open':
          open++;
          break;
        case 'in_progress':
        case 'paused':
          inProgress++;
          break;
        case 'awaiting_inspection':
          awaitingInspection++;
          break;
        case 'completed':
        case 'closed':
          completed++;
          break;
      }

      if (data['priority']?.toString() ==
          'urgent') {
        urgent++;
      }
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Maintenance Overview',
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
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _summaryTile(
              title: 'Open',
              value: '$open',
              icon:
                  Icons.pending_actions_outlined,
              color: Colors.orange,
            ),
            _summaryTile(
              title: 'In Progress',
              value: '$inProgress',
              icon:
                  Icons.engineering_outlined,
              color: Colors.blue,
            ),
            _summaryTile(
              title: 'Awaiting Inspection',
              value: '$awaitingInspection',
              icon:
                  Icons.fact_check_outlined,
              color: Colors.purple,
            ),
            _summaryTile(
              title: 'Completed',
              value: '$completed',
              icon:
                  Icons.check_circle_outline,
              color: Colors.green,
            ),
            _summaryTile(
              title: 'Urgent',
              value: '$urgent',
              icon:
                  Icons.warning_amber_outlined,
              color: Colors.redAccent,
            ),
            _summaryTile(
              title: 'Total Tasks',
              value: '${tasks.length}',
              icon:
                  Icons.build_circle_outlined,
              color: yellow,
            ),
          ],
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

  Widget _filterChips() {
    const List<String> filters =
        <String>[
      'all',
      'open',
      'in_progress',
      'paused',
      'awaiting_inspection',
      'completed',
      'closed',
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
                onSelected: (_) {
                  setState(() {
                    _selectedFilter =
                        filter;
                  });
                },
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _safetyNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color: Colors.red.withValues(
            alpha: 0.24,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            color: Colors.redAccent,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Active maintenance can block a room from booking. A completed repair must pass inspection before the room becomes available again.',
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

  Widget _taskCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final String taskId =
        data['taskId']?.toString() ??
            document.id;

    final String roomNumber =
        data['roomNumber']?.toString() ??
            'Unknown';

    final String roomName =
        data['roomName']?.toString() ??
            'Room';

    final String category =
        data['category']?.toString() ??
            'general';

    final String priority =
        data['priority']?.toString() ??
            'normal';

    final String status =
        data['status']?.toString() ??
            'open';

    final String assignedTo =
        data['assignedTechnicianName']
                ?.toString() ??
            data['assignedStaffName']
                ?.toString() ??
            '';

    final String title =
        data['title']?.toString() ??
            'Maintenance Task';

    final String notes =
        data['notes']?.toString() ??
            '';

    final double estimatedCost =
        _readDouble(
      data['estimatedCost'],
    );

    final double finalCost =
        _readDouble(
      data['finalCost'],
    );

    final DateTime dueDate =
        _readDateTime(
      data['dueDate'],
    );

    final bool roomBlocked =
        data['roomBlocked'] == true;

    final bool working =
        _workingTaskId ==
            document.id;

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
            alpha: 0.30,
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
                decoration:
                    BoxDecoration(
                  color:
                      statusColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  _categoryIcon(category),
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
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
                      'Room $roomNumber • $roomName',
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _smallBadge(
                _capitalize(category),
                _categoryColor(category),
              ),
              _smallBadge(
                _capitalize(priority),
                _priorityColor(priority),
              ),
              if (roomBlocked)
                _smallBadge(
                  'Room Blocked',
                  Colors.redAccent,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow(
            'Task ID',
            taskId,
          ),
          _detailRow(
            'Assigned To',
            assignedTo.isEmpty
                ? 'Not assigned'
                : assignedTo,
          ),
          if (dueDate
                  .millisecondsSinceEpoch !=
              0)
            _detailRow(
              'Due Date',
              _formatDate(dueDate),
            ),
          if (estimatedCost > 0)
            _detailRow(
              'Estimated Cost',
              'PKR ${_money(estimatedCost)}',
            ),
          if (finalCost > 0)
            _detailRow(
              'Final Cost',
              'PKR ${_money(finalCost)}',
            ),
          if (notes.trim().isNotEmpty)
            _detailRow(
              'Notes',
              notes,
            ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: working
                      ? null
                      : () {
                          _openEditTaskSheet(
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
                    _handleTaskAction(
                      action: action,
                      document: document,
                    );
                  },
                  itemBuilder: (
                    context,
                  ) =>
                      <PopupMenuEntry<
                          String>>[
                    if (status == 'open')
                      const PopupMenuItem(
                        value: 'start',
                        child: Text(
                          'Start work',
                        ),
                      ),
                    if (status ==
                        'in_progress')
                      const PopupMenuItem(
                        value: 'pause',
                        child: Text(
                          'Pause work',
                        ),
                      ),
                    if (status == 'paused')
                      const PopupMenuItem(
                        value: 'resume',
                        child: Text(
                          'Resume work',
                        ),
                      ),
                    if (status ==
                            'in_progress' ||
                        status == 'paused')
                      const PopupMenuItem(
                        value:
                            'complete',
                        child: Text(
                          'Mark repair complete',
                        ),
                      ),
                    if (status ==
                        'awaiting_inspection')
                      const PopupMenuItem(
                        value: 'inspect',
                        child: Text(
                          'Inspect and reopen',
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'history',
                      child: Text(
                        'View history',
                      ),
                    ),
                    if (status == 'open')
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete open task',
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

  Future<void> _openCreateTaskSheet() async {
    final QuerySnapshot<Map<String, dynamic>>
        roomSnapshot =
        await _firestore
            .collection('hotel_rooms')
            .where(
              'hotelId',
              isEqualTo: widget.hotelId,
            )
            .get();

    if (!mounted) {
      return;
    }

    if (roomSnapshot.docs.isEmpty) {
      _showMessage(
        'Create hotel rooms before adding maintenance tasks.',
        isError: true,
      );
      return;
    }

    String roomId =
        roomSnapshot.docs.first.id;

    final Map<String, dynamic>
        firstRoomData =
        roomSnapshot.docs.first.data();

    String roomNumber =
        firstRoomData['roomNumber']
                ?.toString() ??
            roomId;

    String roomName =
        firstRoomData['roomName']
                ?.toString() ??
            firstRoomData['name']
                ?.toString() ??
            'Room';

    String category = 'general';
    String priority = 'normal';
    bool blockRoom = true;
    DateTime? dueDate;

    final TextEditingController
        titleController =
        TextEditingController();

    final TextEditingController
        technicianController =
        TextEditingController();

    final TextEditingController
        estimatedCostController =
        TextEditingController();

    final TextEditingController
        notesController =
        TextEditingController();

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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Maintenance Task',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<
                        String>(
                      initialValue: roomId,
                      dropdownColor: darkCard,
                      decoration:
                          const InputDecoration(
                        labelText: 'Room',
                      ),
                      items:
                          roomSnapshot.docs.map(
                        (document) {
                          final data =
                              document.data();

                          final number =
                              data['roomNumber']
                                      ?.toString() ??
                                  document.id;

                          final name =
                              data['roomName']
                                      ?.toString() ??
                                  data['name']
                                      ?.toString() ??
                                  'Room';

                          return DropdownMenuItem<
                              String>(
                            value:
                                document.id,
                            child: Text(
                              'Room $number - $name',
                            ),
                          );
                        },
                      ).toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        final selected =
                            roomSnapshot.docs
                                .firstWhere(
                          (document) =>
                              document.id ==
                              value,
                        );

                        final data =
                            selected.data();

                        setSheetState(() {
                          roomId = value;
                          roomNumber =
                              data['roomNumber']
                                      ?.toString() ??
                                  value;
                          roomName =
                              data['roomName']
                                      ?.toString() ??
                                  data['name']
                                      ?.toString() ??
                                  'Room';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _sheetField(
                      controller:
                          titleController,
                      label:
                          'Task title',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<
                        String>(
                      initialValue: category,
                      dropdownColor: darkCard,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Repair category',
                      ),
                      items:
                          const <String>[
                        'general',
                        'ac',
                        'plumbing',
                        'electrical',
                        'furniture',
                        'bathroom',
                        'safety',
                        'internet',
                        'appliance',
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
                          category = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    _sheetField(
                      controller:
                          technicianController,
                      label:
                          'Assigned technician/staff',
                    ),
                    const SizedBox(height: 12),
                    _sheetField(
                      controller:
                          estimatedCostController,
                      label:
                          'Estimated cost (PKR)',
                      keyboardType:
                          TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final DateTime now =
                            DateTime.now();

                        final DateTime? selected =
                            await showDatePicker(
                          context: context,
                          initialDate:
                              dueDate ??
                                  now.add(
                                    const Duration(
                                      days: 1,
                                    ),
                                  ),
                          firstDate: now,
                          lastDate: now.add(
                            const Duration(
                              days: 730,
                            ),
                          ),
                        );

                        if (selected != null) {
                          setSheetState(() {
                            dueDate = selected;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(
                          labelText: 'Due date',
                        ),
                        child: Text(
                          dueDate == null
                              ? 'Select date'
                              : _formatDate(
                                  dueDate!,
                                ),
                          style:
                              const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sheetField(
                      controller:
                          notesController,
                      label: 'Notes',
                      maxLines: 4,
                    ),
                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Block room during maintenance',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      value: blockRoom,
                      activeThumbColor:
                          yellow,
                      onChanged: (value) {
                        setSheetState(() {
                          blockRoom = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton(
                        onPressed: () {
                          if (titleController
                              .text
                              .trim()
                              .isEmpty) {
                            return;
                          }

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
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'Create Task',
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
      },
    );

    if (saved == true) {
      await _createTask(
        roomId: roomId,
        roomNumber: roomNumber,
        roomName: roomName,
        title:
            titleController.text.trim(),
        category: category,
        priority: priority,
        assignedTechnician:
            technicianController.text.trim(),
        estimatedCost:
            double.tryParse(
                  estimatedCostController
                      .text
                      .trim(),
                ) ??
                0,
        dueDate: dueDate,
        notes:
            notesController.text.trim(),
        blockRoom: blockRoom,
      );
    }

    titleController.dispose();
    technicianController.dispose();
    estimatedCostController.dispose();
    notesController.dispose();
  }

  Future<void> _openEditTaskSheet(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final Map<String, dynamic> data =
        document.data();

    String priority =
        data['priority']?.toString() ??
            'normal';

    final TextEditingController
        technicianController =
        TextEditingController(
      text:
          data['assignedTechnicianName']
                  ?.toString() ??
              '',
    );

    final TextEditingController
        estimatedController =
        TextEditingController(
      text: _readDouble(
        data['estimatedCost'],
      ).toStringAsFixed(0),
    );

    final TextEditingController
        finalController =
        TextEditingController(
      text: _readDouble(
        data['finalCost'],
      ).toStringAsFixed(0),
    );

    final TextEditingController
        notesController =
        TextEditingController(
      text: data['notes']?.toString() ??
          '',
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Maintenance Task',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
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
                        if (value != null) {
                          setSheetState(() {
                            priority = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _sheetField(
                      controller:
                          technicianController,
                      label:
                          'Assigned technician',
                    ),
                    const SizedBox(height: 12),
                    _sheetField(
                      controller:
                          estimatedController,
                      label:
                          'Estimated cost',
                      keyboardType:
                          TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _sheetField(
                      controller:
                          finalController,
                      label:
                          'Final repair cost',
                      keyboardType:
                          TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _sheetField(
                      controller:
                          notesController,
                      label: 'Notes',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 14),
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
                          'Save Changes',
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
      await _updateTask(
        document: document,
        action: 'task_edited',
        details:
            'Maintenance task details edited.',
        update: <String, dynamic>{
          'priority': priority,
          'assignedTechnicianName':
              technicianController.text
                  .trim(),
          'estimatedCost':
              double.tryParse(
                    estimatedController
                        .text
                        .trim(),
                  ) ??
                  0,
          'finalCost':
              double.tryParse(
                    finalController.text
                        .trim(),
                  ) ??
                  0,
          'notes':
              notesController.text.trim(),
        },
      );
    }

    technicianController.dispose();
    estimatedController.dispose();
    finalController.dispose();
    notesController.dispose();
  }

  Future<void> _handleTaskAction({
    required String action,
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  }) async {
    switch (action) {
      case 'start':
        await _startTask(document);
        break;
      case 'pause':
        await _pauseTask(document);
        break;
      case 'resume':
        await _resumeTask(document);
        break;
      case 'complete':
        await _completeTask(document);
        break;
      case 'inspect':
        await _inspectTask(document);
        break;
      case 'history':
        _showHistory(document);
        break;
      case 'delete':
        await _deleteOpenTask(document);
        break;
    }
  }

  Future<void> _createTask({
    required String roomId,
    required String roomNumber,
    required String roomName,
    required String title,
    required String category,
    required String priority,
    required String assignedTechnician,
    required double estimatedCost,
    required DateTime? dueDate,
    required String notes,
    required bool blockRoom,
  }) async {
    setState(() {
      _isWorking = true;
    });

    try {
      final DocumentReference<
              Map<String, dynamic>>
          reference =
          _tasksCollection.doc();

      final WriteBatch batch =
          _firestore.batch();

      batch.set(
        reference,
        <String, dynamic>{
          'taskId': reference.id,
          'hotelId': widget.hotelId,
          'roomId': roomId,
          'roomNumber': roomNumber,
          'roomName': roomName,
          'title': title,
          'category': category,
          'priority': priority,
          'assignedTechnicianName':
              assignedTechnician,
          'estimatedCost':
              estimatedCost,
          'finalCost': 0,
          'dueDate': dueDate == null
              ? null
              : Timestamp.fromDate(
                  dueDate,
                ),
          'notes': notes,
          'status': 'open',
          'roomBlocked': blockRoom,
          'beforeImageUrl': '',
          'afterImageUrl': '',
          'localBeforeImagePath': '',
          'localAfterImagePath': '',
          'storageUploadUsed': false,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      if (blockRoom) {
        batch.set(
          _firestore
              .collection('hotel_rooms')
              .doc(roomId),
          <String, dynamic>{
            'manualStatus':
                'maintenance',
            'maintenanceTaskId':
                reference.id,
            'maintenanceReason':
                title,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      await _saveAudit(
        taskId: reference.id,
        roomId: roomId,
        action: 'task_created',
        details:
            'Maintenance task created.',
      );

      _showMessage(
        'Maintenance task created.',
      );
    } catch (error) {
      _showMessage(
        'Unable to create maintenance task: $error',
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

  Future<void> _startTask(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    await _updateTask(
      document: document,
      action: 'task_started',
      details:
          'Maintenance work started.',
      update: <String, dynamic>{
        'status': 'in_progress',
        'startedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _pauseTask(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    await _updateTask(
      document: document,
      action: 'task_paused',
      details:
          'Maintenance work paused.',
      update: <String, dynamic>{
        'status': 'paused',
        'pausedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _resumeTask(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    await _updateTask(
      document: document,
      action: 'task_resumed',
      details:
          'Maintenance work resumed.',
      update: <String, dynamic>{
        'status': 'in_progress',
        'resumedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _completeTask(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final bool confirmed =
        await _confirmAction(
      title:
          'Mark Repair Complete',
      message:
          'Mark repair work complete and send it for inspection?',
      confirmLabel:
          'Send for Inspection',
    );

    if (!confirmed) {
      return;
    }

    await _updateTask(
      document: document,
      action: 'repair_completed',
      details:
          'Repair completed and awaiting inspection.',
      update: <String, dynamic>{
        'status':
            'awaiting_inspection',
        'repairCompletedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _inspectTask(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final TextEditingController
        notesController =
        TextEditingController();

    bool passed = true;

    final bool? saved =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) =>
          StatefulBuilder(
        builder: (
          context,
          setDialogState,
        ) =>
            AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Maintenance Inspection',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding:
                    EdgeInsets.zero,
                title: const Text(
                  'Repair passed inspection',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                value: passed,
                activeThumbColor: yellow,
                onChanged: (value) {
                  setDialogState(() {
                    passed = value;
                  });
                },
              ),
              _sheetField(
                controller:
                    notesController,
                label:
                    'Inspection notes',
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor:
                    Colors.black,
              ),
              child: const Text(
                'Save Inspection',
              ),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      notesController.dispose();
      return;
    }

    final Map<String, dynamic> data =
        document.data();

    final String roomId =
        data['roomId']?.toString() ??
            '';

    await _setWorking(
      document.id,
      () async {
        final WriteBatch batch =
            _firestore.batch();

        batch.set(
          document.reference,
          <String, dynamic>{
            'status': passed
                ? 'completed'
                : 'in_progress',
            'inspectionPassed':
                passed,
            'inspectionNotes':
                notesController.text
                    .trim(),
            'inspectedAt':
                FieldValue
                    .serverTimestamp(),
            if (passed)
              'completedAt':
                  FieldValue
                      .serverTimestamp(),
            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        if (roomId.isNotEmpty) {
          batch.set(
            _firestore
                .collection(
                  'hotel_rooms',
                )
                .doc(roomId),
            <String, dynamic>{
              'manualStatus': passed
                  ? 'available'
                  : 'maintenance',
              'maintenanceTaskId':
                  passed
                      ? ''
                      : document.id,
              'maintenanceReason':
                  passed
                      ? ''
                      : data['title']
                              ?.toString() ??
                          'Maintenance',
              'updatedAt':
                  FieldValue
                      .serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        await batch.commit();

        await _saveAudit(
          taskId: document.id,
          roomId: roomId,
          action: passed
              ? 'inspection_passed'
              : 'inspection_failed',
          details: passed
              ? 'Repair passed inspection and room reopened.'
              : 'Repair failed inspection and returned to work.',
        );
      },
    );

    notesController.dispose();

    _showMessage(
      passed
          ? 'Room reopened after inspection.'
          : 'Task returned to in-progress.',
    );
  }

  Future<void> _deleteOpenTask(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    if (document.data()['status']
            ?.toString() !=
        'open') {
      _showMessage(
        'Only open maintenance tasks can be deleted.',
        isError: true,
      );
      return;
    }

    final bool confirmed =
        await _confirmAction(
      title:
          'Delete Maintenance Task',
      message:
          'Delete this open maintenance task?',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (!confirmed) {
      return;
    }

    final String roomId =
        document.data()['roomId']
                ?.toString() ??
            '';

    final bool roomBlocked =
        document.data()['roomBlocked'] ==
            true;

    await _setWorking(
      document.id,
      () async {
        final WriteBatch batch =
            _firestore.batch();

        batch.delete(
          document.reference,
        );

        if (roomBlocked &&
            roomId.isNotEmpty) {
          batch.set(
            _firestore
                .collection(
                  'hotel_rooms',
                )
                .doc(roomId),
            <String, dynamic>{
              'manualStatus':
                  'available',
              'maintenanceTaskId':
                  '',
              'maintenanceReason':
                  '',
              'updatedAt':
                  FieldValue
                      .serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        await batch.commit();

        await _saveAudit(
          taskId: document.id,
          roomId: roomId,
          action: 'task_deleted',
          details:
              'Open maintenance task deleted.',
        );
      },
    );

    _showMessage(
      'Maintenance task deleted.',
    );
  }

  Future<void> _updateTask({
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
    required String action,
    required String details,
    required Map<String, dynamic>
        update,
  }) async {
    final String roomId =
        document.data()['roomId']
                ?.toString() ??
            '';

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
          taskId: document.id,
          roomId: roomId,
          action: action,
          details: details,
        );
      },
    );

    _showMessage(
      'Maintenance task updated.',
    );
  }

  Future<void> _saveAudit({
    required String taskId,
    required String roomId,
    required String action,
    required String details,
  }) async {
    await _auditCollection.add(
      <String, dynamic>{
        'hotelId': widget.hotelId,
        'taskId': taskId,
        'roomId': roomId,
        'action': action,
        'details': details,
        'performedByRole':
            'hotel_admin',
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _setWorking(
    String taskId,
    Future<void> Function() action,
  ) async {
    setState(() {
      _workingTaskId = taskId;
    });

    try {
      await action();
    } catch (error) {
      _showMessage(
        'Unable to update task: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _workingTaskId = '';
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
      builder: (
        BuildContext sheetContext,
      ) {
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
                    'hotelId',
                    isEqualTo:
                        widget.hotelId,
                  )
                  .where(
                    'taskId',
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
                            'Maintenance History',
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
                                'No maintenance history yet.',
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
                                final data =
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

  Widget _sheetField({
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

  Widget _storageBypassNotice() {
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
              'Before/after repair image fields are prepared, but Firebase Storage upload remains bypassed until billing is enabled. Maintenance records and room blocking continue to work through Firestore.',
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
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(
    String status,
  ) {
    switch (status) {
      case 'all':
        return 'All';
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'paused':
        return 'Paused';
      case 'awaiting_inspection':
        return 'Awaiting Inspection';
      case 'completed':
        return 'Completed';
      case 'closed':
        return 'Closed';
      default:
        return _capitalize(status);
    }
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'paused':
        return Colors.amber;
      case 'awaiting_inspection':
        return Colors.purple;
      case 'completed':
      case 'closed':
        return Colors.green;
      default:
        return yellow;
    }
  }

  Color _priorityColor(
    String priority,
  ) {
    switch (priority) {
      case 'urgent':
        return Colors.redAccent;
      case 'high':
        return Colors.orange;
      case 'low':
        return Colors.blueGrey;
      default:
        return yellow;
    }
  }

  int _priorityWeight(
    String priority,
  ) {
    switch (priority) {
      case 'urgent':
        return 4;
      case 'high':
        return 3;
      case 'normal':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  Color _categoryColor(
    String category,
  ) {
    switch (category) {
      case 'ac':
        return Colors.cyan;
      case 'plumbing':
        return Colors.blue;
      case 'electrical':
        return Colors.amber;
      case 'furniture':
        return Colors.brown;
      case 'bathroom':
        return Colors.teal;
      case 'safety':
        return Colors.redAccent;
      case 'internet':
        return Colors.indigo;
      case 'appliance':
        return Colors.deepPurple;
      default:
        return yellow;
    }
  }

  IconData _categoryIcon(
    String category,
  ) {
    switch (category) {
      case 'ac':
        return Icons.ac_unit;
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'furniture':
        return Icons.chair_outlined;
      case 'bathroom':
        return Icons.bathtub_outlined;
      case 'safety':
        return Icons.health_and_safety_outlined;
      case 'internet':
        return Icons.wifi;
      case 'appliance':
        return Icons.kitchen_outlined;
      default:
        return Icons.build_circle_outlined;
    }
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
      return DateTime.tryParse(
            value,
          ) ??
          DateTime
              .fromMillisecondsSinceEpoch(
            0,
          );
    }

    return DateTime
        .fromMillisecondsSinceEpoch(
      0,
    );
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

  String _formatDate(
    DateTime date,
  ) {
    if (date.millisecondsSinceEpoch ==
        0) {
      return 'Not set';
    }

    final String day =
        date.day
            .toString()
            .padLeft(2, '0');

    final String month =
        date.month
            .toString()
            .padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatDateTime(
    DateTime date,
  ) {
    if (date.millisecondsSinceEpoch ==
        0) {
      return '';
    }

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

  String _money(
    num amount,
  ) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(
            r'\B(?=(\d{3})+(?!\d))',
          ),
          (Match match) => ',',
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
