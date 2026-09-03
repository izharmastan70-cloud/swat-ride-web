// Full-screen map interface for pickup and dropoff location selection.

import 'package:flutter/material.dart';
import '../models/map_location_model.dart';
import '../services/open_map_location_service.dart';
import '../widgets/open_map_view_widget.dart';
import '../widgets/current_location_button_widget.dart';

class OpenMapSelectionScreen extends StatefulWidget {
  /// Title for the screen
  final String title;

  /// Subtitle or instruction text
  final String? subtitle;

  /// Initial location to display
  final MapLocation? initialLocation;

  /// Callback when location is selected
  final Function(MapLocation) onLocationSelected;

  /// Whether to show location history
  final bool showHistory;

  /// Recent locations from previous selections
  final List<MapLocation>? recentLocations;

  const OpenMapSelectionScreen({
    super.key,
    this.title = 'Select Location',
    this.subtitle,
    this.initialLocation,
    required this.onLocationSelected,
    this.showHistory = true,
    this.recentLocations,
  });

  @override
  State<OpenMapSelectionScreen> createState() =>
      _OpenMapSelectionScreenState();
}

class _OpenMapSelectionScreenState extends State<OpenMapSelectionScreen> {
  late MapLocation _selectedLocation;
  List<MapLocation> _recentLocations = [];
  bool _showHistoryPanel = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ??
        OpenMapLocationService.getSwatCenter();
    _recentLocations = widget.recentLocations ?? [];
  }

  void _onLocationChanged(MapLocation location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _onConfirmLocation() {
    widget.onLocationSelected(_selectedLocation);
    Navigator.pop(context, _selectedLocation);
  }

  void _onCurrentLocationFetched(MapLocation location) {
    setState(() {
      _selectedLocation = location;
    });

    // Show confirmation dialog
    _showLocationConfirmation(location);
  }

  void _showLocationConfirmation(MapLocation location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Confirmed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location.addressName ?? 'Unknown Location',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Change'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _onConfirmLocation();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<MapLocation>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _selectedLocation);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
          elevation: 0,
          actions: [
            if (widget.showHistory)
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  setState(() {
                    _showHistoryPanel = !_showHistoryPanel;
                  });
                },
                tooltip: 'Recent locations',
              ),
          ],
        ),
        body: Stack(
          children: [
            // Map view with dragging enabled
            OpenMapViewWidget(
              initialLocation: _selectedLocation,
              onLocationChanged: _onLocationChanged,
              onLocationSelected: (location) {
                setState(() {
                  _selectedLocation = location;
                });
              },
              enableDragging: true,
              showMarker: true,
              showCenterPin: true,
              initialZoom: 15,
            ),

            // Top instruction panel
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        )
                      else
                        const Text(
                          'Drag the map or tap to select location\nTap the location button to use current GPS location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Current location button (top-right)
            Positioned(
              top: 16,
              right: 16,
              child: CurrentLocationButton(
                onLocationFetched: _onCurrentLocationFetched,
                onError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                size: 50,
              ),
            ),

            // Location history panel (right side, collapsible)
            if (_showHistoryPanel)
              Positioned(
                right: 0,
                top: 80,
                bottom: 100,
                width: MediaQuery.of(context).size.width * 0.6,
                child: Card(
                  elevation: 8,
                  margin: const EdgeInsets.all(8),
                  child: _buildHistoryPanel(),
                ),
              ),

            // Bottom action bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).padding.bottom + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selected location info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedLocation.addressName ??
                                      'Selected Location',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${_selectedLocation.latitude.toStringAsFixed(4)}, '
                                  '${_selectedLocation.longitude.toStringAsFixed(4)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _onConfirmLocation,
                            child: const Text('Confirm Location'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPanel() {
    if (_recentLocations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.history, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No recent locations',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _recentLocations.length,
      itemBuilder: (context, index) {
        final location = _recentLocations[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.location_on, size: 20, color: Colors.blue),
          title: Text(
            location.addressName ?? 'Location',
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 10),
          ),
          onTap: () {
            setState(() {
              _selectedLocation = location;
              _showHistoryPanel = false;
            });
          },
        );
      },
    );
  }
}
