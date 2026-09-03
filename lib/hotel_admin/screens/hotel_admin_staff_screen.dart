import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HotelAdminStaffScreen extends StatefulWidget {
  const HotelAdminStaffScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelAdminStaffScreen> createState() =>
      _HotelAdminStaffScreenState();
}

class _HotelAdminStaffScreenState
    extends State<HotelAdminStaffScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedFilter = 'all';
  String _searchText = '';
  bool _isWorking = false;

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
          'Hotel Staff Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _isWorking
            ? null
            : () {
                _openStaffForm();
              },
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        icon: const Icon(
          Icons.person_add_alt_1,
        ),
        label: const Text(
          'Add Staff',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('hotel_staff')
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
                    'Unable to Load Staff',
                message:
                    snapshot.error.toString(),
              );
            }

            final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>
                staff =
                snapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            staff.sort(
              (a, b) {
                final String aName =
                    a.data()['fullName']
                            ?.toString() ??
                        '';

                final String bName =
                    b.data()['fullName']
                            ?.toString() ??
                        '';

                return aName.compareTo(
                  bName,
                );
              },
            );

            final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>
                filtered =
                _filterStaff(staff);

            return RefreshIndicator(
              color: yellow,
              backgroundColor: darkCard,
              onRefresh: () async {
                await _firestore
                    .collection(
                      'hotel_staff',
                    )
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
                  100,
                ),
                children: [
                  _summaryCard(staff),
                  const SizedBox(height: 16),
                  _searchBox(),
                  const SizedBox(height: 12),
                  _filterChips(),
                  const SizedBox(height: 18),
                  if (filtered.isEmpty)
                    _messageState(
                      icon:
                          Icons.groups_outlined,
                      title:
                          'No Staff Found',
                      message:
                          'Add hotel staff or change the selected filter.',
                    )
                  else
                    ...filtered.map(
                      _staffCard,
                    ),
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
        staff,
  ) {
    int managers = 0;
    int reception = 0;
    int housekeeping = 0;
    int inactive = 0;

    for (final member in staff) {
      final Map<String, dynamic> data =
          member.data();

      final bool isActive =
          data['isActive'] != false;

      if (!isActive) {
        inactive++;
        continue;
      }

      switch (
          data['role']?.toString() ??
              'reception') {
        case 'manager':
          managers++;
          break;
        case 'housekeeping':
          housekeeping++;
          break;
        default:
          reception++;
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.65,
      children: [
        _summaryTile(
          title: 'Managers',
          value: '$managers',
          icon:
              Icons.manage_accounts_outlined,
          color: Colors.purple,
        ),
        _summaryTile(
          title: 'Reception',
          value: '$reception',
          icon:
              Icons.support_agent_outlined,
          color: Colors.blue,
        ),
        _summaryTile(
          title: 'Housekeeping',
          value: '$housekeeping',
          icon: Icons
              .cleaning_services_outlined,
          color: Colors.green,
        ),
        _summaryTile(
          title: 'Inactive',
          value: '$inactive',
          icon:
              Icons.person_off_outlined,
          color: Colors.redAccent,
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
              fontWeight:
                  FontWeight.bold,
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

  Widget _searchBox() {
    return TextField(
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
            'Search name, phone, CNIC or role...',
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
              BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _filterChips() {
    const List<String> filters =
        <String>[
      'all',
      'manager',
      'reception',
      'housekeeping',
      'inactive',
    ];

    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,
      child: Row(
        children: filters.map(
          (String filter) {
            final bool selected =
                _selectedFilter ==
                    filter;

            return Padding(
              padding:
                  const EdgeInsets.only(
                right: 8,
              ),
              child: ChoiceChip(
                selected: selected,
                label: Text(
                  _label(filter),
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

  Widget _staffCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        member,
  ) {
    final Map<String, dynamic> data =
        member.data();

    final String fullName =
        data['fullName']?.toString() ??
            'Staff Member';

    final String role =
        data['role']?.toString() ??
            'reception';

    final String phone =
        data['phone']?.toString() ??
            '';

    final String cnic =
        data['cnic']?.toString() ??
            '';

    final String shiftStart =
        data['shiftStart']?.toString() ??
            '09:00';

    final String shiftEnd =
        data['shiftEnd']?.toString() ??
            '17:00';

    final bool isActive =
        data['isActive'] != false;

    final List<String> permissions =
        _readStringList(
      data['permissions'],
    );

    final Color roleColor =
        _roleColor(role);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? roleColor.withValues(
                  alpha: 0.28,
                )
              : Colors.redAccent
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
                  color: roleColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  _roleIcon(role),
                  color: roleColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _label(role),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _activeBadge(isActive),
            ],
          ),
          const SizedBox(height: 13),
          if (phone.isNotEmpty)
            _detailRow(
              'Phone',
              phone,
            ),
          if (cnic.isNotEmpty)
            _detailRow(
              'CNIC',
              cnic,
            ),
          _detailRow(
            'Shift',
            '$shiftStart - $shiftEnd',
          ),
          _detailRow(
            'Permissions',
            permissions.isEmpty
                ? 'Role defaults'
                : permissions.join(', '),
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
                          _openStaffForm(
                            member: member,
                          );
                        },
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label:
                      const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: _isWorking
                      ? null
                      : () {
                          _toggleActive(
                            member,
                            !isActive,
                          );
                        },
                  icon: Icon(
                    isActive
                        ? Icons
                            .person_off_outlined
                        : Icons
                            .person_add_alt_outlined,
                  ),
                  label: Text(
                    isActive
                        ? 'Deactivate'
                        : 'Activate',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        isActive
                            ? Colors.redAccent
                            : Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openStaffForm({
    QueryDocumentSnapshot<
            Map<String, dynamic>>?
        member,
  }) async {
    final Map<String, dynamic> data =
        member?.data() ??
            <String, dynamic>{};

    final TextEditingController
        nameController =
        TextEditingController(
      text:
          data['fullName']?.toString() ??
              '',
    );

    final TextEditingController
        phoneController =
        TextEditingController(
      text:
          data['phone']?.toString() ??
              '',
    );

    final TextEditingController
        cnicController =
        TextEditingController(
      text:
          data['cnic']?.toString() ??
              '',
    );

    final TextEditingController
        shiftStartController =
        TextEditingController(
      text:
          data['shiftStart']?.toString() ??
              '09:00',
    );

    final TextEditingController
        shiftEndController =
        TextEditingController(
      text:
          data['shiftEnd']?.toString() ??
              '17:00',
    );

    String role =
        data['role']?.toString() ??
            'reception';

    final Set<String> permissions =
        _readStringList(
      data['permissions'],
    ).toSet();

    final GlobalKey<FormState> formKey =
        GlobalKey<FormState>();

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
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        member == null
                            ? 'Add Hotel Staff'
                            : 'Edit Hotel Staff',
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      _formField(
                        controller:
                            nameController,
                        label: 'Full Name',
                        icon:
                            Icons.person_outline,
                        validator: _required,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      _formField(
                        controller:
                            phoneController,
                        label: 'Phone Number',
                        icon:
                            Icons.phone_outlined,
                        keyboardType:
                            TextInputType.phone,
                        validator:
                            _phoneValidator,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      _formField(
                        controller:
                            cnicController,
                        label: 'CNIC Number',
                        icon:
                            Icons.badge_outlined,
                        keyboardType:
                            TextInputType.number,
                        validator: _required,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      DropdownButtonFormField<
                          String>(
                        initialValue: role,
                        dropdownColor: darkCard,
                        decoration:
                            const InputDecoration(
                          labelText: 'Role',
                        ),
                        items:
                            const <String>[
                          'manager',
                          'reception',
                          'housekeeping',
                        ]
                                .map(
                                  (value) =>
                                      DropdownMenuItem<
                                          String>(
                                    value: value,
                                    child: Text(
                                      _label(
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
                            role = value;
                            permissions
                              ..clear()
                              ..addAll(
                                _defaultPermissions(
                                  value,
                                ),
                              );
                          });
                        },
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _formField(
                              controller:
                                  shiftStartController,
                              label:
                                  'Shift Start',
                              icon: Icons
                                  .schedule_outlined,
                              validator:
                                  _required,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: _formField(
                              controller:
                                  shiftEndController,
                              label:
                                  'Shift End',
                              icon: Icons
                                  .schedule_outlined,
                              validator:
                                  _required,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Text(
                        'Permissions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      ..._allPermissions.map(
                        (permission) {
                          return CheckboxListTile(
                            value:
                                permissions.contains(
                              permission,
                            ),
                            onChanged: (value) {
                              setSheetState(() {
                                if (value == true) {
                                  permissions.add(
                                    permission,
                                  );
                                } else {
                                  permissions.remove(
                                    permission,
                                  );
                                }
                              });
                            },
                            activeColor: yellow,
                            checkColor:
                                Colors.black,
                            contentPadding:
                                EdgeInsets.zero,
                            title: Text(
                              _permissionLabel(
                                permission,
                              ),
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton.icon(
                          onPressed: () {
                            if (formKey
                                    .currentState
                                    ?.validate() ==
                                true) {
                              Navigator.pop(
                                context,
                                true,
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.save_outlined,
                          ),
                          label: const Text(
                            'Save Staff',
                          ),
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
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        'Staff app login credentials will be linked after the role-based authentication phase. This step saves the staff profile and permissions.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (save == true) {
      await _saveStaff(
        member: member,
        fullName:
            nameController.text.trim(),
        phone:
            phoneController.text.trim(),
        cnic:
            cnicController.text.trim(),
        role: role,
        shiftStart:
            shiftStartController.text
                .trim(),
        shiftEnd:
            shiftEndController.text
                .trim(),
        permissions:
            permissions.toList(),
      );
    }

    nameController.dispose();
    phoneController.dispose();
    cnicController.dispose();
    shiftStartController.dispose();
    shiftEndController.dispose();
  }

  Future<void> _saveStaff({
    required QueryDocumentSnapshot<
            Map<String, dynamic>>?
        member,
    required String fullName,
    required String phone,
    required String cnic,
    required String role,
    required String shiftStart,
    required String shiftEnd,
    required List<String> permissions,
  }) async {
    setState(() {
      _isWorking = true;
    });

    try {
      final DocumentReference<
              Map<String, dynamic>>
          reference = member?.reference ??
              _firestore
                  .collection(
                    'hotel_staff',
                  )
                  .doc();

      await reference.set(
        <String, dynamic>{
          'staffId': reference.id,
          'hotelId': widget.hotelId,
          'fullName': fullName,
          'phone': phone,
          'cnic': cnic,
          'role': role,
          'shiftStart': shiftStart,
          'shiftEnd': shiftEnd,
          'permissions': permissions,
          'isActive':
              member?.data()['isActive'] ??
                  true,
          'authUserId':
              member?.data()['authUserId'] ??
                  '',
          'createdAt':
              member?.data()['createdAt'] ??
                  FieldValue
                      .serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _showMessage(
        member == null
            ? 'Staff member added successfully.'
            : 'Staff member updated successfully.',
      );
    } catch (error) {
      _showMessage(
        'Unable to save staff member: $error',
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

  Future<void> _toggleActive(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        member,
    bool active,
  ) async {
    setState(() {
      _isWorking = true;
    });

    try {
      await member.reference.set(
        <String, dynamic>{
          'isActive': active,
          'updatedAt':
              FieldValue.serverTimestamp(),
          if (!active)
            'deactivatedAt':
                FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _showMessage(
        active
            ? 'Staff member activated.'
            : 'Staff member deactivated.',
      );
    } catch (error) {
      _showMessage(
        'Unable to update staff status: $error',
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

  List<QueryDocumentSnapshot<
          Map<String, dynamic>>>
      _filterStaff(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        staff,
  ) {
    final String search =
        _searchText.trim().toLowerCase();

    return staff.where(
      (member) {
        final Map<String, dynamic> data =
            member.data();

        final String fullName =
            data['fullName']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final String phone =
            data['phone']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final String cnic =
            data['cnic']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final String role =
            data['role']
                    ?.toString()
                    .toLowerCase() ??
                'reception';

        final bool isActive =
            data['isActive'] != false;

        final bool searchMatch =
            search.isEmpty ||
                fullName.contains(search) ||
                phone.contains(search) ||
                cnic.contains(search) ||
                role.contains(search);

        final bool filterMatch =
            _selectedFilter == 'all' ||
                (_selectedFilter ==
                        'inactive' &&
                    !isActive) ||
                (_selectedFilter !=
                        'inactive' &&
                    role ==
                        _selectedFilter &&
                    isActive);

        return searchMatch &&
            filterMatch;
      },
    ).toList();
  }

  Widget _formField({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.grey,
        ),
        prefixIcon: Icon(
          icon,
          color: yellow,
        ),
        filled: true,
        fillColor: darkBackground,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _activeBadge(
    bool active,
  ) {
    final Color color =
        active
            ? Colors.green
            : Colors.redAccent;

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
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight:
              FontWeight.bold,
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

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
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
                fontWeight:
                    FontWeight.bold,
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
      ),
    );
  }

  static const List<String>
      _allPermissions = <String>[
    'manage_bookings',
    'check_in_guest',
    'check_out_guest',
    'manage_rooms',
    'manage_housekeeping',
    'create_walk_in_booking',
    'view_payments',
    'manage_staff',
    'view_reports',
    'manage_settings',
  ];

  static List<String>
      _defaultPermissions(
    String role,
  ) {
    switch (role) {
      case 'manager':
        return List<String>.from(
          _allPermissions,
        );
      case 'housekeeping':
        return <String>[
          'manage_housekeeping',
        ];
      default:
        return <String>[
          'manage_bookings',
          'check_in_guest',
          'check_out_guest',
          'create_walk_in_booking',
          'view_payments',
        ];
    }
  }

  static String _permissionLabel(
    String permission,
  ) {
    switch (permission) {
      case 'manage_bookings':
        return 'Manage Bookings';
      case 'check_in_guest':
        return 'Check-in Guest';
      case 'check_out_guest':
        return 'Check-out Guest';
      case 'manage_rooms':
        return 'Manage Rooms';
      case 'manage_housekeeping':
        return 'Manage Housekeeping';
      case 'create_walk_in_booking':
        return 'Create Walk-in Booking';
      case 'view_payments':
        return 'View Payments';
      case 'manage_staff':
        return 'Manage Staff';
      case 'view_reports':
        return 'View Reports';
      case 'manage_settings':
        return 'Manage Settings';
      default:
        return permission;
    }
  }

  Color _roleColor(
    String role,
  ) {
    switch (role) {
      case 'manager':
        return Colors.purple;
      case 'housekeeping':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _roleIcon(
    String role,
  ) {
    switch (role) {
      case 'manager':
        return Icons
            .manage_accounts_outlined;
      case 'housekeeping':
        return Icons
            .cleaning_services_outlined;
      default:
        return Icons.support_agent_outlined;
    }
  }

  static String _label(
    String value,
  ) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() +
        value.substring(1);
  }

  List<String> _readStringList(
    dynamic value,
  ) {
    if (value is List) {
      return value
          .map(
            (item) => item.toString(),
          )
          .toList();
    }

    return <String>[];
  }

  String? _required(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  String? _phoneValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().length < 10) {
      return 'Enter a valid phone number.';
    }

    return null;
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
