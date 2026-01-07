import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/map_constants.dart';
import 'package:farmdashr/data/models/geo_location.dart';
import 'package:farmdashr/data/services/location_service.dart';

/// Model for map markers with location and metadata.
class MapMarkerData {
  final String id;
  final GeoLocation location;
  final String title;
  final String? subtitle;
  final Color color;

  const MapMarkerData({
    required this.id,
    required this.location,
    required this.title,
    this.subtitle,
    this.color = AppColors.primary,
  });
}

/// Read-only map display widget for showing one or more locations.
/// Used to display pickup locations to customers.
class MapDisplayWidget extends StatefulWidget {
  /// List of markers to display on the map.
  final List<MapMarkerData> markers;

  /// Height of the map widget.
  final double height;

  /// Whether to allow zoom and pan interactions.
  final bool interactive;

  /// Whether to show "Get Directions" button for markers.
  final bool showDirectionsButton;

  /// Callback when a marker is tapped.
  final ValueChanged<MapMarkerData>? onMarkerTap;

  /// Optional: highlight a specific marker by ID.
  final String? selectedMarkerId;

  /// Whether to show the info card for the selected marker.
  final bool showSelectedMarkerInfo;

  const MapDisplayWidget({
    super.key,
    required this.markers,
    this.height = 200,
    this.interactive = true,
    this.showDirectionsButton = true,
    this.onMarkerTap,
    this.selectedMarkerId,
    this.showSelectedMarkerInfo = true,
  });

  @override
  State<MapDisplayWidget> createState() => _MapDisplayWidgetState();
}

class _MapDisplayWidgetState extends State<MapDisplayWidget> {
  final LocationService _locationService = LocationService();
  MapMarkerData? _selectedMarker;

  @override
  void initState() {
    super.initState();
    // Pre-select marker if selectedMarkerId is provided
    if (widget.selectedMarkerId != null) {
      _selectedMarker = widget.markers.firstWhere(
        (m) => m.id == widget.selectedMarkerId,
        orElse: () => widget.markers.first,
      );
    }
  }

  @override
  void didUpdateWidget(MapDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMarkerId != oldWidget.selectedMarkerId) {
      if (widget.selectedMarkerId != null) {
        setState(() {
          _selectedMarker = widget.markers.firstWhere(
            (m) => m.id == widget.selectedMarkerId,
            orElse: () => widget.markers.first,
          );
        });
      }
    }
  }

  LatLngBounds _calculateBounds() {
    if (widget.markers.isEmpty) {
      return LatLngBounds(
        MapConstants.defaultCenter.toLatLng(),
        MapConstants.defaultCenter.toLatLng(),
      );
    }

    if (widget.markers.length == 1) {
      final point = widget.markers.first.location.toLatLng();
      // Create a small bound around single point
      return LatLngBounds(
        LatLng(point.latitude - 0.01, point.longitude - 0.01),
        LatLng(point.latitude + 0.01, point.longitude + 0.01),
      );
    }

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final marker in widget.markers) {
      if (marker.location.latitude < minLat) {
        minLat = marker.location.latitude;
      }
      if (marker.location.latitude > maxLat) {
        maxLat = marker.location.latitude;
      }
      if (marker.location.longitude < minLng) {
        minLng = marker.location.longitude;
      }
      if (marker.location.longitude > maxLng) {
        maxLng = marker.location.longitude;
      }
    }

    // Add padding
    const padding = 0.01;
    return LatLngBounds(
      LatLng(minLat - padding, minLng - padding),
      LatLng(maxLat + padding, maxLng + padding),
    );
  }

  void _onMarkerTap(MapMarkerData marker) {
    setState(() {
      _selectedMarker = marker;
    });
    widget.onMarkerTap?.call(marker);
  }

  Future<void> _openDirections(MapMarkerData marker) async {
    await _locationService.openDirections(marker.location);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.markers.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.containerLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 8),
              Text(
                'No locations to display',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final bounds = _calculateBounds();

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
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(32),
                  ),
                  minZoom: MapConstants.minZoom,
                  maxZoom: MapConstants.maxZoom,
                  interactionOptions: InteractionOptions(
                    flags: widget.interactive
                        ? InteractiveFlag.all
                        : InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapConstants.tileUrl,
                    userAgentPackageName: MapConstants.userAgent,
                  ),
                  MarkerLayer(
                    markers: widget.markers.map((marker) {
                      final isSelected = _selectedMarker?.id == marker.id;
                      return Marker(
                        point: marker.location.toLatLng(),
                        width: isSelected ? 60 : 50,
                        height: isSelected ? 60 : 50,
                        child: GestureDetector(
                          onTap: () => _onMarkerTap(marker),
                          child: _MarkerIcon(
                            color: marker.color,
                            isSelected: isSelected,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
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
        // Selected marker info
        if (widget.showSelectedMarkerInfo && _selectedMarker != null) ...[
          const SizedBox(height: 12),
          _buildSelectedMarkerInfo(_selectedMarker!),
        ],
      ],
    );
  }

  Widget _buildSelectedMarkerInfo(MapMarkerData marker) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: marker.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on, color: marker.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  marker.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (marker.subtitle != null)
                  Text(
                    marker.subtitle!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (widget.showDirectionsButton)
            IconButton(
              onPressed: () => _openDirections(marker),
              icon: const Icon(Icons.directions),
              color: AppColors.primary,
              tooltip: 'Get directions',
            ),
        ],
      ),
    );
  }
}

class _MarkerIcon extends StatelessWidget {
  final Color color;
  final bool isSelected;

  const _MarkerIcon({required this.color, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isSelected ? 6 : 4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
            ),
            child: Icon(
              Icons.location_on,
              color: Colors.white,
              size: isSelected ? 28 : 24,
            ),
          ),
          Container(
            width: isSelected ? 10 : 8,
            height: isSelected ? 5 : 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
