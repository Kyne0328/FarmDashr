import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/map_constants.dart';
import 'package:farmdashr/blocs/vendor/vendor.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/data/models/geo_location.dart';
import 'package:farmdashr/data/services/location_service.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';

/// Nearby Farms Map View - Shows farms on an interactive map
/// Allows customers to explore and discover local farms
class NearbyFarmsMapPage extends StatefulWidget {
  const NearbyFarmsMapPage({super.key});

  @override
  State<NearbyFarmsMapPage> createState() => _NearbyFarmsMapPageState();
}

class _NearbyFarmsMapPageState extends State<NearbyFarmsMapPage> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  GeoLocation? _userLocation;
  UserProfile? _selectedVendor;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    // Load vendors
    context.read<VendorBloc>().add(LoadVendors());
  }

  Future<void> _initializeLocation() async {
    try {
      final permission = await _locationService.checkPermission();
      final hasPermission =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      if (hasPermission) {
        final location = await _locationService.getCurrentLocation();
        if (mounted) {
          setState(() {
            _userLocation = location;
            _hasLocationPermission = true;
          });
          // Center map on user location
          if (location != null) {
            _mapController.move(location.toLatLng(), MapConstants.defaultZoom);
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _hasLocationPermission = false;
          });
        }
      }
    } catch (_) {
      // Ignore location errors
    }
  }

  Future<void> _requestLocationPermission() async {
    final permission = await _locationService.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _initializeLocation();
    }
  }

  void _centerOnUserLocation() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!.toLatLng(), MapConstants.defaultZoom);
    }
  }

  void _fitCameraToVendors(List<UserProfile> vendors) {
    // Collect all valid points
    final points = <LatLng>[];

    for (final vendor in vendors) {
      // Main location
      if (vendor.businessInfo?.locationCoordinates != null) {
        final loc = GeoLocation.tryParse(
          vendor.businessInfo!.locationCoordinates!,
        );
        if (loc != null) points.add(loc.toLatLng());
      }

      // Pickup locations
      if (vendor.businessInfo?.pickupLocations != null) {
        for (final pickup in vendor.businessInfo!.pickupLocations) {
          if (pickup.coordinates != null) {
            points.add(pickup.coordinates!.toLatLng());
          }
        }
      }
    }

    if (points.isNotEmpty) {
      List<LatLng> pointsToFit = points;

      // Apply Proximity Logic if User Location is available
      if (_userLocation != null) {
        final userLatLng = _userLocation!.toLatLng();

        // 1. Try to find farms within 50km
        final localPoints = points.where((p) {
          final distance = Geolocator.distanceBetween(
            userLatLng.latitude,
            userLatLng.longitude,
            p.latitude,
            p.longitude,
          );
          return distance <= 50000; // 50km in meters
        }).toList();

        if (localPoints.isNotEmpty) {
          pointsToFit = localPoints;
        } else {
          // 2. Fallback: Take closest 3 if none are within 50km
          points.sort((a, b) {
            final distA = Geolocator.distanceBetween(
              userLatLng.latitude,
              userLatLng.longitude,
              a.latitude,
              a.longitude,
            );
            final distB = Geolocator.distanceBetween(
              userLatLng.latitude,
              userLatLng.longitude,
              b.latitude,
              b.longitude,
            );
            return distA.compareTo(distB);
          });
          pointsToFit = points.take(3).toList();
        }

        // Always include user in the fit bounds so they see themselves relative to the farms
        pointsToFit.add(userLatLng);
      }

      // Calculate bounds
      double minLat = _minLat(pointsToFit);
      double maxLat = _maxLat(pointsToFit);
      double minLng = _minLng(pointsToFit);
      double maxLng = _maxLng(pointsToFit);

      // Add padding to bounds
      final bounds = LatLngBounds(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      );

      // Fit camera
      // We perform this slightly delayed to ensure map is ready
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
          );
        }
      });
    } else if (_userLocation != null) {
      // No vendors, but we have user location
      _centerOnUserLocation();
    }
  }

  double _minLat(List<LatLng> points) =>
      points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
  double _maxLat(List<LatLng> points) =>
      points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
  double _minLng(List<LatLng> points) =>
      points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
  double _maxLng(List<LatLng> points) =>
      points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

  void _onVendorTap(UserProfile vendor) {
    setState(() {
      _selectedVendor = vendor;
    });
  }

  void _viewVendorProducts(UserProfile vendor) {
    context.go('/customer-browse?tab=vendors');
  }

  List<Marker> _buildVendorMarkers(List<UserProfile> vendors) {
    final markers = <Marker>[];

    for (final vendor in vendors) {
      if (vendor.businessInfo == null) continue;

      final isSelected = _selectedVendor?.id == vendor.id;

      // 1. Add Main Farm Location Marker
      if (vendor.businessInfo!.locationCoordinates != null &&
          vendor.businessInfo!.locationCoordinates!.isNotEmpty) {
        final location = GeoLocation.tryParse(
          vendor.businessInfo!.locationCoordinates!,
        );
        if (location != null) {
          markers.add(
            Marker(
              point: location.toLatLng(),
              width: isSelected ? 60 : 50,
              height: isSelected ? 70 : 60,
              child: GestureDetector(
                onTap: () => _onVendorTap(vendor),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSelected ? 8 : 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.farmerPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isSelected
                                        ? AppColors.primary
                                        : AppColors.farmerPrimary)
                                    .withValues(alpha: 0.4),
                            blurRadius: isSelected ? 12 : 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                      child: Icon(
                        Icons.storefront,
                        color: Colors.white,
                        size: isSelected ? 24 : 20,
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
              ),
            ),
          );
        }
      }

      // 2. Add Pickup Location Markers
      for (final pickup in vendor.businessInfo!.pickupLocations) {
        if (pickup.coordinates != null) {
          markers.add(
            Marker(
              point: pickup.coordinates!.toLatLng(),
              width: isSelected ? 50 : 40, // Slightly smaller than main farm
              height: isSelected ? 60 : 50,
              child: GestureDetector(
                onTap: () => _onVendorTap(vendor),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSelected ? 6 : 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors
                                  .actionOrange, // Different color for pickup
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isSelected
                                        ? AppColors.primary
                                        : AppColors.actionOrange)
                                    .withValues(alpha: 0.4),
                            blurRadius: isSelected ? 10 : 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      child: Icon(
                        Icons.location_on, // Different icon
                        color: Colors.white,
                        size: isSelected ? 20 : 16,
                      ),
                    ),
                    const SizedBox(height: 2), // Small offset
                    Container(
                      width: isSelected ? 8 : 6,
                      height: isSelected ? 4 : 3,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Nearby Farms',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: BlocListener<VendorBloc, VendorState>(
        listener: (context, state) {
          if (state is VendorLoaded && state.vendors.isNotEmpty) {
            _fitCameraToVendors(state.vendors);
          }
        },
        child: BlocBuilder<VendorBloc, VendorState>(
          builder: (context, state) {
            if (state is VendorLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is VendorError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text('Error loading farms', style: AppTextStyles.body1),
                    const SizedBox(height: 16),
                    FarmButton(
                      label: 'Retry',
                      onPressed: () =>
                          context.read<VendorBloc>().add(LoadVendors()),
                      style: FarmButtonStyle.outline,
                    ),
                  ],
                ),
              );
            }

            final vendors = state is VendorLoaded
                ? state.vendors
                : <UserProfile>[];
            final vendorsWithLocation = vendors.where((v) {
              final hasMainLocation =
                  v.businessInfo?.locationCoordinates != null &&
                  v.businessInfo!.locationCoordinates!.isNotEmpty;
              final hasPickupLocation =
                  v.businessInfo?.pickupLocations.any(
                    (p) => p.coordinates != null,
                  ) ??
                  false;
              return hasMainLocation || hasPickupLocation;
            }).toList();

            return Stack(
              children: [
                // Map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        _userLocation?.toLatLng() ??
                        MapConstants.defaultCenter.toLatLng(),
                    initialZoom: MapConstants.defaultZoom,
                    minZoom: MapConstants.minZoom,
                    maxZoom: MapConstants.maxZoom,
                    onTap: (tapPosition, point) {
                      setState(() => _selectedVendor = null);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: MapConstants.tileUrl,
                      userAgentPackageName: MapConstants.userAgent,
                    ),
                    // User location marker
                    if (_userLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _userLocation!.toLatLng(),
                            width: 24,
                            height: 24,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.info,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.info.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    // Vendor markers
                    MarkerLayer(markers: _buildVendorMarkers(vendors)),
                  ],
                ),

                // Attribution
                Positioned(
                  left: 8,
                  bottom: _selectedVendor != null ? 180 : 100,
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

                // Stats bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    color: Colors.white,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.storefront,
                          size: 18,
                          color: AppColors.farmerPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${vendorsWithLocation.length} farm${vendorsWithLocation.length != 1 ? 's' : ''} on map',
                          style: AppTextStyles.body2,
                        ),
                        const Spacer(),
                        if (!_hasLocationPermission)
                          TextButton.icon(
                            onPressed: _requestLocationPermission,
                            icon: const Icon(Icons.location_on, size: 16),
                            label: const Text('Enable Location'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // My location button
                if (_hasLocationPermission)
                  Positioned(
                    right: 16,
                    bottom: _selectedVendor != null ? 190 : 110,
                    child: FloatingActionButton.small(
                      onPressed: _centerOnUserLocation,
                      backgroundColor: Colors.white,
                      child: const Icon(
                        Icons.my_location,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                // Selected vendor card
                if (_selectedVendor != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _buildVendorCard(_selectedVendor!),
                  ),

                // Empty state
                if (vendorsWithLocation.isEmpty && state is VendorLoaded)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 100,
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No farms with locations yet',
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check back soon as more farms add their locations',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVendorCard(UserProfile vendor) {
    final farmName = vendor.businessInfo?.farmName ?? 'Unknown Farm';
    final description = vendor.businessInfo?.description;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.farmerPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront,
                  color: AppColors.farmerPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farmName,
                      style: AppTextStyles.h4,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null && description.isNotEmpty)
                      Text(
                        description,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedVendor = null),
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FarmButton(
                  label: 'View Products',
                  onPressed: () => _viewVendorProducts(vendor),
                  style: FarmButtonStyle.primary,
                  backgroundColor: AppColors.farmerPrimary,
                  height: 44,
                ),
              ),
              const SizedBox(width: 12),
              if (vendor.businessInfo?.locationCoordinates != null)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton.outlined(
                    onPressed: () {
                      final location = GeoLocation.tryParse(
                        vendor.businessInfo!.locationCoordinates!,
                      );
                      if (location != null) {
                        _locationService.openDirections(location);
                      }
                    },
                    icon: const Icon(Icons.directions, size: 20),
                    style: IconButton.styleFrom(
                      side: const BorderSide(color: AppColors.farmerPrimary),
                      foregroundColor: AppColors.farmerPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
