import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/hotel_agent.dart';
import '../services/hotel_agent_management_service.dart';

class HotelAgentManagementScreen
    extends StatefulWidget {
  const HotelAgentManagementScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelAgentManagementScreen>
      createState() =>
          _HotelAgentManagementScreenState();
}

class _HotelAgentManagementScreenState
    extends State<HotelAgentManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground =
      Color(0xFF0D0D0D);

  final HotelAgentManagementService
      _service =
      HotelAgentManagementService();

  bool _isWorking = false;

  final List<String> _roles =
      const <String>[
    'manager',
    'receptionist',
    'bookingAgent',
  ];

  final Map<String, String>
      _permissionLabels =
      const <String, String>{
    'manageBookings':
        'Manage Bookings',
    'manageRooms':
        'Manage Rooms',
    'managePrices':
        'Manage Prices',
    'chatWithGuests':
        'Chat with Guests',
    'callGuests':
        'Call Guests',
    'manageCheckInOut':
        'Check-in / Check-out',
  };

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final User? user = _currentUser;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Hotel Agents',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: user == null ||
                _isWorking
            ? null
            : () {
                _openAgentForm(
                  ownerUserId: user.uid,
                );
              },
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add),
        label: const Text(
          'Add Agent',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: user == null
            ? _messageState(
                icon: Icons.lock_outline,
                title: 'Login Required',
                message:
                    'Please log in to manage hotel agents.',
              )
            : StreamBuilder<List<HotelAgent>>(
                stream: _service
                    .hotelAgentsStream(
                  widget.hotelId,
                ),
                builder: (
                  context,
                  AsyncSnapshot<
                          List<HotelAgent>>
                      snapshot,
                ) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(
                        color: yellow,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _messageState(
                      icon:
                          Icons.error_outline,
                      title:
                          'Unable to Load Agents',
                      message:
                          snapshot.error
                              .toString(),
                    );
                  }

                  final List<HotelAgent>
                      agents =
                      snapshot.data ??
                          <HotelAgent>[];

                  if (agents.isEmpty) {
                    return _messageState(
                      icon:
                          Icons.people_outline,
                      title:
                          'No Hotel Agents',
                      message:
                          'Add a manager, receptionist or booking agent. Every agent must be approved by SWAT RIDE admin before access is enabled.',
                      buttonText:
                          'Add First Agent',
                      onPressed: () {
                        _openAgentForm(
                          ownerUserId:
                              user.uid,
                        );
                      },
                    );
                  }

                  return ListView(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      16,
                      16,
                      16,
                      100,
                    ),
                    children: [
                      _summaryCard(agents),
                      const SizedBox(
                        height: 16,
                      ),
                      _adminControlNotice(),
                      const SizedBox(
                        height: 18,
                      ),
                      const Text(
                        'Hotel Staff',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      ...agents.map(
                        (agent) =>
                            _agentCard(
                          agent: agent,
                          ownerUserId:
                              user.uid,
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _summaryCard(
    List<HotelAgent> agents,
  ) {
    final int approved = agents
        .where(
          (agent) =>
              agent.isApprovedByAdmin,
        )
        .length;

    final int active = agents
        .where(
          (agent) =>
              agent.canAccessHotelPanel,
        )
        .length;

    final int pending =
        agents.length - approved;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              title: 'Total',
              value: '${agents.length}',
              icon: Icons.groups_outlined,
            ),
          ),
          Expanded(
            child: _summaryItem(
              title: 'Active',
              value: '$active',
              icon:
                  Icons.verified_user_outlined,
            ),
          ),
          Expanded(
            child: _summaryItem(
              title: 'Pending',
              value: '$pending',
              icon: Icons.schedule,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: yellow,
          size: 24,
        ),
        const SizedBox(height: 6),
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
    );
  }

  Widget _adminControlNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.admin_panel_settings_outlined,
            color: yellow,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hotel owner can submit, edit or cancel pending agent requests. SWAT RIDE admin controls final approval and agent ON/OFF access. Disabling an agent never disables the hotel.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _agentCard({
    required HotelAgent agent,
    required String ownerUserId,
  }) {
    final String status =
        _agentStatus(agent);

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
            alpha: 0.35,
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: yellow.withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: yellow,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      agent.fullName,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      _roleLabel(
                        agent.role,
                      ),
                      style:
                          const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 14),
          _detailRow(
            'Phone',
            agent.phoneNumber,
          ),
          if (agent.email
              .trim()
              .isNotEmpty)
            _detailRow(
              'Email',
              agent.email,
            ),
          _detailRow(
            'Admin Approval',
            agent.isApprovedByAdmin
                ? 'Approved'
                : 'Pending',
          ),
          _detailRow(
            'Panel Access',
            agent.canAccessHotelPanel
                ? 'Active'
                : 'Off',
          ),
          const SizedBox(height: 10),
          const Text(
            'Permissions',
            style: TextStyle(
              color: yellow,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                agent.permissions.map(
              (permission) {
                return Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withValues(
                      alpha: 0.05,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(18),
                  ),
                  child: Text(
                    _permissionLabels[
                            permission] ??
                        permission,
                    style:
                        const TextStyle(
                      color: Colors.grey,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ).toList(),
          ),
          if (agent
              .deactivationReason
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Admin note: ${agent.deactivationReason}',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (!agent.isApprovedByAdmin)
            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed: _isWorking
                        ? null
                        : () {
                            _openAgentForm(
                              ownerUserId:
                                  ownerUserId,
                              existingAgent:
                                  agent,
                            );
                          },
                    icon: const Icon(
                      Icons.edit_outlined,
                    ),
                    label:
                        const Text('Edit'),
                    style:
                        OutlinedButton
                            .styleFrom(
                      foregroundColor:
                          yellow,
                      side:
                          const BorderSide(
                        color: yellow,
                      ),
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
                            _confirmCancelRequest(
                              agent:
                                  agent,
                              ownerUserId:
                                  ownerUserId,
                            );
                          },
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                    label:
                        const Text('Remove'),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          Colors.red,
                      foregroundColor:
                          Colors.white,
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isWorking
                    ? null
                    : () {
                        _requestDeactivation(
                          agent:
                              agent,
                          ownerUserId:
                              ownerUserId,
                        );
                      },
                icon: const Icon(
                  Icons.power_settings_new,
                ),
                label: const Text(
                  'Request Agent Deactivation',
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.orange,
                  side: const BorderSide(
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
        ],
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
        bottom: 7,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.bold,
                fontSize: 12,
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
          alpha: 0.15,
        ),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
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
              if (buttonText != null &&
                  onPressed != null) ...[
                const SizedBox(
                  height: 16,
                ),
                ElevatedButton.icon(
                  onPressed:
                      onPressed,
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        yellow,
                    foregroundColor:
                        Colors.black,
                  ),
                  icon:
                      const Icon(
                    Icons.person_add,
                  ),
                  label: Text(
                    buttonText,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAgentForm({
    required String ownerUserId,
    HotelAgent? existingAgent,
  }) async {
    final GlobalKey<FormState>
        formKey =
        GlobalKey<FormState>();

    final TextEditingController
        nameController =
        TextEditingController(
      text:
          existingAgent?.fullName ??
              '',
    );

    final TextEditingController
        phoneController =
        TextEditingController(
      text:
          existingAgent?.phoneNumber ??
              '',
    );

    final TextEditingController
        emailController =
        TextEditingController(
      text:
          existingAgent?.email ??
              '',
    );

    final TextEditingController
        userIdController =
        TextEditingController(
      text:
          existingAgent?.userId ??
              '',
    );

    String selectedRole =
        existingAgent?.role ??
            'receptionist';

    final List<String>
        selectedPermissions =
        List<String>.from(
      existingAgent?.permissions ??
          <String>[
            'manageBookings',
            'chatWithGuests',
            'callGuests',
          ],
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          darkBackground,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            return SafeArea(
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  MediaQuery.of(context)
                          .viewInsets
                          .bottom +
                      20,
                ),
                child:
                    SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          existingAgent ==
                                  null
                              ? 'Add Hotel Agent'
                              : 'Edit Agent Request',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 21,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        _formField(
                          controller:
                              nameController,
                          label:
                              'Full name',
                          icon:
                              Icons.person,
                          validator:
                              _requiredValidator,
                        ),
                        _formField(
                          controller:
                              phoneController,
                          label:
                              'Phone number',
                          icon:
                              Icons.phone,
                          keyboardType:
                              TextInputType
                                  .phone,
                          validator:
                              _phoneValidator,
                        ),
                        _formField(
                          controller:
                              emailController,
                          label:
                              'Email (optional)',
                          icon:
                              Icons.email,
                          keyboardType:
                              TextInputType
                                  .emailAddress,
                          validator:
                              _optionalEmailValidator,
                        ),
                        _formField(
                          controller:
                              userIdController,
                          label:
                              'Agent user ID (optional)',
                          icon:
                              Icons.fingerprint,
                          hint:
                              'Admin can link the account later',
                        ),
                        Container(
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 12,
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                14,
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
                          child:
                              DropdownButtonHideUnderline(
                            child:
                                DropdownButton<
                                    String>(
                              value:
                                  selectedRole,
                              isExpanded:
                                  true,
                              dropdownColor:
                                  darkCard,
                              items: _roles
                                  .map(
                                    (role) =>
                                        DropdownMenuItem<
                                            String>(
                                      value:
                                          role,
                                      child:
                                          Text(
                                        _roleLabel(
                                          role,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged:
                                  (value) {
                                if (value ==
                                    null) {
                                  return;
                                }

                                setSheetState(
                                  () {
                                    selectedRole =
                                        value;
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        const Text(
                          'Permissions',
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _permissionLabels
                                  .entries
                                  .map(
                            (entry) {
                              final bool
                                  selected =
                                  selectedPermissions
                                      .contains(
                                entry.key,
                              );

                              return FilterChip(
                                selected:
                                    selected,
                                label:
                                    Text(
                                  entry.value,
                                ),
                                selectedColor:
                                    yellow
                                        .withValues(
                                  alpha:
                                      0.25,
                                ),
                                checkmarkColor:
                                    yellow,
                                onSelected:
                                    (value) {
                                  setSheetState(
                                    () {
                                      if (value) {
                                        if (!selectedPermissions
                                            .contains(
                                          entry.key,
                                        )) {
                                          selectedPermissions
                                              .add(
                                            entry.key,
                                          );
                                        }
                                      } else {
                                        selectedPermissions
                                            .remove(
                                          entry.key,
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          ).toList(),
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        Container(
                          padding:
                              const EdgeInsets
                                  .all(12),
                          decoration:
                              BoxDecoration(
                            color: yellow
                                .withValues(
                              alpha:
                                  0.08,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                          child:
                              const Text(
                            'The agent will remain OFF until SWAT RIDE admin approves the request. Admin can later change permissions or disable only this agent.',
                            style:
                                TextStyle(
                              color:
                                  Colors.grey,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 18,
                        ),
                        SizedBox(
                          width:
                              double.infinity,
                          child:
                              ElevatedButton.icon(
                            onPressed:
                                () async {
                              final bool
                                  valid =
                                  formKey
                                          .currentState
                                          ?.validate() ??
                                      false;

                              if (!valid) {
                                return;
                              }

                              if (selectedPermissions
                                  .isEmpty) {
                                _showMessage(
                                  'Select at least one permission.',
                                  isError:
                                      true,
                                );
                                return;
                              }

                              final HotelAgent
                                  agent =
                                  HotelAgent(
                                id:
                                    existingAgent
                                            ?.id ??
                                        '',
                                hotelId:
                                    widget
                                        .hotelId,
                                userId:
                                    userIdController
                                        .text
                                        .trim(),
                                fullName:
                                    nameController
                                        .text
                                        .trim(),
                                phoneNumber:
                                    phoneController
                                        .text
                                        .trim(),
                                email:
                                    emailController
                                        .text
                                        .trim(),
                                role:
                                    selectedRole,
                                permissions:
                                    List<String>.from(
                                  selectedPermissions,
                                ),
                                isActive:
                                    false,
                                isApprovedByAdmin:
                                    false,
                                createdAt:
                                    existingAgent
                                        ?.createdAt,
                                updatedAt:
                                    null,
                              );

                              Navigator.pop(
                                sheetContext,
                              );

                              await _saveAgent(
                                agent:
                                    agent,
                                ownerUserId:
                                    ownerUserId,
                                isEdit:
                                    existingAgent !=
                                        null,
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
                                vertical:
                                    15,
                              ),
                            ),
                            icon: Icon(
                              existingAgent ==
                                      null
                                  ? Icons
                                      .send_outlined
                                  : Icons
                                      .save_outlined,
                            ),
                            label: Text(
                              existingAgent ==
                                      null
                                  ? 'Submit Agent Request'
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
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    userIdController.dispose();
  }

  Widget _formField({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType:
            keyboardType,
        validator: validator,
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration:
            InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: yellow,
          ),
          filled: true,
          fillColor: darkCard,
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            borderSide:
                BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _saveAgent({
    required HotelAgent agent,
    required String ownerUserId,
    required bool isEdit,
  }) async {
    setState(() {
      _isWorking = true;
    });

    try {
      if (isEdit) {
        await _service
            .updatePendingAgent(
          agent: agent,
          requestedByOwnerId:
              ownerUserId,
        );
      } else {
        await _service
            .submitAgentRequest(
          agent: agent,
          requestedByOwnerId:
              ownerUserId,
        );
      }

      _showMessage(
        isEdit
            ? 'Agent request updated.'
            : 'Agent request submitted for admin approval.',
      );
    } catch (error) {
      _showMessage(
        error.toString(),
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

  Future<void>
      _confirmCancelRequest({
    required HotelAgent agent,
    required String ownerUserId,
  }) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Remove Agent Request',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: Text(
            'Remove ${agent.fullName} from the pending agent requests?',
            style: const TextStyle(
              color: Colors.grey,
              height: 1.4,
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
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Remove'),
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
      await _service
          .cancelPendingRequest(
        agentId: agent.id,
        requestedByOwnerId:
            ownerUserId,
      );

      _showMessage(
        'Agent request removed.',
      );
    } catch (error) {
      _showMessage(
        error.toString(),
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

  Future<void>
      _requestDeactivation({
    required HotelAgent agent,
    required String ownerUserId,
  }) async {
    final TextEditingController
        reasonController =
        TextEditingController();

    final String? reason =
        await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Deactivate Agent',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: TextField(
            controller:
                reasonController,
            maxLines: 3,
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration:
                const InputDecoration(
              hintText:
                  'Enter reason for deactivation',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  reasonController
                      .text
                      .trim(),
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.orange,
                foregroundColor:
                    Colors.black,
              ),
              child:
                  const Text('Submit'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null ||
        reason.trim().isEmpty) {
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      await _service
          .requestAgentDeactivation(
        agentId: agent.id,
        requestedByOwnerId:
            ownerUserId,
        reason: reason,
      );

      _showMessage(
        'Agent deactivation request sent to admin.',
      );
    } catch (error) {
      _showMessage(
        error.toString(),
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

  String _agentStatus(
    HotelAgent agent,
  ) {
    if (!agent.isApprovedByAdmin) {
      return 'pending';
    }

    if (agent.isActive) {
      return 'active';
    }

    return 'disabled';
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'disabled':
        return Colors.red;
      default:
        return yellow;
    }
  }

  String _statusLabel(
    String status,
  ) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'disabled':
        return 'Disabled';
      default:
        return 'Admin Pending';
    }
  }

  String _roleLabel(
    String role,
  ) {
    switch (role) {
      case 'manager':
        return 'Manager';
      case 'receptionist':
        return 'Receptionist';
      case 'bookingAgent':
        return 'Booking Agent';
      default:
        return role;
    }
  }

  String? _requiredValidator(
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
    final String clean =
        value?.replaceAll(
              RegExp(r'\D'),
              '',
            ) ??
            '';

    if (clean.length < 10 ||
        clean.length > 13) {
      return 'Enter a valid phone number.';
    }

    return null;
  }

  String? _optionalEmailValidator(
    String? value,
  ) {
    final String email =
        value?.trim() ?? '';

    if (email.isEmpty) {
      return null;
    }

    if (!email.contains('@') ||
        !email.contains('.')) {
      return 'Enter a valid email.';
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
              isError
                  ? Colors.red
                  : darkCard,
        ),
      );
  }
}
