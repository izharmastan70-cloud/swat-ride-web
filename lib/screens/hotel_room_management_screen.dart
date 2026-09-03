import 'package:flutter/material.dart';

import '../models/hotel_room.dart';
import '../services/tourism_service.dart';

class HotelRoomManagementScreen extends StatefulWidget {
  const HotelRoomManagementScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelRoomManagementScreen> createState() =>
      _HotelRoomManagementScreenState();
}

class _HotelRoomManagementScreenState
    extends State<HotelRoomManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final TourismService _tourismService =
      TourismService();

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
          'Room Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Room',
            onPressed: _isWorking
                ? null
                : () {
                    _openRoomForm();
                  },
            icon: const Icon(
              Icons.add_circle_outline,
              color: yellow,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isWorking
            ? null
            : () {
                _openRoomForm();
              },
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Room',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<HotelRoom>>(
          stream: _tourismService.hotelRoomsStream(
            widget.hotelId,
          ),
          builder: (
            context,
            AsyncSnapshot<List<HotelRoom>> snapshot,
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
                title: 'Unable to Load Rooms',
                message: snapshot.error.toString(),
              );
            }

            final List<HotelRoom> rooms =
                snapshot.data ?? <HotelRoom>[];

            if (rooms.isEmpty) {
              return _messageState(
                icon: Icons.meeting_room_outlined,
                title: 'No Rooms Added',
                message:
                    'Add your first hotel room to start managing prices and availability.',
                buttonText: 'Add First Room',
                onPressed: () {
                  _openRoomForm();
                },
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                100,
              ),
              children: [
                _summaryCard(rooms),

                const SizedBox(height: 18),

                const Text(
                  'Hotel Rooms',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                ...rooms.map(
                  (room) => _roomCard(room),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard(
    List<HotelRoom> rooms,
  ) {
    final int available = rooms
        .where(
          (room) => room.isAvailable,
        )
        .length;

    final int unavailable =
        rooms.length - available;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              title: 'Total',
              value: '${rooms.length}',
              icon: Icons.meeting_room_outlined,
            ),
          ),
          Expanded(
            child: _summaryItem(
              title: 'Available',
              value: '$available',
              icon: Icons.check_circle_outline,
            ),
          ),
          Expanded(
            child: _summaryItem(
              title: 'Unavailable',
              value: '$unavailable',
              icon: Icons.block_outlined,
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

  Widget _roomCard(
    HotelRoom room,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: room.isAvailable
              ? Colors.white.withValues(
                  alpha: 0.05,
                )
              : Colors.red.withValues(
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
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bed_outlined,
                  color: yellow,
                  size: 27,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.roomType,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                color: darkCard,
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _openRoomForm(
                      room: room,
                    );
                  } else if (value == 'delete') {
                    _confirmDelete(room);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: yellow,
                        ),
                        SizedBox(width: 8),
                        Text('Edit Room'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text('Delete Room'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(
                icon: Icons.people_outline,
                text: '${room.maxGuests} guests',
              ),
              _infoChip(
                icon: Icons.bed,
                text: '${room.beds} beds',
              ),
              _infoChip(
                icon: Icons.payments_outlined,
                text:
                    'Rs. ${room.pricePerNight.toStringAsFixed(0)} / night',
              ),
            ],
          ),

          if (room.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              room.description,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],

          if (room.facilities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: room.facilities
                  .map(
                    (facility) => Chip(
                      label: Text(
                        facility,
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                      ),
                      backgroundColor:
                          Colors.white.withValues(
                        alpha: 0.05,
                      ),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 10),

          SwitchListTile(
            value: room.isAvailable,
            onChanged: _isWorking
                ? null
                : (value) {
                    _updateAvailability(
                      roomId: room.id,
                      isAvailable: value,
                    );
                  },
            activeThumbColor: yellow,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Available for Booking',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              room.isAvailable
                  ? 'Customers can select this room.'
                  : 'This room is hidden from new bookings.',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.05,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: yellow,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
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
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(18),
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
              if (buttonText != null &&
                  onPressed != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(
                    Icons.add,
                  ),
                  label: Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
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

  Future<void> _openRoomForm({
    HotelRoom? room,
  }) async {
    final GlobalKey<FormState> formKey =
        GlobalKey<FormState>();

    final TextEditingController nameController =
        TextEditingController(
      text: room?.name ?? '',
    );

    final TextEditingController descriptionController =
        TextEditingController(
      text: room?.description ?? '',
    );

    final TextEditingController guestsController =
        TextEditingController(
      text: room == null
          ? '2'
          : room.maxGuests.toString(),
    );

    final TextEditingController bedsController =
        TextEditingController(
      text: room == null
          ? '1'
          : room.beds.toString(),
    );

    final TextEditingController priceController =
        TextEditingController(
      text: room == null
          ? ''
          : room.pricePerNight.toString(),
    );

    String selectedType =
        room?.roomType ?? 'Standard';

    bool isAvailable =
        room?.isAvailable ?? true;

    final List<String> selectedFacilities =
        List<String>.from(
      room?.facilities ?? <String>[],
    );

    const List<String> roomTypes = <String>[
      'Standard',
      'Single',
      'Double',
      'Family',
      'Deluxe',
      'Suite',
      'Executive',
    ];

    const List<String> availableFacilities =
        <String>[
      'WiFi',
      'Air Conditioning',
      'Heater',
      'TV',
      'Attached Bathroom',
      'Balcony',
      'Breakfast',
      'Room Service',
      'Mountain View',
      'Extra Bed',
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: darkBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setSheetState,
          ) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  MediaQuery.of(context)
                          .viewInsets
                          .bottom +
                      20,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          room == null
                              ? 'Add Hotel Room'
                              : 'Edit Hotel Room',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        _sheetField(
                          controller: nameController,
                          label: 'Room name',
                          icon: Icons.bed_outlined,
                          validator:
                              _requiredValidator,
                        ),

                        Container(
                          margin: const EdgeInsets.only(
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
                            child:
                                DropdownButton<String>(
                              value: selectedType,
                              isExpanded: true,
                              dropdownColor: darkCard,
                              items: roomTypes
                                  .map(
                                    (type) =>
                                        DropdownMenuItem<
                                            String>(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }

                                setSheetState(() {
                                  selectedType = value;
                                });
                              },
                            ),
                          ),
                        ),

                        _sheetField(
                          controller:
                              descriptionController,
                          label: 'Description',
                          icon:
                              Icons.description_outlined,
                          maxLines: 3,
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: _sheetField(
                                controller:
                                    guestsController,
                                label: 'Max guests',
                                icon:
                                    Icons.people_outline,
                                keyboardType:
                                    TextInputType.number,
                                validator:
                                    _positiveIntegerValidator,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _sheetField(
                                controller:
                                    bedsController,
                                label: 'Beds',
                                icon: Icons.bed,
                                keyboardType:
                                    TextInputType.number,
                                validator:
                                    _positiveIntegerValidator,
                              ),
                            ),
                          ],
                        ),

                        _sheetField(
                          controller: priceController,
                          label: 'Price per night',
                          icon:
                              Icons.payments_outlined,
                          keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                            decimal: true,
                          ),
                          validator:
                              _nonNegativePriceValidator,
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Facilities',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              availableFacilities.map(
                            (facility) {
                              final bool selected =
                                  selectedFacilities
                                      .contains(
                                facility,
                              );

                              return FilterChip(
                                selected: selected,
                                label:
                                    Text(facility),
                                selectedColor:
                                    yellow.withValues(
                                  alpha: 0.25,
                                ),
                                checkmarkColor: yellow,
                                onSelected: (value) {
                                  setSheetState(() {
                                    if (value) {
                                      selectedFacilities
                                          .add(facility);
                                    } else {
                                      selectedFacilities
                                          .remove(
                                        facility,
                                      );
                                    }
                                  });
                                },
                              );
                            },
                          ).toList(),
                        ),

                        const SizedBox(height: 12),

                        SwitchListTile(
                          value: isAvailable,
                          onChanged: (value) {
                            setSheetState(() {
                              isAvailable = value;
                            });
                          },
                          activeThumbColor: yellow,
                          contentPadding:
                              EdgeInsets.zero,
                          title: const Text(
                            'Available for Booking',
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          padding:
                              const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: yellow.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Room image upload will be enabled after Firebase Storage billing is available.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final bool valid = formKey
                                      .currentState
                                      ?.validate() ??
                                  false;

                              if (!valid) {
                                return;
                              }

                              final HotelRoom newRoom =
                                  HotelRoom(
                                id: room?.id ?? '',
                                hotelId:
                                    widget.hotelId,
                                name: nameController
                                    .text
                                    .trim(),
                                description:
                                    descriptionController
                                        .text
                                        .trim(),
                                roomType:
                                    selectedType,
                                maxGuests:
                                    int.tryParse(
                                          guestsController
                                              .text
                                              .trim(),
                                        ) ??
                                        1,
                                beds: int.tryParse(
                                      bedsController
                                          .text
                                          .trim(),
                                    ) ??
                                    1,
                                pricePerNight:
                                    double.tryParse(
                                          priceController
                                              .text
                                              .trim(),
                                        ) ??
                                        0,
                                facilities:
                                    List<String>.from(
                                  selectedFacilities,
                                ),
                                imageUrl:
                                    room?.imageUrl ?? '',
                                isAvailable:
                                    isAvailable,
                              );

                              Navigator.pop(
                                sheetContext,
                              );

                              await _saveRoom(
                                room: newRoom,
                                isEdit:
                                    room != null,
                              );
                            },
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor: yellow,
                              foregroundColor:
                                  Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                              ),
                            ),
                            icon: Icon(
                              room == null
                                  ? Icons.add
                                  : Icons.save_outlined,
                            ),
                            label: Text(
                              room == null
                                  ? 'Add Room'
                                  : 'Save Changes',
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
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
    descriptionController.dispose();
    guestsController.dispose();
    bedsController.dispose();
    priceController.dispose();
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: yellow,
          ),
          filled: true,
          fillColor: darkCard,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _saveRoom({
    required HotelRoom room,
    required bool isEdit,
  }) async {
    setState(() {
      _isWorking = true;
    });

    try {
      if (isEdit) {
        await _tourismService
            .adminUpdateHotelRoom(
          roomId: room.id,
          room: room,
        );
      } else {
        await _tourismService
            .adminCreateHotelRoom(
          room,
        );
      }

      _showMessage(
        isEdit
            ? 'Room updated successfully.'
            : 'Room added successfully.',
      );
    } catch (error) {
      _showMessage(
        'Unable to save room: $error',
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

  Future<void> _updateAvailability({
    required String roomId,
    required bool isAvailable,
  }) async {
    setState(() {
      _isWorking = true;
    });

    try {
      await _tourismService
          .adminSetRoomAvailability(
        roomId: roomId,
        isAvailable: isAvailable,
      );

      _showMessage(
        isAvailable
            ? 'Room is now available.'
            : 'Room has been paused.',
      );
    } catch (error) {
      _showMessage(
        'Unable to update room: $error',
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
    HotelRoom room,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Delete Room',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Delete "${room.name}"? This action cannot be undone.',
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
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
      await _tourismService
          .adminDeleteHotelRoom(
        room.id,
      );

      _showMessage(
        'Room deleted successfully.',
      );
    } catch (error) {
      _showMessage(
        'Unable to delete room: $error',
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

  String? _requiredValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  String? _positiveIntegerValidator(
    String? value,
  ) {
    final int? number =
        int.tryParse(
      value?.trim() ?? '',
    );

    if (number == null || number <= 0) {
      return 'Enter a valid number.';
    }

    return null;
  }

  String? _nonNegativePriceValidator(
    String? value,
  ) {
    final double? number =
        double.tryParse(
      value?.trim() ?? '',
    );

    if (number == null || number < 0) {
      return 'Enter a valid price.';
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
