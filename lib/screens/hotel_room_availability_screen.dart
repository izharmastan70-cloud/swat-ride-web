import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/hotel_room.dart';
import '../models/hotel_room_availability.dart';
import '../services/hotel_room_availability_service.dart';
import '../services/tourism_service.dart';

class HotelRoomAvailabilityScreen
    extends StatefulWidget {
  const HotelRoomAvailabilityScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelRoomAvailabilityScreen>
      createState() =>
          _HotelRoomAvailabilityScreenState();
}

class _HotelRoomAvailabilityScreenState
    extends State<HotelRoomAvailabilityScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground =
      Color(0xFF0D0D0D);

  final TourismService _tourismService =
      TourismService();

  final HotelRoomAvailabilityService
      _availabilityService =
      HotelRoomAvailabilityService();

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
          'Room Availability',
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
                _openAvailabilityForm();
              },
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Date Rule',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<
            List<HotelRoomAvailability>>(
          stream: _availabilityService
              .hotelAvailabilityStream(
            widget.hotelId,
          ),
          builder: (
            context,
            AsyncSnapshot<
                    List<
                        HotelRoomAvailability>>
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
                icon: Icons.error_outline,
                title:
                    'Unable to Load Availability',
                message:
                    snapshot.error.toString(),
              );
            }

            final List<HotelRoomAvailability>
                rules = snapshot.data ??
                    <HotelRoomAvailability>[];

            if (rules.isEmpty) {
              return _messageState(
                icon:
                    Icons.event_available_outlined,
                title: 'No Date Rules',
                message:
                    'Add blocked dates or special pricing rules for hotel rooms.',
                buttonText: 'Add First Rule',
                onPressed: () {
                  _openAvailabilityForm();
                },
              );
            }

            return ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                100,
              ),
              children: [
                _buildInfoCard(),

                const SizedBox(height: 18),

                const Text(
                  'Availability Rules',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                ...rules.map(
                  (rule) =>
                      _availabilityCard(rule),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: yellow,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Block rooms for maintenance or apply special prices for weekends, holidays and seasons. Booking availability will use these date rules.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _availabilityCard(
    HotelRoomAvailability rule,
  ) {
    return FutureBuilder<HotelRoom?>(
      future: _tourismService
          .getHotelRoomById(
        rule.roomId,
      ),
      builder: (
        context,
        AsyncSnapshot<HotelRoom?> snapshot,
      ) {
        final String roomName =
            snapshot.data?.name ??
                'Hotel Room';

        return Container(
          margin:
              const EdgeInsets.only(
            bottom: 12,
          ),
          padding:
              const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius:
                BorderRadius.circular(17),
            border: Border.all(
              color: rule.isBlocked
                  ? Colors.red.withValues(
                      alpha: 0.35,
                    )
                  : yellow.withValues(
                      alpha: 0.25,
                    ),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    rule.isBlocked
                        ? Icons.block
                        : Icons.price_change_outlined,
                    color: rule.isBlocked
                        ? Colors.red
                        : yellow,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      roomName,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: darkCard,
                    onSelected: (value) {
                      if (value ==
                          'delete') {
                        _confirmDelete(rule);
                      }
                    },
                    itemBuilder:
                        (context) =>
                            const [
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .delete_outline,
                              color:
                                  Colors.red,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              'Delete Rule',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _detailRow(
                'From',
                _formatDate(
                  rule.startDate,
                ),
              ),

              _detailRow(
                'Until',
                _formatDate(
                  rule.endDate,
                ),
              ),

              _detailRow(
                'Reason',
                _reasonLabel(
                  rule.reason,
                ),
              ),

              _detailRow(
                'Status',
                rule.isBlocked
                    ? 'Blocked'
                    : 'Available',
              ),

              if (rule.priceOverride !=
                  null)
                _detailRow(
                  'Special Price',
                  'Rs. ${rule.priceOverride!.toStringAsFixed(0)} / night',
                ),
            ],
          ),
        );
      },
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
              const SizedBox(
                height: 14,
              ),
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
              const SizedBox(
                height: 8,
              ),
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
                    Icons.add,
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

  Future<void> _openAvailabilityForm()
      async {
    final List<HotelRoom> rooms =
        await _tourismService
            .getHotelRooms(
      widget.hotelId,
    );

    if (!mounted) {
      return;
    }

    if (rooms.isEmpty) {
      _showMessage(
        'Add at least one hotel room first.',
        isError: true,
      );
      return;
    }

    String selectedRoomId =
        rooms.first.id;

    DateTime startDate =
        DateTime.now();

    DateTime endDate =
        DateTime.now().add(
      const Duration(days: 1),
    );

    bool isBlocked = true;

    String reason =
        'owner_block';

    final TextEditingController
        priceController =
        TextEditingController();

    const List<String> reasons =
        <String>[
      'owner_block',
      'maintenance',
      'renovation',
      'weekend',
      'holiday',
      'seasonal',
    ];

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
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      const Text(
                        'Add Availability Rule',
                        style:
                            TextStyle(
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

                      _sheetDropdown(
                        value:
                            selectedRoomId,
                        items: rooms
                            .map(
                              (room) =>
                                  DropdownMenuItem<
                                      String>(
                                value:
                                    room.id,
                                child: Text(
                                  room.name,
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
                              selectedRoomId =
                                  value;
                            },
                          );
                        },
                      ),

                      _dateTile(
                        title:
                            'Start Date',
                        value:
                            _formatDate(
                          startDate,
                        ),
                        onTap:
                            () async {
                          final DateTime?
                              picked =
                              await showDatePicker(
                            context:
                                context,
                            initialDate:
                                startDate,
                            firstDate:
                                DateTime
                                    .now(),
                            lastDate:
                                DateTime
                                    .now()
                                    .add(
                              const Duration(
                                days: 730,
                              ),
                            ),
                          );

                          if (picked ==
                              null) {
                            return;
                          }

                          setSheetState(
                            () {
                              startDate =
                                  picked;

                              if (!endDate
                                  .isAfter(
                                startDate,
                              )) {
                                endDate =
                                    startDate
                                        .add(
                                  const Duration(
                                    days:
                                        1,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      _dateTile(
                        title:
                            'End Date',
                        value:
                            _formatDate(
                          endDate,
                        ),
                        onTap:
                            () async {
                          final DateTime?
                              picked =
                              await showDatePicker(
                            context:
                                context,
                            initialDate:
                                endDate,
                            firstDate:
                                startDate.add(
                              const Duration(
                                days: 1,
                              ),
                            ),
                            lastDate:
                                DateTime
                                    .now()
                                    .add(
                              const Duration(
                                days: 730,
                              ),
                            ),
                          );

                          if (picked ==
                              null) {
                            return;
                          }

                          setSheetState(
                            () {
                              endDate =
                                  picked;
                            },
                          );
                        },
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _sheetDropdown(
                        value: reason,
                        items: reasons
                            .map(
                              (value) =>
                                  DropdownMenuItem<
                                      String>(
                                value:
                                    value,
                                child: Text(
                                  _reasonLabel(
                                    value,
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
                              reason =
                                  value;
                            },
                          );
                        },
                      ),

                      SwitchListTile(
                        value:
                            isBlocked,
                        onChanged:
                            (value) {
                          setSheetState(
                            () {
                              isBlocked =
                                  value;
                            },
                          );
                        },
                        activeThumbColor:
                            yellow,
                        contentPadding:
                            EdgeInsets.zero,
                        title:
                            const Text(
                          'Block Room',
                        ),
                        subtitle:
                            const Text(
                          'Turn off to keep the room available and only apply special pricing.',
                          style:
                              TextStyle(
                            color:
                                Colors.grey,
                            fontSize:
                                11,
                          ),
                        ),
                      ),

                      TextField(
                        controller:
                            priceController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal:
                              true,
                        ),
                        decoration:
                            InputDecoration(
                          labelText:
                              'Special price per night (optional)',
                          prefixIcon:
                              const Icon(
                            Icons
                                .payments_outlined,
                            color:
                                yellow,
                          ),
                          filled:
                              true,
                          fillColor:
                              darkCard,
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                            borderSide:
                                BorderSide
                                    .none,
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
                            final User? user =
                                FirebaseAuth
                                    .instance
                                    .currentUser;

                            if (user ==
                                null) {
                              Navigator.pop(
                                sheetContext,
                              );

                              _showMessage(
                                'Please log in first.',
                                isError:
                                    true,
                              );
                              return;
                            }

                            final double?
                                price =
                                priceController
                                        .text
                                        .trim()
                                        .isEmpty
                                    ? null
                                    : double.tryParse(
                                        priceController
                                            .text
                                            .trim(),
                                      );

                            final HotelRoomAvailability
                                availability =
                                HotelRoomAvailability(
                              id: '',
                              hotelId:
                                  widget
                                      .hotelId,
                              roomId:
                                  selectedRoomId,
                              startDate:
                                  startDate,
                              endDate:
                                  endDate,
                              isBlocked:
                                  isBlocked,
                              reason:
                                  reason,
                              priceOverride:
                                  price,
                              createdByUserId:
                                  user.uid,
                              createdAt:
                                  null,
                              updatedAt:
                                  null,
                            );

                            Navigator.pop(
                              sheetContext,
                            );

                            await _saveAvailability(
                              availability,
                            );
                          },
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                yellow,
                            foregroundColor:
                                Colors
                                    .black,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical:
                                  15,
                            ),
                          ),
                          icon:
                              const Icon(
                            Icons.save,
                          ),
                          label:
                              const Text(
                            'Save Rule',
                            style:
                                TextStyle(
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
            );
          },
        );
      },
    );

    priceController.dispose();
  }

  Widget _sheetDropdown({
    required String value,
    required List<
            DropdownMenuItem<String>>
        items,
    required ValueChanged<String?>
        onChanged,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child:
          DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: darkCard,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dateTile({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(14),
      child: Container(
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month,
              color: yellow,
            ),
            const SizedBox(width: 12),
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
                      color:
                          Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    value,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons
                  .keyboard_arrow_right,
              color: yellow,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAvailability(
    HotelRoomAvailability availability,
  ) async {
    setState(() {
      _isWorking = true;
    });

    try {
      await _availabilityService
          .createAvailability(
        availability,
      );

      _showMessage(
        'Availability rule saved successfully.',
      );
    } catch (error) {
      _showMessage(
        'Unable to save rule: $error',
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

  Future<void> _confirmDelete(
    HotelRoomAvailability rule,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Delete Date Rule',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: const Text(
            'Delete this room availability rule?',
            style: TextStyle(
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
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Delete',
              ),
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
      await _availabilityService
          .deleteAvailability(
        rule.id,
      );

      _showMessage(
        'Availability rule deleted.',
      );
    } catch (error) {
      _showMessage(
        'Unable to delete rule: $error',
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

  String _formatDate(
    DateTime date,
  ) {
    final String day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final String month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    return '$day/$month/${date.year}';
  }

  String _reasonLabel(
    String reason,
  ) {
    switch (reason) {
      case 'maintenance':
        return 'Maintenance';
      case 'renovation':
        return 'Renovation';
      case 'weekend':
        return 'Weekend Price';
      case 'holiday':
        return 'Holiday Price';
      case 'seasonal':
        return 'Seasonal Price';
      default:
        return 'Owner Block';
    }
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
