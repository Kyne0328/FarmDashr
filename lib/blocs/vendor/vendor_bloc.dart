import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/data/repositories/auth/vendor_repository.dart';
import 'package:farmdashr/blocs/vendor/vendor_event.dart';
import 'package:farmdashr/blocs/vendor/vendor_state.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/core/error/failures.dart';

class VendorBloc extends Bloc<VendorEvent, VendorState> {
  final VendorRepository _repository;
  StreamSubscription<List<UserProfile>>? _vendorsSubscription;

  VendorBloc({required VendorRepository repository})
    : _repository = repository,
      super(const VendorInitial()) {
    on<LoadVendors>(_onLoadVendors);
    on<VendorsUpdated>(_onVendorsUpdated);
    on<SearchVendors>(_onSearchVendors);
    on<VendorErrorReceived>(_onVendorErrorReceived);
  }

  Future<void> _onLoadVendors(
    LoadVendors event,
    Emitter<VendorState> emit,
  ) async {
    emit(VendorLoading(excludeUserId: event.excludeUserId));

    await _vendorsSubscription?.cancel();
    _vendorsSubscription = _repository.watchVendors().listen(
      (vendors) {
        add(VendorsUpdated(vendors));
      },
      onError: (error) {
        final message = error is Failure ? error.message : error.toString();
        add(VendorErrorReceived(message));
      },
    );
  }

  void _onVendorsUpdated(VendorsUpdated event, Emitter<VendorState> emit) {
    final currentState = state;
    // Determine exclusion ID from current state if available.
    // If state was loading, we should have it.
    String? excludeUserId;
    if (currentState is VendorLoading) {
      excludeUserId = currentState.excludeUserId;
    } else if (currentState is VendorLoaded) {
      excludeUserId = currentState.excludeUserId;
    }

    // Filter out the excluded user
    var displayVendors = event.vendors;
    if (excludeUserId != null) {
      displayVendors = displayVendors
          .where((v) => v.id != excludeUserId)
          .toList();
    }

    if (currentState is VendorLoaded && currentState.searchQuery.isNotEmpty) {
      final query = currentState.searchQuery.toLowerCase();
      final filtered = displayVendors.where((vendor) {
        return vendor.name.toLowerCase().contains(query) ||
            (vendor.businessInfo?.farmName.toLowerCase().contains(query) ??
                false);
      }).toList();
      emit(
        currentState.copyWith(
          vendors: displayVendors,
          filteredVendors: filtered,
          excludeUserId: excludeUserId,
        ),
      );
    } else {
      emit(VendorLoaded(vendors: displayVendors, excludeUserId: excludeUserId));
    }
  }

  void _onVendorErrorReceived(
    VendorErrorReceived event,
    Emitter<VendorState> emit,
  ) {
    emit(VendorError(event.message));
  }

  void _onSearchVendors(SearchVendors event, Emitter<VendorState> emit) {
    final currentState = state;
    if (currentState is VendorLoaded) {
      if (event.query.isEmpty) {
        emit(currentState.copyWith(searchQuery: '', filteredVendors: []));
      } else {
        final query = event.query.toLowerCase();
        final filtered = currentState.vendors.where((vendor) {
          return vendor.name.toLowerCase().contains(query) ||
              (vendor.businessInfo?.farmName.toLowerCase().contains(query) ??
                  false);
        }).toList();
        emit(
          currentState.copyWith(
            searchQuery: event.query,
            filteredVendors: filtered,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _vendorsSubscription?.cancel();
    return super.close();
  }
}
