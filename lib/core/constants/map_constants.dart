import 'package:farmdashr/data/models/geo_location.dart';

/// Map configuration constants for OpenStreetMap integration.
class MapConstants {
  MapConstants._();

  /// Default map center (Tagum City, Philippines)
  static const defaultCenter = GeoLocation(
    latitude: 7.4482,
    longitude: 125.8094,
  );

  /// Zoom levels
  static const double defaultZoom = 13.0;
  static const double minZoom = 5.0;
  static const double maxZoom = 18.0;
  static const double markerZoom = 15.0;
  static const double pickerZoom = 16.0;

  /// OpenStreetMap tile server URL
  static const String tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Required attribution for OpenStreetMap
  static const String attribution = '© OpenStreetMap contributors';

  /// User agent for tile requests (required by OSM policy)
  static const String userAgent = 'FarmDashr/1.0';
}
