// Reusable Mapbox map widget with marker and selection support.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/mapbox_config.dart';
import '../models/map_location_model.dart';

class OpenMapViewWidget extends StatefulWidget {
  /// Initial center location
  final MapLocation initialLocation;

  /// Callbacks and handlers
  final Function(MapLocation) onLocationChanged;
  final Function(MapLocation)? onLocationSelected;
  final VoidCallback? onMapTap;

  /// Display settings
  final double initialZoom;
  final bool enableDragging;
  final bool showMarker;
  final bool showCenterPin;
  final bool showLocationCard;
  final List<MapPin> additionalPins;
  final List<LatLng> routePoints;

  /// UI customization
  final Color markerColor;
  final double markerSize;
  final Widget? customMarkerWidget;

  const OpenMapViewWidget({
    super.key,
    required this.initialLocation,
    required this.onLocationChanged,
    this.onLocationSelected,
    this.onMapTap,
    this.initialZoom = 16,
    this.enableDragging = false,
    this.showMarker = true,
    this.showCenterPin = true,
    this.showLocationCard = true,
    this.additionalPins = const [],
    this.routePoints = const [],
    this.markerColor = Colors.red,
    this.markerSize = 40,
    this.customMarkerWidget,
  });

  @override
  State<OpenMapViewWidget> createState() => _OpenMapViewWidgetState();
}

class _OpenMapViewWidgetState extends State<OpenMapViewWidget> {
  late MapLocation currentLocation;
  late MapController _mapController;
  LatLng? _draggedPosition;

  @override
  void initState() {
    super.initState();
    currentLocation = widget.initialLocation;
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant OpenMapViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLocation != oldWidget.initialLocation) {
      currentLocation = widget.initialLocation;
      _draggedPosition = null;
      _mapController.move(currentLocation.latLng, _mapController.camera.zoom);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _updateLocation(LatLng newLatLng) {
    final newLocation = MapLocation(
      latitude: newLatLng.latitude,
      longitude: newLatLng.longitude,
      addressName: currentLocation.addressName,
      selectionMethod: widget.enableDragging
          ? LocationSelectionMethod.mapPin
          : currentLocation.selectionMethod,
      selectedAt: DateTime.now(),
    );

    setState(() {
      currentLocation = newLocation;
      _draggedPosition = newLatLng;
    });

    widget.onLocationChanged(newLocation);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentLocation.latLng,
              initialZoom: widget.initialZoom,
              minZoom: 5,
              maxZoom: 19,
              onPositionChanged: (position, hasGesture) {
                if (widget.enableDragging && hasGesture && position.center != null) {
                  _updateLocation(position.center!);
                }
              },
              onTap: (tapPosition, latLng) {
                if (widget.enableDragging) {
                  _updateLocation(latLng);
                  widget.onLocationSelected?.call(
                    MapLocation.fromLatLng(latLng),
                  );
                }
                widget.onMapTap?.call();
              },
            ),
            children: [
              // Base layer: Mapbox Streets raster tiles.
              TileLayer(
                urlTemplate: MapboxConfig.rasterTilesUrl,
                userAgentPackageName: 'com.swatride.app',
                maxNativeZoom: 19,
              ),

              // Markers layer
              MarkerLayer(
                markers: _buildMarkers(),
              ),

              // Polylines for additional features (routes, etc)
              PolylineLayer(
                polylines: widget.routePoints.length < 2
                    ? const <Polyline>[]
                    : <Polyline>[
                        Polyline(
                          points: widget.routePoints,
                          color: Colors.blue,
                          strokeWidth: 5,
                        ),
                      ],
              ),
            ],
          ),

          // Center pin indicator (if enabled)
          if (widget.showCenterPin)
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 12,
              top: MediaQuery.of(context).size.height / 2 - 12,
              child: _buildCenterPin(),
            ),

          // Location info card (bottom)
          if (widget.showLocationCard)
            Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildLocationCard(),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Main marker at current location
    if (widget.showMarker) {
      markers.add(
        Marker(
          point: _draggedPosition ?? currentLocation.latLng,
          width: widget.markerSize,
          height: widget.markerSize,
          child: GestureDetector(
            onLongPress: widget.enableDragging ? () {} : null,
            child: widget.customMarkerWidget ??
                _buildDefaultMarker(),
          ),
        ),
      );
    }

    // Additional markers
    for (final pin in widget.additionalPins) {
      markers.add(
        Marker(
          point: pin.location.latLng,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: pin.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                pin.label ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildDefaultMarker() {
    return Container(
      decoration: BoxDecoration(
        color: widget.markerColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.location_on,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildCenterPin() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      width: 24,
      height: 24,
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentLocation.addressName ?? 'Unknown Location',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${currentLocation.latitude.toStringAsFixed(4)}, '
              '${currentLocation.longitude.toStringAsFixed(4)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (widget.enableDragging) ...[
              const SizedBox(height: 8),
              Text(
                'Drag map to select location',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Represents a pin/marker to display on the map
class MapPin {
  final MapLocation location;
  final Color color;
  final String? label;
  final VoidCallback? onTap;

  const MapPin({
    required this.location,
    this.color = Colors.blue,
    this.label,
    this.onTap,
  });
}
