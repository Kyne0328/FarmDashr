import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/data/repositories/vendor_repository.dart';
import 'package:farmdashr/blocs/vendor/vendor_event.dart';
import 'package:farmdashr/blocs/vendor/vendor_state.dart';
import 'package:farmdashr/data/models/user_profile.dart';

class VendorBloc extends Bloc<VendorEvent, VendorState> {
  final VendorRepository _repository;
  StreamSubscription<List<UserProfile>>? _vendorsSubscription;

  VendorBloc({VendorRepository? repository})
    : _repository = repository ?? VendorRepository(),
      super(const VendorInitial()) {
    on<LoadVendors>(_onLoadVendors);
    on<VendorsUpdated>(_onVendorsUpdated);
    on<SearchVendors>(_onSearchVendors);
  }

  Future<void> _onLoadVendors(
    LoadVendors event,
    Emitter<VendorState> emit,
  ) async {
    emit(const VendorLoading());

    await _vendorsSubscription?.cancel();
    _vendorsSubscription = _repository.watchVendors().listen((vendors) {
      add(VendorsUpdated(vendors));
    });
  }

  void _onVendorsUpdated(VendorsUpdated event, Emitter<VendorState> emit) {
    emit(VendorLoaded(vendors: event.vendors));
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
