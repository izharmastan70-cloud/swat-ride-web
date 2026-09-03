import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../models/location_model.dart';
import '../../super_admin/services/super_admin_operational_control_service.dart';

class PhoneCallDispatchResult {
  const PhoneCallDispatchResult({
    required this.rideId,
    required this.reused,
    required this.notificationStatus,
  });

  final String rideId;
  final bool reused;
  final String notificationStatus;
}

class PhoneCallDispatchService {
  PhoneCallDispatchService({
    FirebaseAuth? auth,
    http.Client? client,
    String? endpoint,
    SuperAdminOperationalControlService? operationalControls,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _client = client ?? http.Client(),
       _endpoint = endpoint ?? _defaultEndpoint,
       _operationalControls =
           operationalControls ?? SuperAdminOperationalControlService();

  static const String _defaultEndpoint = String.fromEnvironment(
    'CALL_RIDE_DISPATCH_URL',
  );
  static const String _defaultCancellationEndpoint = String.fromEnvironment(
    'CALL_RIDE_CANCELLATION_URL',
  );

  final FirebaseAuth _auth;
  final http.Client _client;
  final String _endpoint;
  final SuperAdminOperationalControlService _operationalControls;

  Future<void> cancel({
    required String rideId,
    required String reason,
  }) async {
    if (_defaultCancellationEndpoint.trim().isEmpty) {
      throw StateError('Call cancellation endpoint has not been configured.');
    }
    final String? token = await _auth.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Sign in before cancelling a phone-call ride.');
    }
    final http.Response response = await _client.post(
      Uri.parse(_defaultCancellationEndpoint),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'rideId': rideId.trim(),
        'reason': reason.trim(),
      }),
    );
    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 ||
        body['ok'] != true) {
      throw StateError((body['code'] ?? 'CANCELLATION_FAILED').toString());
    }
  }

  Future<PhoneCallDispatchResult> dispatch({
    required String callSessionId,
    required String idempotencyKey,
    required String passengerName,
    required String passengerPhone,
    required String driverId,
    required LocationModel pickupLocation,
    required LocationModel destinationLocation,
    required double distanceKm,
    required int estimatedMinutes,
    required String paymentMethod,
  }) async {
    if (callSessionId.trim().isEmpty) {
      throw ArgumentError.value(callSessionId, 'callSessionId', 'is required');
    }
    final SuperAdminOperationalControls controls =
        await _operationalControls.get();
    if (!controls.phoneCallBookingEnabled) {
      throw StateError(
        'Phone-call booking is paused by Super Admin. No booking was created.',
      );
    }
    if (_endpoint.trim().isEmpty) {
      throw StateError('Call dispatch endpoint has not been configured.');
    }
    final String? token = await _auth.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Sign in before dispatching a phone-call ride.');
    }

    final http.Response response = await _client.post(
      Uri.parse(_endpoint),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'callSessionId': callSessionId.trim(),
        'idempotencyKey': idempotencyKey,
        'passengerName': passengerName.trim(),
        'passengerPhone': passengerPhone.trim(),
        'driverId': driverId.trim(),
        'pickupLocation': pickupLocation.toMap(),
        'destinationLocation': destinationLocation.toMap(),
        'distanceKm': distanceKm,
        'estimatedMinutes': estimatedMinutes,
        'paymentMethod': paymentMethod.trim(),
      }),
    );
    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || body['ok'] != true) {
      throw StateError((body['code'] ?? 'DISPATCH_FAILED').toString());
    }
    return PhoneCallDispatchResult(
      rideId: (body['rideId'] ?? '').toString(),
      reused: body['reused'] == true,
      notificationStatus: (body['notificationStatus'] ?? 'UNKNOWN').toString(),
    );
  }
}