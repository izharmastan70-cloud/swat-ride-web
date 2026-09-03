import 'package:flutter/material.dart';

import '../../models/cargo_booking_model.dart';
import '../../services/cargo_booking_service.dart';

class CargoAdminOrdersScreen extends StatelessWidget {
  const CargoAdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CargoBookingService service = CargoBookingService();

    return Scaffold(
      appBar: AppBar(title: const Text('Cargo Orders'), centerTitle: true),
      body: StreamBuilder<List<CargoBookingModel>>(
        stream: service.watchAllBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load Cargo orders: '
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<CargoBookingModel> bookings =
              snapshot.data ?? <CargoBookingModel>[];

          if (bookings.isEmpty) {
            return const Center(child: Text('No Cargo orders found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _orderCard(context, service, bookings[index]);
            },
          );
        },
      ),
    );
  }

  Widget _orderCard(
    BuildContext context,
    CargoBookingService service,
    CargoBookingModel booking,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ExpansionTile(
        title: Text(
          _serviceName(booking.serviceType),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${booking.status} • '
          'Rs. ${booking.totalFare.toStringAsFixed(0)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _infoRow('Booking ID', booking.bookingId),
          _infoRow('Customer ID', booking.customerId),
          _infoRow('Driver ID', booking.driverId ?? 'Not assigned'),
          _infoRow('Vehicle', booking.vehicleType ?? '-'),
          _infoRow('Pickup', booking.pickupAddress ?? '-'),
          _infoRow('Drop', booking.dropAddress ?? '-'),
          if (booking.shopName != null) _infoRow('Shop', booking.shopName!),
          _infoRow('Payment Method', booking.paymentMethod ?? 'Not selected'),
          _infoRow('Fare', 'Rs. ${booking.totalFare.toStringAsFixed(0)}'),
          _infoRow(
            'Commission',
            'Rs. ${booking.commissionAmount.toStringAsFixed(0)}',
          ),
          _infoRow(
            'Driver Earning',
            'Rs. ${booking.driverNetEarning.toStringAsFixed(0)}',
          ),
          if (booking.serviceType == CargoBookingModel.buyForMe)
            _infoRow(
              'Advance',
              booking.advancePaid
                  ? 'Paid - Rs. ${booking.advanceAmount.toStringAsFixed(0)}'
                  : 'Pending - Rs. ${booking.advanceAmount.toStringAsFixed(0)}',
            ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (booking.status != CargoBookingModel.delivered &&
                  booking.status != CargoBookingModel.cancelled)
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Order'),
                  onPressed: () {
                    _cancelOrder(context, service, booking);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(
    BuildContext context,
    CargoBookingService service,
    CargoBookingModel booking,
  ) async {
    final TextEditingController controller = TextEditingController();

    final String? reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Cargo Order'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Cancellation reason'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text('Cancel Order'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason == null || !context.mounted) {
      return;
    }

    try {
      await service.cancelBooking(
        bookingId: booking.bookingId,
        reason: reason.isEmpty ? 'Cancelled by Cargo Admin' : reason,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cargo order cancelled.')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel Cargo order: $error')),
      );
    }
  }

  String _serviceName(String serviceType) {
    switch (serviceType) {
      case CargoBookingModel.parcel:
        return 'Send Parcel';
      case CargoBookingModel.goods:
        return 'Move Goods';
      case CargoBookingModel.shifting:
        return 'House Shifting';
      case CargoBookingModel.pickupMyItem:
        return 'Pickup My Item';
      case CargoBookingModel.buyForMe:
        return 'Buy For Me';
      default:
        return 'Cargo';
    }
  }
}
