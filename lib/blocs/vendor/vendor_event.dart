import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/user_profile.dart';

abstract class VendorEvent extends Equatable {
  const VendorEvent();

  @override
  List<Object?> get props => [];
}

class LoadVendors extends VendorEvent {
  const LoadVendors();
}

class VendorsUpdated extends VendorEvent {
  final List<UserProfile> vendors;

  const VendorsUpdated(this.vendors);

  @override
  List<Object?> get props => [vendors];
}

class SearchVendors extends VendorEvent {
  final String query;

  const SearchVendors(this.query);

  @override
  List<Object?> get props => [query];
}
