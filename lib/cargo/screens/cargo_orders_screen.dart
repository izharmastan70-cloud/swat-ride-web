import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/cargo_booking_model.dart';
import '../services/cargo_booking_service.dart';
import 'cargo_tracking_screen.dart';

class CargoOrdersScreen extends StatelessWidget {
  const CargoOrdersScreen({super.key});

  static const Color _yellow = Color(0xFFFFD60A);
  static const Color _background = Color(0xFF0D0D0D);
  static const Color _card = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view your Cargo orders.')),
      );
    }

    final CargoBookingService bookingService = CargoBookingService();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('My Cargo Orders'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<CargoBookingModel>>(
        stream: bookingService.watchCustomerBookings(user.uid),
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 56,
                      color: _yellow,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No Cargo orders yet',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Your current and previous Cargo bookings '
                      'will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _bookingCard(context, bookings[index]);
            },
          );
        },
      ),
    );
  }

  Widget _bookingCard(BuildContext context, CargoBookingModel booking) {
    return Card(
      color: _card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CargoTrackingScreen(bookingId: booking.bookingId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _yellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_statusIcon(booking.status), color: _yellow),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _serviceName(booking.serviceType),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _statusName(booking.status),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      booking.dropAddress ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _serviceName(String type) {
    switch (type) {
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

  String _statusName(String status) {
    switch (status) {
      case CargoBookingModel.searching:
        return 'Searching for driver';
      case CargoBookingModel.driverAssigned:
        return 'Driver assigned';
      case CargoBookingModel.driverArriving:
        return 'Driver arriving';
      case CargoBookingModel.pickedUp:
        return 'Picked up';
      case CargoBookingModel.shopping:
        return 'Driver shopping';
      case CargoBookingModel.onTheWay:
        return 'On the way';
      case CargoBookingModel.delivered:
        return 'Delivered';
      case CargoBookingModel.cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case CargoBookingModel.delivered:
        return Icons.check_circle_outline;
      case CargoBookingModel.cancelled:
        return Icons.cancel_outlined;
      case CargoBookingModel.shopping:
        return Icons.shopping_bag_outlined;
      case CargoBookingModel.onTheWay:
        return Icons.local_shipping_outlined;
      default:
        return Icons.local_shipping_outlined;
    }
  }
}
