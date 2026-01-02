import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/user_profile.dart';

abstract class VendorState extends Equatable {
  const VendorState();

  @override
  List<Object?> get props => [];
}

class VendorInitial extends VendorState {
  const VendorInitial();
}

class VendorLoading extends VendorState {
  const VendorLoading();
}

class VendorLoaded extends VendorState {
  final List<UserProfile> vendors;
  final List<UserProfile> filteredVendors;
  final String searchQuery;

  const VendorLoaded({
    required this.vendors,
    this.filteredVendors = const [],
    this.searchQuery = '',
  });

  /// Get the vendors to display (filtered if searching, all otherwise).
  List<UserProfile> get displayVendors =>
      searchQuery.isEmpty ? vendors : filteredVendors;

  @override
  List<Object?> get props => [vendors, filteredVendors, searchQuery];

  VendorLoaded copyWith({
    List<UserProfile>? vendors,
    List<UserProfile>? filteredVendors,
    String? searchQuery,
  }) {
    return VendorLoaded(
      vendors: vendors ?? this.vendors,
      filteredVendors: filteredVendors ?? this.filteredVendors,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class VendorError extends VendorState {
  final String message;

  const VendorError(this.message);

  @override
  List<Object?> get props => [message];
}
