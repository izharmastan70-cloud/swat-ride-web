import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:swat_ride/models/location_model.dart';
import 'package:swat_ride/services/osrm_routing_service.dart';

class _ResponseClient extends http.BaseClient {
  _ResponseClient(this.response);

  final http.Response response;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  const LocationModel pickup = LocationModel(
    latitude: 34.7717,
    longitude: 72.3602,
    address: 'Mingora',
    placeName: 'Mingora',
  );
  const LocationModel destination = LocationModel(
    latitude: 34.7464,
    longitude: 72.3571,
    address: 'Saidu Sharif',
    placeName: 'Saidu Sharif',
  );

  test('parses OSRM driving distance, duration and GeoJSON geometry', () async {
    final OsrmRoutingService service = OsrmRoutingService(
      client: _ResponseClient(http.Response('''
        {"code":"Ok","routes":[{"distance":4250.5,"duration":742.2,
        "geometry":{"coordinates":[[72.3602,34.7717],[72.3571,34.7464]]}}]}
      ''', 200)),
    );

    final route = await service.getDrivingRoute(
      pickup: pickup,
      destination: destination,
    );

    expect(route.distanceKm, 4.2505);
    expect(route.estimatedMinutes, 13);
    expect(route.geometry.first.latitude, 34.7717);
    expect(route.geometry.last.longitude, 72.3571);
  });

  test('rejects OSRM responses with no route', () async {
    final OsrmRoutingService service = OsrmRoutingService(
      client: _ResponseClient(http.Response('{"code":"NoRoute","routes":[]}', 200)),
    );

    expect(
      () => service.getDrivingRoute(pickup: pickup, destination: destination),
      throwsA(isA<OsrmRoutingException>()),
    );
  });
}