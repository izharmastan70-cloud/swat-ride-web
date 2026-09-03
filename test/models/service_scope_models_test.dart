import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/cargo/models/cargo_driver_application_model.dart';
import 'package:swat_ride/models/ride_model.dart';

void main() {
  test('normal rides serialize an explicit normal-ride scope', () {
    expect(RideModel.normalRideScope, 'normal_ride');
  });

  test('cargo driver applications default to the cargo scope', () {
    final CargoDriverApplicationModel application =
        CargoDriverApplicationModel.fromMap(<String, dynamic>{});

    expect(application.serviceScope, CargoDriverApplicationModel.cargoScope);
  });
}