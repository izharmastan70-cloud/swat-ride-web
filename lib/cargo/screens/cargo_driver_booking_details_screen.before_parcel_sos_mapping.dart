import 'package:flutter/material.dart';

import '../../safety/models/safety_models.dart';
import '../../safety/screens/safety_center_screen.dart';
import '../models/cargo_booking_model.dart';
import '../models/cargo_driver_application_model.dart';
import '../services/cargo_booking_service.dart';
import '../services/cargo_driver_booking_service.dart';

class CargoDriverBookingDetailsScreen extends StatefulWidget {
  const CargoDriverBookingDetailsScreen({
    super.key,
    required this.bookingId,
    required this.driver,
  });

  final String bookingId;
  final CargoDriverApplicationModel driver;

  @override
  State<CargoDriverBookingDetailsScreen> createState() =>
      _CargoDriverBookingDetailsScreenState();
}

class _CargoDriverBookingDetailsScreenState
    extends State<CargoDriverBookingDetailsScreen> {
  final CargoBookingService _bookingService =
      CargoBookingService();

  final CargoDriverBookingService _driverService =
      CargoDriverBookingService();

  bool _updatingStatus = false;

  Future<void> _runAction(
    Future<void> Function() action,
  ) async {
    if (_updatingStatus) {
      return;
    }

    setState(() {
      _updatingStatus = true;
    });

    try {
      await action();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargo job status updated.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst('StateError: ', '')
                .replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingStatus = false;
        });
      }
    }
  }

  void _openUniversalSafetyCenter(
    CargoBookingModel booking,
  ) {
    final CargoDriverApplicationModel driver =
        widget.driver;

    final SafetyPersonSnapshot driverPerson =
        SafetyPersonSnapshot(
      userId: driver.userId,
      role: SafetyUserRole.cargoDriver,
      fullName: driver.fullName,
      phoneNumber: driver.phone,
      profileImageUrl:
          driver.driverPhotoUrl ?? '',
      isVerified:
          driver.status ==
              CargoDriverApplicationModel.approved,
      extraData: <String, dynamic>{
        'applicationId':
            driver.applicationId,
      },
    );

    final SafetyVehicleSnapshot vehicle =
        SafetyVehicleSnapshot(
      vehicleId: driver.applicationId,
      vehicleType: driver.vehicleType,
      vehicleNumber: driver.vehicleNumber,
      registrationNumber:
          driver.vehicleNumber,
      imageUrl:
          driver.vehiclePhotoUrl ?? '',
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return SafetyCenterScreen(
            contextData: SafetyContext(
              serviceType:
                  SafetyServiceType.cargoDelivery,
              referenceId:
                  booking.bookingId,
              initiatedByUserId:
                  driver.userId,
              initiatedByRole:
                  SafetyUserRole.cargoDriver,
              sourcePage:
                  SafetySourcePage.cargoTracking,
              referenceStatus:
                  booking.status,
              primaryPerson:
                  driverPerson,
              vehicle:
                  vehicle,
              serviceTitle:
                  'Cargo Driver Safety',
              serviceSubtitle:
                  _serviceName(
                booking.serviceType,
              ),
              paymentMethod:
                  booking.paymentMethod ?? '',
              metadata: <String, dynamic>{
                'bookingId':
                    booking.bookingId,
                'driverId':
                    driver.userId,
                'applicationId':
                    driver.applicationId,
                'customerId':
                    booking.customerId,
                'serviceType':
                    booking.serviceType,
                'vehicleType':
                    driver.vehicleType,
                'vehicleNumber':
                    driver.vehicleNumber,
                'pickupAddress':
                    booking.pickupAddress ?? '',
                'dropAddress':
                    booking.dropAddress ?? '',
                'shopName':
                    booking.shopName ?? '',
                'shopAddress':
                    booking.shopAddress ?? '',
                'totalFare':
                    booking.totalFare,
                'driverNetEarning':
                    booking.driverNetEarning,
                'advancePaid':
                    booking.advancePaid,

                // CNIC, receiver phone, private documents
                // and other sensitive credentials are
                // intentionally excluded.
                //
                // Cargo booking model currently has no
                // pickup/drop GPS coordinates, so no fake
                // SafetyLocation is created.
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CargoBookingModel?>(
      stream: _bookingService.watchBooking(
        widget.bookingId,
      ),
      builder: (
        BuildContext context,
        AsyncSnapshot<CargoBookingModel?> snapshot,
      ) {
        final CargoBookingModel? booking =
            snapshot.data;

        return Scaffold(
          backgroundColor:
              const Color(0xFFF5F6F8),
          appBar: AppBar(
            backgroundColor:
                Colors.white,
            surfaceTintColor:
                Colors.white,
            title: const Text(
              'Cargo Job Details',
            ),
            actions:
                booking == null ||
                        booking.status ==
                            CargoBookingModel.cancelled ||
                        booking.status ==
                            CargoBookingModel.delivered
                    ? null
                    : <Widget>[
                        IconButton(
                          tooltip:
                              'Safety & SOS',
                          onPressed: () {
                            _openUniversalSafetyCenter(
                              booking,
                            );
                          },
                          icon: const Icon(
                            Icons.shield_outlined,
                            color:
                                Colors.redAccent,
                          ),
                        ),
                      ],
          ),
          body: _buildBody(
            snapshot,
            booking,
          ),
        );
      },
    );
  }

  Widget _buildBody(
    AsyncSnapshot<CargoBookingModel?> snapshot,
    CargoBookingModel? booking,
  ) {
    if (snapshot.connectionState ==
            ConnectionState.waiting &&
        booking == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (snapshot.hasError) {
      return const _MessageCard(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load Cargo job',
        message:
            'Please check your connection and try again.',
      );
    }

    if (booking == null) {
      return const _MessageCard(
        icon: Icons.inventory_2_outlined,
        title: 'Cargo booking not found',
        message:
            'This Cargo booking is no longer available.',
      );
    }

    if (booking.driverId !=
        widget.driver.userId) {
      return const _MessageCard(
        icon: Icons.lock_outline,
        title: 'Job access denied',
        message:
            'This Cargo booking is not assigned to this driver.',
      );
    }

    return SafeArea(
      child: ListView(
        padding:
            const EdgeInsets.all(16),
        children: <Widget>[
          _StatusCard(
            booking: booking,
          ),
          const SizedBox(height: 14),
          _RouteCard(
            booking: booking,
          ),
          const SizedBox(height: 14),
          _BookingInfoCard(
            booking: booking,
          ),
          const SizedBox(height: 14),
          _EarningsCard(
            booking: booking,
          ),
          const SizedBox(height: 18),
          if (booking.status !=
                  CargoBookingModel.cancelled &&
              booking.status !=
                  CargoBookingModel.delivered)
            OutlinedButton.icon(
              onPressed: () {
                _openUniversalSafetyCenter(
                  booking,
                );
              },
              icon: const Icon(
                Icons.shield_outlined,
              ),
              label: const Text(
                'SAFETY & SOS',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    Colors.redAccent,
                minimumSize:
                    const Size.fromHeight(
                  52,
                ),
                side: const BorderSide(
                  color:
                      Colors.redAccent,
                ),
              ),
            ),
          if (booking.status !=
                  CargoBookingModel.cancelled &&
              booking.status !=
                  CargoBookingModel.delivered)
            const SizedBox(height: 12),
          _buildPrimaryAction(
            booking,
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(
    CargoBookingModel booking,
  ) {
    if (_updatingStatus) {
      return const SizedBox(
        height: 52,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (booking.status ==
        CargoBookingModel.driverAssigned) {
      return _ActionButton(
        label: 'Start Heading to Pickup',
        icon: Icons.navigation_outlined,
        onPressed: () {
          _runAction(
            () => _driverService.markArriving(
              booking.bookingId,
            ),
          );
        },
      );
    }

    if (booking.status ==
        CargoBookingModel.driverArriving) {
      if (booking.serviceType ==
          CargoBookingModel.buyForMe) {
        return _ActionButton(
          label: 'Start Shopping',
          icon:
              Icons.shopping_cart_outlined,
          onPressed: () {
            _runAction(
              () =>
                  _driverService.startShopping(
                booking.bookingId,
              ),
            );
          },
        );
      }

      return _ActionButton(
        label: 'Mark Cargo Picked Up',
        icon:
            Icons.inventory_2_outlined,
        onPressed: () {
          _runAction(
            () => _driverService.markPickedUp(
              booking.bookingId,
            ),
          );
        },
      );
    }

    if (booking.status ==
            CargoBookingModel.pickedUp ||
        booking.status ==
            CargoBookingModel.shopping) {
      return _ActionButton(
        label: 'Start Delivery',
        icon:
            Icons.local_shipping_outlined,
        onPressed: () {
          _runAction(
            () =>
                _driverService.markOnTheWay(
              booking.bookingId,
            ),
          );
        },
      );
    }

    if (booking.status ==
        CargoBookingModel.onTheWay) {
      return _ActionButton(
        label: 'Mark Delivered',
        icon:
            Icons.check_circle_outline,
        onPressed: () {
          _confirmDelivered(
            booking,
          );
        },
      );
    }

    if (booking.status ==
        CargoBookingModel.delivered) {
      return const _MessageCard(
        icon:
            Icons.check_circle_outline,
        title: 'Cargo Delivered',
        message:
            'This Cargo job has been completed.',
      );
    }

    if (booking.status ==
        CargoBookingModel.cancelled) {
      return _MessageCard(
        icon: Icons.cancel_outlined,
        title: 'Cargo Job Cancelled',
        message:
            booking.cancellationReason ??
                'This Cargo job was cancelled.',
      );
    }

    return const _MessageCard(
      icon: Icons.info_outline,
      title: 'Waiting for next step',
      message:
          'The Cargo job status will update automatically.',
    );
  }

  Future<void> _confirmDelivered(
    CargoBookingModel booking,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          title:
              const Text('Confirm Delivery'),
          content: const Text(
            'Confirm that the Cargo has been delivered to the receiver.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text('Not yet'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child:
                  const Text('Delivered'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _runAction(
      () => _driverService.markDelivered(
        booking.bookingId,
      ),
    );
  }

  String _serviceName(
    String serviceType,
  ) {
    switch (serviceType) {
      case CargoBookingModel.parcel:
        return 'Parcel Delivery';

      case CargoBookingModel.goods:
        return 'Goods Delivery';

      case CargoBookingModel.shifting:
        return 'Home / Office Shifting';

      case CargoBookingModel.pickupMyItem:
        return 'Pickup My Item';

      case CargoBookingModel.buyForMe:
        return 'Buy For Me';

      default:
        return serviceType
            .replaceAll('_', ' ');
    }
  }
}

class _StatusCard
    extends StatelessWidget {
  const _StatusCard({
    required this.booking,
  });

  final CargoBookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 26,
            backgroundColor:
                Color(0xFFEAF3FF),
            foregroundColor:
                Color(0xFF123C69),
            child: Icon(
              Icons.local_shipping_outlined,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Current Status',
                  style: TextStyle(
                    color:
                        Color(0xFF68778A),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  booking.status
                      .replaceAll('_', ' ')
                      .toUpperCase(),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard
    extends StatelessWidget {
  const _RouteCard({
    required this.booking,
  });

  final CargoBookingModel booking;

  @override
  Widget build(BuildContext context) {
    final String pickup =
        booking.pickupAddress
                    ?.trim()
                    .isNotEmpty ==
                true
            ? booking.pickupAddress!
                .trim()
            : booking.shopAddress
                        ?.trim()
                        .isNotEmpty ==
                    true
                ? booking.shopAddress!
                    .trim()
                : 'Pickup location';

    final String drop =
        booking.dropAddress
                    ?.trim()
                    .isNotEmpty ==
                true
            ? booking.dropAddress!
                .trim()
            : 'Delivery location';

    return _SectionCard(
      title: 'Route',
      children: <Widget>[
        _InfoRow(
          label: 'Pickup',
          value: pickup,
        ),
        _InfoRow(
          label: 'Delivery',
          value: drop,
        ),
      ],
    );
  }
}

class _BookingInfoCard
    extends StatelessWidget {
  const _BookingInfoCard({
    required this.booking,
  });

  final CargoBookingModel booking;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Booking Details',
      children: <Widget>[
        _InfoRow(
          label: 'Booking ID',
          value: booking.bookingId,
        ),
        _InfoRow(
          label: 'Service',
          value: booking.serviceType
              .replaceAll('_', ' '),
        ),
        _InfoRow(
          label: 'Vehicle',
          value:
              booking.vehicleType ?? '-',
        ),
        if (booking.shopName
                    ?.trim()
                    .isNotEmpty ==
                true)
          _InfoRow(
            label: 'Shop',
            value:
                booking.shopName!.trim(),
          ),
        if (booking.itemNote
                    ?.trim()
                    .isNotEmpty ==
                true)
          _InfoRow(
            label: 'Instructions',
            value:
                booking.itemNote!.trim(),
          ),
        if (booking.paymentMethod !=
            null)
          _InfoRow(
            label: 'Payment',
            value:
                booking.paymentMethod!,
          ),
        if (booking.serviceType ==
            CargoBookingModel.buyForMe)
          _InfoRow(
            label: 'Advance',
            value: booking.advancePaid
                ? 'Verified'
                : 'Not verified',
          ),
      ],
    );
  }
}

class _EarningsCard
    extends StatelessWidget {
  const _EarningsCard({
    required this.booking,
  });

  final CargoBookingModel booking;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Fare & Earnings',
      children: <Widget>[
        _InfoRow(
          label: 'Total Fare',
          value:
              'Rs ${booking.totalFare.toStringAsFixed(0)}',
        ),
        _InfoRow(
          label: 'Commission',
          value:
              'Rs ${booking.commissionAmount.toStringAsFixed(0)}',
        ),
        _InfoRow(
          label: 'Driver Net',
          value:
              'Rs ${booking.driverNetEarning.toStringAsFixed(0)}',
        ),
      ],
    );
  }
}

class _SectionCard
    extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow
    extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color:
                    Color(0xFF68778A),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton
    extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style:
          FilledButton.styleFrom(
        minimumSize:
            const Size.fromHeight(54),
      ),
    );
  }
}

class _MessageCard
    extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(28),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 48,
              color:
                  const Color(0xFF68778A),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color:
                    Color(0xFF68778A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
