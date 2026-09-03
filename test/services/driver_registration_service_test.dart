import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/services/driver_registration_service.dart';

void main() {
  test('normalizes registration, chassis and CNIC identities consistently', () {
    expect(
      DriverRegistrationService.normalizeVehicleIdentity(' swat-123 / a '),
      'SWAT123A',
    );
    expect(
      DriverRegistrationService.normalizeVehicleIdentity('35202-1234567-1'),
      '3520212345671',
    );
  });
}