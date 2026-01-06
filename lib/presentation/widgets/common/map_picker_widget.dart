import 'dart:async';

import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/map_constants.dart';
import 'package:farmdashr/data/models/geo_location.dart';
import 'package:farmdashr/data/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

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

  final TextEditingController _addressController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _mapController.dispose();
    _addressController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd) {
      final center = _mapController.camera.center;
      setState(() {
        _selectedLocation = GeoLocation.fromLatLng(center);
      });

      // Debounce the callback and reverse geocoding
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
        widget.onLocationChanged?.call(_selectedLocation);

        // Reverse geocoding
        final address = await _locationService.getAddressFromCoordinates(
          _selectedLocation,
        );
        if (mounted && address != null) {
          // Update text field without triggering search (since onChanged is not called programmatically)
          _addressController.text = address;
        }
      });
    }
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

  void _onAddressSelected(Map<String, dynamic> prediction) {
    final lat = prediction['lat'] as double;
    final lng = prediction['lon'] as double;
    final location = GeoLocation(latitude: lat, longitude: lng);

    setState(() {
      _selectedLocation = location;
    });
    _mapController.move(location.toLatLng(), MapConstants.pickerZoom);
    widget.onLocationChanged?.call(_selectedLocation);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Address Search Bar
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _AddressSearchField(
            controller: _addressController,
            onSelected: _onAddressSelected,
          ),
        ),

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
                  onMapEvent: _onMapEvent,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapConstants.tileUrl,
                    userAgentPackageName: MapConstants.userAgent,
                  ),
                  // Removed MarkerLayer since pin is now fixed at center
                ],
              ),

              // Center Fixed Pin
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24), // Offset for pin point
                  child: _MapPin(),
                ),
              ),

              // Current location button
              if (widget.showCurrentLocationButton)
                Positioned(
                  right: 12,
                  bottom: 34, // Moved up slightly for attribution
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
            'Location: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
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
        // Space to align pin tip with center
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AddressSearchField extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onSelected;
  final TextEditingController? controller;

  const _AddressSearchField({required this.onSelected, this.controller});

  @override
  State<_AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<_AddressSearchField> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();
  final _locationService = LocationService();
  Timer? _debounceTimer;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.length < 3) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);
      final results = await _locationService.searchAddress(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search address...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      _controller.clear();
                      // Don't clear suggestions immediately to allow re-selection or edit
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: _onSearchChanged,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  title: Text(
                    suggestion['display_name'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () {
                    widget.onSelected(suggestion);
                    setState(() => _suggestions = []);
                    _controller.text = suggestion['display_name'];
                    _focusNode.unfocus();
                  },
                  dense: true,
                  leading: const Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
