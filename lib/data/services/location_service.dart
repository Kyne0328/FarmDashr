import 'dart:convert';
import 'dart:math';

import 'package:farmdashr/core/constants/map_constants.dart';
import 'package:farmdashr/data/models/geo_location.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Service for handling device location and map-related utilities.
class LocationService {
  /// Get current location of the user.
  Future<GeoLocation?> getCurrentLocation() async {
    try {
      final permission = await checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition();
      return GeoLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Check current location permission status.
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission from the user.
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Calculate distance between two points in kilometers.
  /// Uses the Haversine formula.
  double calculateDistanceKm(GeoLocation from, GeoLocation to) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(to.latitude - from.latitude);
    final dLon = _toRadians(to.longitude - from.longitude);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(from.latitude)) *
            cos(_toRadians(to.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Format distance for display (e.g., "2.5 km" or "500 m").
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  /// Open external maps app with directions to destination.
  Future<bool> openDirections(GeoLocation destination) async {
    // Google Maps URL
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}',
    );

    // Native Google Maps Intent (Android)
    final googleMapsNativeUrl = Uri.parse(
      'google.navigation:q=${destination.latitude},${destination.longitude}',
    );

    // Try native Android intent first (if available)
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (await canLaunchUrl(googleMapsNativeUrl)) {
        await launchUrl(googleMapsNativeUrl);
        return true;
      }
    }

    // Fallback to standard Google Maps URL
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      return true;
    }

    return false;
  }

  /// Search for an address using Nominatim (OpenStreetMap)
  /// Returns a list of suggestions with display name and coordinates
  Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    if (query.length < 3) return [];

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': MapConstants.userAgent},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => {
                'display_name': item['display_name'],
                'lat': double.parse(item['lat']),
                'lon': double.parse(item['lon']),
              },
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error searching address: $e');
      return [];
    }
  }

  /// Get address from coordinates (Reverse Geocoding)
  Future<String?> getAddressFromCoordinates(GeoLocation location) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${location.latitude}&lon=${location.longitude}&format=json',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': MapConstants.userAgent},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting address: $e');
      return null;
    }
  }
}
