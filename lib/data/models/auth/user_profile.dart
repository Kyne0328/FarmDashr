import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/auth/pickup_location.dart';

/// User profile data model.
/// Follows Single Responsibility Principle - only handles user profile data.
class UserProfile extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? profilePictureUrl;
  final String? fcmToken;
  final UserType userType;
  final BusinessInfo? businessInfo;
  final DateTime memberSince;
  final NotificationPreferences notificationPreferences;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.profilePictureUrl,
    this.fcmToken,
    required this.userType,
    this.businessInfo,
    required this.memberSince,
    this.notificationPreferences = const NotificationPreferences(),
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    address,
    profilePictureUrl,
    fcmToken,
    userType,
    businessInfo,
    memberSince,
    notificationPreferences,
  ];

  /// Whether this user is a farmer
  bool get isFarmer => userType == UserType.farmer;

  /// Whether this user is a customer
  bool get isCustomer => userType == UserType.customer;

  /// Formatted member since date
  String get formattedMemberSince {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[memberSince.month - 1]} ${memberSince.year}';
  }

  /// Creates a copy with updated fields
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? profilePictureUrl,
    String? fcmToken,
    UserType? userType,
    BusinessInfo? businessInfo,
    DateTime? memberSince,
    NotificationPreferences? notificationPreferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      userType: userType ?? this.userType,
      businessInfo: businessInfo ?? this.businessInfo,
      memberSince: memberSince ?? this.memberSince,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
    );
  }

  /// Creates a UserProfile from Firestore document data
  factory UserProfile.fromJson(Map<String, dynamic> json, String id) {
    return UserProfile(
      id: id,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      fcmToken: json['fcmToken'] as String?,
      userType: UserType.values.firstWhere(
        (e) => e.name == json['userType'],
        orElse: () => UserType.customer,
      ),
      businessInfo: json['businessInfo'] != null
          ? BusinessInfo.fromJson(json['businessInfo'] as Map<String, dynamic>)
          : null,
      memberSince: json['memberSince'] != null
          ? (json['memberSince'] as dynamic).toDate()
          : DateTime.now(),
      notificationPreferences: json['notificationPreferences'] != null
          ? NotificationPreferences.fromJson(
              json['notificationPreferences'] as Map<String, dynamic>,
            )
          : const NotificationPreferences(),
    );
  }

  /// Converts UserProfile to Firestore document data
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'profilePictureUrl': profilePictureUrl,
      'fcmToken': fcmToken,
      'userType': userType.name,
      'businessInfo': businessInfo?.toJson(),
      'memberSince': memberSince,
      'notificationPreferences': notificationPreferences.toJson(),
    };
  }
}

/// Notification preferences
class NotificationPreferences extends Equatable {
  final bool pushEnabled; // Master toggle for push notifications

  // Customer Preferences
  final bool orderUpdates;

  // Farmer Preferences
  final bool newOrders; // "New Order Received"

  const NotificationPreferences({
    this.pushEnabled = true,
    this.orderUpdates = true,
    this.newOrders = true,
  });

  @override
  List<Object?> get props => [pushEnabled, orderUpdates, newOrders];

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      orderUpdates: json['orderUpdates'] as bool? ?? true,
      newOrders: json['newOrders'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushEnabled,
      'orderUpdates': orderUpdates,
      'newOrders': newOrders,
    };
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? orderUpdates,
    bool? newOrders,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      newOrders: newOrders ?? this.newOrders,
    );
  }
}

/// User type enumeration
enum UserType {
  farmer,
  customer;

  String get displayName {
    switch (this) {
      case UserType.farmer:
        return 'Farmer Account';
      case UserType.customer:
        return 'Customer Account';
    }
  }
}

/// Business information for farmer profiles
class BusinessInfo extends Equatable {
  final String farmName;
  final String? description;
  final String? businessLicense;
  final List<Certification> certifications;
  // Additional business profile fields
  final String? operatingHours; // e.g., "Mon-Sat: 8AM-5PM"
  final String? locationCoordinates; // For map display (future)
  final String? facebookUrl;
  final String? instagramUrl;
  final List<PickupLocation> pickupLocations;

  const BusinessInfo({
    required this.farmName,
    this.description,
    this.businessLicense,
    this.certifications = const [],
    this.operatingHours,
    this.locationCoordinates,
    this.facebookUrl,
    this.instagramUrl,
    this.pickupLocations = const [],
  });

  @override
  List<Object?> get props => [
    farmName,
    description,
    businessLicense,
    certifications,
    operatingHours,
    locationCoordinates,
    facebookUrl,
    instagramUrl,
    pickupLocations,
  ];

  factory BusinessInfo.fromJson(Map<String, dynamic> json) {
    return BusinessInfo(
      farmName: json['farmName'] as String? ?? '',
      description: json['description'] as String?,
      businessLicense: json['businessLicense'] as String?,
      certifications:
          (json['certifications'] as List<dynamic>?)
              ?.map((e) => Certification.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      operatingHours: json['operatingHours'] as String?,
      locationCoordinates: json['locationCoordinates'] as String?,
      facebookUrl: json['facebookUrl'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      pickupLocations:
          (json['pickupLocations'] as List<dynamic>?)
              ?.map((e) => PickupLocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmName': farmName,
      'description': description,
      'businessLicense': businessLicense,
      'certifications': certifications.map((e) => e.toJson()).toList(),
      'operatingHours': operatingHours,
      'locationCoordinates': locationCoordinates,
      'facebookUrl': facebookUrl,
      'instagramUrl': instagramUrl,
      'pickupLocations': pickupLocations.map((e) => e.toJson()).toList(),
    };
  }

  BusinessInfo copyWith({
    String? farmName,
    String? description,
    String? businessLicense,
    List<Certification>? certifications,
    String? operatingHours,
    String? locationCoordinates,
    String? facebookUrl,
    String? instagramUrl,
    List<PickupLocation>? pickupLocations,
  }) {
    return BusinessInfo(
      farmName: farmName ?? this.farmName,
      description: description ?? this.description,
      businessLicense: businessLicense ?? this.businessLicense,
      certifications: certifications ?? this.certifications,
      operatingHours: operatingHours ?? this.operatingHours,
      locationCoordinates: locationCoordinates ?? this.locationCoordinates,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      pickupLocations: pickupLocations ?? this.pickupLocations,
    );
  }
}

/// Certification model
class Certification extends Equatable {
  final String name;
  final CertificationType type;
  final DateTime? expiryDate;

  const Certification({
    required this.name,
    required this.type,
    this.expiryDate,
  });

  @override
  List<Object?> get props => [name, type, expiryDate];

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      name: json['name'] as String? ?? '',
      type: CertificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CertificationType.other,
      ),
      expiryDate: json['expiryDate'] != null
          ? (json['expiryDate'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'type': type.name, 'expiryDate': expiryDate};
  }

  bool get isValid => expiryDate == null || expiryDate!.isAfter(DateTime.now());
}

/// Certification type enumeration
enum CertificationType { organic, local, nonGmo, fairTrade, other }
