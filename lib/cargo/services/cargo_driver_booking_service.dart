import '../models/cargo_booking_model.dart';
import 'cargo_booking_service.dart';

class CargoDriverBookingService {
  CargoDriverBookingService({CargoBookingService? bookingService})
    : _bookingService = bookingService ?? CargoBookingService();

  final CargoBookingService _bookingService;

  Future<void> markArriving(String bookingId) async {
    await _bookingService.updateStatus(
      bookingId: bookingId,
      status: CargoBookingModel.driverArriving,
    );
  }

  Future<void> markPickedUp(String bookingId) async {
    final CargoBookingModel booking = await _requireBooking(bookingId);

    if (booking.serviceType == CargoBookingModel.buyForMe) {
      throw StateError('Buy For Me must use shopping status.');
    }

    await _bookingService.updateStatus(
      bookingId: bookingId,
      status: CargoBookingModel.pickedUp,
    );
  }

  Future<void> startShopping(String bookingId) async {
    final CargoBookingModel booking = await _requireBooking(bookingId);

    if (booking.serviceType != CargoBookingModel.buyForMe) {
      throw StateError('Shopping status is only for Buy For Me.');
    }

    await _bookingService.ensureAdvanceVerified(bookingId);

    await _bookingService.updateStatus(
      bookingId: bookingId,
      status: CargoBookingModel.shopping,
    );
  }

  Future<void> markOnTheWay(String bookingId) async {
    await _requireBooking(bookingId);

    await _bookingService.updateStatus(
      bookingId: bookingId,
      status: CargoBookingModel.onTheWay,
    );
  }

  Future<void> markDelivered(String bookingId) async {
    await _requireBooking(bookingId);

    await _bookingService.updateStatus(
      bookingId: bookingId,
      status: CargoBookingModel.delivered,
    );
  }

  Future<CargoBookingModel> _requireBooking(String bookingId) async {
    final CargoBookingModel? booking = await _bookingService.getBooking(
      bookingId,
    );

    if (booking == null) {
      throw StateError('Cargo booking not found.');
    }

    if (booking.status == CargoBookingModel.cancelled ||
        booking.status == CargoBookingModel.delivered) {
      throw StateError('Cargo booking is already closed.');
    }

    return booking;
  }
}
