import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Represents geographic coordinates (latitude and longitude).
/// Used for map markers, pickup locations, and farm locations.
class GeoLocation extends Equatable {
  final double latitude;
  final double longitude;

  const GeoLocation({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];

  /// Creates a GeoLocation from a coordinate string "lat,lng"
  factory GeoLocation.fromString(String coords) {
    final parts = coords.split(',');
    if (parts.length != 2) {
      throw ArgumentError('Invalid coordinate string: $coords');
    }
    return GeoLocation(
      latitude: double.parse(parts[0].trim()),
      longitude: double.parse(parts[1].trim()),
    );
  }

  /// Converts to coordinate string "lat,lng"
  String toCoordinateString() => '$latitude,$longitude';

  /// Converts to LatLng for flutter_map
  LatLng toLatLng() => LatLng(latitude, longitude);

  /// Creates from LatLng (flutter_map)
  factory GeoLocation.fromLatLng(LatLng latLng) =>
      GeoLocation(latitude: latLng.latitude, longitude: latLng.longitude);

  /// JSON serialization
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  /// JSON deserialization
  factory GeoLocation.fromJson(Map<String, dynamic> json) => GeoLocation(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );

  /// Creates a copy with updated fields
  GeoLocation copyWith({double? latitude, double? longitude}) => GeoLocation(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
  );
}
