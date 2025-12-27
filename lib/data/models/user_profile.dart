import 'package:equatable/equatable.dart';

/// User profile data model.
/// Follows Single Responsibility Principle - only handles user profile data.
class UserProfile extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? profilePictureUrl;
  final UserType userType;
  final BusinessInfo? businessInfo;
  final UserStats? stats;
  final DateTime memberSince;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.profilePictureUrl,
    required this.userType,
    this.businessInfo,
    this.stats,
    required this.memberSince,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    address,
    profilePictureUrl,
    userType,
    businessInfo,
    stats,
    memberSince,
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
    UserType? userType,
    BusinessInfo? businessInfo,
    UserStats? stats,
    DateTime? memberSince,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      userType: userType ?? this.userType,
      businessInfo: businessInfo ?? this.businessInfo,
      stats: stats ?? this.stats,
      memberSince: memberSince ?? this.memberSince,
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
      userType: UserType.values.firstWhere(
        (e) => e.name == json['userType'],
        orElse: () => UserType.customer,
      ),
      businessInfo: json['businessInfo'] != null
          ? BusinessInfo.fromJson(json['businessInfo'] as Map<String, dynamic>)
          : null,
      stats: json['stats'] != null
          ? UserStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      memberSince: json['memberSince'] != null
          ? (json['memberSince'] as dynamic).toDate()
          : DateTime.now(),
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
      'userType': userType.name,
      'businessInfo': businessInfo?.toJson(),
      'stats': stats?.toJson(),
      'memberSince': memberSince,
    };
  }

  /// Sample data for development/testing
  static UserProfile get sampleFarmer => UserProfile(
    id: '1',
    name: 'John Farmer',
    email: 'you@example.com',
    phone: '(555) 123-4567',
    address: 'Green Valley Farm, 123 Farm Road',
    userType: UserType.farmer,
    businessInfo: BusinessInfo.sample,
    stats: UserStats.sampleFarmerStats,
    memberSince: DateTime(2024, 1, 1),
  );
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
  final String? businessLicense;
  final List<Certification> certifications;

  const BusinessInfo({
    required this.farmName,
    this.businessLicense,
    this.certifications = const [],
  });

  @override
  List<Object?> get props => [farmName, businessLicense, certifications];

  factory BusinessInfo.fromJson(Map<String, dynamic> json) {
    return BusinessInfo(
      farmName: json['farmName'] as String? ?? '',
      businessLicense: json['businessLicense'] as String?,
      certifications:
          (json['certifications'] as List<dynamic>?)
              ?.map((e) => Certification.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'farmName': farmName,
      'businessLicense': businessLicense,
      'certifications': certifications.map((e) => e.toJson()).toList(),
    };
  }

  static BusinessInfo get sample => const BusinessInfo(
    farmName: 'Green Valley Farm',
    businessLicense: '#FRM-2024-001234',
    certifications: [
      Certification(name: 'Organic Certified', type: CertificationType.organic),
      Certification(name: 'Local Producer', type: CertificationType.local),
    ],
  );
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

/// User statistics
class UserStats extends Equatable {
  final double totalRevenue;
  final double revenueChange;
  final int productsSold;
  final double productsSoldChange;
  final int totalOrders;
  final int totalCustomers;

  const UserStats({
    required this.totalRevenue,
    required this.revenueChange,
    required this.productsSold,
    required this.productsSoldChange,
    required this.totalOrders,
    required this.totalCustomers,
  });

  @override
  List<Object?> get props => [
    totalRevenue,
    revenueChange,
    productsSold,
    productsSoldChange,
    totalOrders,
    totalCustomers,
  ];

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      revenueChange: (json['revenueChange'] as num?)?.toDouble() ?? 0.0,
      productsSold: json['productsSold'] as int? ?? 0,
      productsSoldChange:
          (json['productsSoldChange'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      totalCustomers: json['totalCustomers'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': totalRevenue,
      'revenueChange': revenueChange,
      'productsSold': productsSold,
      'productsSoldChange': productsSoldChange,
      'totalOrders': totalOrders,
      'totalCustomers': totalCustomers,
    };
  }

  String get formattedRevenue =>
      '\$${totalRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}';

  String get formattedRevenueChange =>
      '${revenueChange >= 0 ? '+' : ''}${revenueChange.toStringAsFixed(1)}%';

  String get formattedProductsSold => productsSold.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );

  String get formattedProductsSoldChange =>
      '${productsSoldChange >= 0 ? '+' : ''}${productsSoldChange.toStringAsFixed(1)}%';

  static UserStats get sampleFarmerStats => const UserStats(
    totalRevenue: 24850,
    revenueChange: 12.5,
    productsSold: 1247,
    productsSoldChange: 8.3,
    totalOrders: 156,
    totalCustomers: 89,
  );
}
