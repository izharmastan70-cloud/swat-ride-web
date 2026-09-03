// Button that fetches a user's current GPS location and centers the map on it.

import 'dart:async';

import 'package:flutter/material.dart';
import '../models/map_location_model.dart';
import '../services/open_map_location_service.dart';

class CurrentLocationButton extends StatefulWidget {
  /// Callback when location is successfully fetched
  final Function(MapLocation) onLocationFetched;

  /// Callback on error
  final Function(String)? onError;

  /// Button styling
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final EdgeInsets padding;

  /// Behavior
  final bool showLoadingIndicator;
  final Duration loadingTimeout;

  const CurrentLocationButton({
    super.key,
    required this.onLocationFetched,
    this.onError,
    this.backgroundColor,
    this.iconColor,
    this.size = 56,
    this.padding = const EdgeInsets.all(0),
    this.showLoadingIndicator = true,
    this.loadingTimeout = const Duration(seconds: 30),
  });

  @override
  State<CurrentLocationButton> createState() => _CurrentLocationButtonState();
}

class _CurrentLocationButtonState extends State<CurrentLocationButton> {
  bool _isLoading = false;
  late OpenMapLocationService _locationService;

  @override
  void initState() {
    super.initState();
    _locationService = OpenMapLocationService();
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final location = await _locationService.getCurrentLocation(
        forceRefresh: true,
      ).timeout(
        widget.loadingTimeout,
        onTimeout: () => throw TimeoutException('Location fetch timed out'),
      );

      if (!mounted) return;

      if (location == null) {
        widget.onError?.call('Unable to fetch location. Please enable location services.');
        setState(() => _isLoading = false);
        return;
      }

      // Verify location is in service area
      if (!_locationService.isLocationInSwat(location)) {
        widget.onError?.call(
          'Your location appears to be outside Swat service area. '
          'Please check your GPS.',
        );
        setState(() => _isLoading = false);
        return;
      }

      widget.onLocationFetched(location);

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location fetched successfully'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() => _isLoading = false);
    } on TimeoutException {
      if (!mounted) return;
      widget.onError?.call(
        'Location fetch timed out. Please try again or check your GPS signal.',
      );
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      widget.onError?.call('Error: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: FloatingActionButton(
        onPressed: _isLoading ? null : _getCurrentLocation,
        backgroundColor: widget.backgroundColor ??
            (Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.white),
        foregroundColor: widget.iconColor ??
            (Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.blue),
        elevation: _isLoading ? 4 : 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        tooltip: _isLoading ? 'Fetching location...' : 'Use my current location',
        child: _isLoading && widget.showLoadingIndicator
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.iconColor ??
                        (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.blue),
                  ),
                ),
              )
            : Icon(
                Icons.my_location,
                size: 24,
              ),
      ),
    );
  }
}

/// More compact version of current location button
class CompactCurrentLocationButton extends StatefulWidget {
  /// Callback when location is successfully fetched
  final Function(MapLocation) onLocationFetched;

  /// Callback on error
  final Function(String)? onError;

  /// Styling
  final Color? backgroundColor;
  final Color? iconColor;

  const CompactCurrentLocationButton({
    super.key,
    required this.onLocationFetched,
    this.onError,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<CompactCurrentLocationButton> createState() =>
      _CompactCurrentLocationButtonState();
}

class _CompactCurrentLocationButtonState
    extends State<CompactCurrentLocationButton> {
  bool _isLoading = false;
  late OpenMapLocationService _locationService;

  @override
  void initState() {
    super.initState();
    _locationService = OpenMapLocationService();
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final location = await _locationService
          .getCurrentLocation(forceRefresh: true)
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (location == null) {
        widget.onError?.call('Unable to fetch location');
        setState(() => _isLoading = false);
        return;
      }

      widget.onLocationFetched(location);
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      widget.onError?.call(e.toString());
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: IconButton(
        onPressed: _isLoading ? null : _getCurrentLocation,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.my_location),
        tooltip: 'Use my location',
        color: widget.iconColor ?? Colors.blue,
        style: IconButton.styleFrom(
          backgroundColor:
              widget.backgroundColor ?? Colors.grey.withValues(alpha: 0.2),
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }
}
