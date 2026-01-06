import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/map_constants.dart';
import 'package:farmdashr/data/models/geo_location.dart';
import 'package:farmdashr/data/services/location_service.dart';

/// Interactive map picker widget for selecting a location.
/// Used by farmers to set farm and pickup locations.
class MapPickerWidget extends StatefulWidget {
  /// Initial location to center the map on.
  final GeoLocation? initialLocation;

  /// Callback when location is selected.
  final ValueChanged<GeoLocation>? onLocationChanged;

  /// Height of the map widget.
  final double height;

  /// Whether to show the "Use My Location" button.
  final bool showCurrentLocationButton;

  /// Whether to show coordinate display below the map.
  final bool showCoordinates;

  const MapPickerWidget({
    super.key,
    this.initialLocation,
    this.onLocationChanged,
    this.height = 300,
    this.showCurrentLocationButton = true,
    this.showCoordinates = true,
  });

  @override
  State<MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends State<MapPickerWidget> {
  late final MapController _mapController;
  late GeoLocation _selectedLocation;
  final LocationService _locationService = LocationService();
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation ?? MapConstants.defaultCenter;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = GeoLocation.fromLatLng(point);
    });
    widget.onLocationChanged?.call(_selectedLocation);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    final location = await _locationService.getCurrentLocation();

    setState(() => _isLoadingLocation = false);

    if (location != null) {
      setState(() {
        _selectedLocation = location;
      });
      _mapController.move(location.toLatLng(), MapConstants.pickerZoom);
      widget.onLocationChanged?.call(_selectedLocation);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not get current location. Please enable location services.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation.toLatLng(),
                  initialZoom: widget.initialLocation != null
                      ? MapConstants.pickerZoom
                      : MapConstants.defaultZoom,
                  minZoom: MapConstants.minZoom,
                  maxZoom: MapConstants.maxZoom,
                  onTap: _onTap,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapConstants.tileUrl,
                    userAgentPackageName: MapConstants.userAgent,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation.toLatLng(),
                        width: 50,
                        height: 50,
                        child: const _MapPin(),
                      ),
                    ],
                  ),
                ],
              ),
              // Current location button
              if (widget.showCurrentLocationButton)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _buildCurrentLocationButton(),
                ),
              // Attribution
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    MapConstants.attribution,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.showCoordinates) ...[
          const SizedBox(height: 8),
          Text(
            'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}, '
            'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'monospace',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrentLocationButton() {
    return Material(
      color: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _isLoadingLocation ? null : _useCurrentLocation,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: _isLoadingLocation
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(
                  Icons.my_location,
                  color: AppColors.primary,
                  size: 22,
                ),
        ),
      ),
    );
  }
}

/// Animated map pin marker
class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 24),
        ),
        // Pin shadow/dot
        Container(
          width: 8,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
