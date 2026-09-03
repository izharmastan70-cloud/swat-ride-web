import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class RideSocketEvent {
  const RideSocketEvent({
    required this.name,
    required this.rideId,
    required this.payload,
  });

  final String name;
  final String rideId;
  final Map<String, dynamic> payload;
}

class RideSocketService {
  RideSocketService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  static const List<String> _rideEvents = <String>[
    'ride_requested',
    'ride_accepted',
    'driver_arrived',
    'trip_started',
    'trip_completed',
  ];

  final FirebaseAuth _auth;
  final StreamController<RideSocketEvent> _events =
      StreamController<RideSocketEvent>.broadcast();
  io.Socket? _socket;

  Stream<RideSocketEvent> get events => _events.stream;
  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect(String serverUrl) async {
    final String normalizedUrl = serverUrl.trim();
    final User? user = _auth.currentUser;
    if (normalizedUrl.isEmpty || user == null) {
      throw StateError('A signed-in user and Socket.io server URL are required.');
    }

    await disconnect();
    final String token = await user.getIdToken(true);
    _socket = io.io(
      normalizedUrl,
      <String, dynamic>{
        'transports': <String>['websocket'],
        'autoConnect': false,
        'auth': <String, String>{'token': token},
      },
    );

    for (final String eventName in _rideEvents) {
      _socket!.on(eventName, (dynamic data) {
        final Map<String, dynamic> payload =
            Map<String, dynamic>.from(data as Map<dynamic, dynamic>);
        _events.add(RideSocketEvent(
          name: eventName,
          rideId: payload['rideId']?.toString() ?? '',
          payload: payload,
        ));
      });
    }

    _socket!.connect();
  }

  Future<void> disconnect() async {
    _socket?.dispose();
    _socket = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _events.close();
  }
}