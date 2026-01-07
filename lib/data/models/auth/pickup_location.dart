import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/geo_location.dart';

/// Represents a physical location where customers can pick up orders
class PickupLocation extends Equatable {
  final String id; // Unique ID for the location
  final String name; // e.g., "Farm Stand", "Downtown Market"
  final String address;
  final GeoLocation? coordinates; // GPS coordinates for map display
  final String notes; // Instructions like "Park behind the barn"
  final List<PickupWindow> availableWindows;

  const PickupLocation({
    required this.id,
    required this.name,
    required this.address,
    this.coordinates,
    this.notes = '',
    this.availableWindows = const [],
  });

  @override
  List<Object?> get props => [
    id,
    name,
    address,
    coordinates,
    notes,
    availableWindows,
  ];

  /// Whether this location has GPS coordinates set
  bool get hasCoordinates => coordinates != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'coordinates': coordinates?.toJson(),
      'notes': notes,
      'availableWindows': availableWindows.map((w) => w.toJson()).toList(),
    };
  }

  factory PickupLocation.fromJson(Map<String, dynamic> json) {
    return PickupLocation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      coordinates: json['coordinates'] != null
          ? GeoLocation.fromJson(json['coordinates'] as Map<String, dynamic>)
          : null,
      notes: json['notes'] as String? ?? '',
      availableWindows:
          (json['availableWindows'] as List<dynamic>?)
              ?.map((e) => PickupWindow.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  PickupLocation copyWith({
    String? id,
    String? name,
    String? address,
    GeoLocation? coordinates,
    String? notes,
    List<PickupWindow>? availableWindows,
  }) {
    return PickupLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
      notes: notes ?? this.notes,
      availableWindows: availableWindows ?? this.availableWindows,
    );
  }
}

/// Represents a time window on a specific day
class PickupWindow extends Equatable {
  final int dayOfWeek; // 1 = Monday, 7 = Sunday (DateTime standard)
  final int startHour; // 0-23
  final int startMinute; // 0-59
  final int endHour; // 0-23
  final int endMinute; // 0-59

  const PickupWindow({
    required this.dayOfWeek,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  @override
  List<Object?> get props => [
    dayOfWeek,
    startHour,
    startMinute,
    endHour,
    endMinute,
  ];

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
    };
  }

  factory PickupWindow.fromJson(Map<String, dynamic> json) {
    return PickupWindow(
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 1,
      startHour: (json['startHour'] as num?)?.toInt() ?? 9,
      startMinute: (json['startMinute'] as num?)?.toInt() ?? 0,
      endHour: (json['endHour'] as num?)?.toInt() ?? 17,
      endMinute: (json['endMinute'] as num?)?.toInt() ?? 0,
    );
  }

  String get dayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return days[dayOfWeek - 1];
    }
    return 'Unknown';
  }

  String get formattedTimeRange {
    final start =
        '${_formatHour(startHour)}:${startMinute.toString().padLeft(2, '0')} ${_getAmPm(startHour)}';
    final end =
        '${_formatHour(endHour)}:${endMinute.toString().padLeft(2, '0')} ${_getAmPm(endHour)}';
    return '$start - $end';
  }

  String _getAmPm(int hour) => hour >= 12 ? 'PM' : 'AM';
  int _formatHour(int hour) {
    if (hour == 0) return 12;
    if (hour > 12) return hour - 12;
    return hour;
  }
}
