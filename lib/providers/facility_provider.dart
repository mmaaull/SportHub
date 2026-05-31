import 'package:flutter/material.dart';

import '../models/facility_model.dart';
import '../services/facility_service.dart';

class FacilityProvider extends ChangeNotifier {
  final FacilityService _facilityService = FacilityService();

  List<FacilityModel> _facilities = [];
  List<FacilityModel> _filteredFacilities = [];

  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedSportType = 'Semua';
  String _selectedCampus = 'Semua';
  String _sortBy = 'Terbaru';

  List<FacilityModel> get facilities => _facilities;
  List<FacilityModel> get filteredFacilities => _filteredFacilities;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String get selectedSportType => _selectedSportType;
  String get selectedCampus => _selectedCampus;
  String get sortBy => _sortBy;

  List<String> get sportTypes {
    final types = _facilities.map((facility) => facility.sportType).toSet().toList();
    types.sort();
    return ['Semua', ...types];
  }

  List<String> get campuses {
    final campusList = _facilities.map((facility) => facility.campus).toSet().toList();
    campusList.sort();
    return ['Semua', ...campusList];
  }

  Stream<List<FacilityModel>> getFacilitiesStream() {
    return _facilityService.getFacilitiesStream();
  }

  Future<void> loadFacilities() async {
    _setLoading(true);
    _clearError();

    try {
      _facilities = await _facilityService.getAllFacilities();
      _applyFilterAndSort();
    } catch (e) {
      _setError(_cleanErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<FacilityModel?> getFacilityById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      return await _facilityService.getFacilityById(id);
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addFacility(FacilityModel facility) async {
    _setLoading(true);
    _clearError();

    try {
      await _facilityService.addFacility(facility);
      await loadFacilities();
      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateFacility(FacilityModel facility) async {
    _setLoading(true);
    _clearError();

    try {
      await _facilityService.updateFacility(facility);
      await loadFacilities();
      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteFacility(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _facilityService.deleteFacility(id);
      await loadFacilities();
      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> seedInitialFacilities() async {
    _setLoading(true);
    _clearError();

    try {
      await _facilityService.seedInitialFacilities();
      await loadFacilities();
      return true;
    } catch (e) {
      _setError(_cleanErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void searchFacilities(String query) {
    _searchQuery = query;
    _applyFilterAndSort();
  }

  void filterBySportType(String sportType) {
    _selectedSportType = sportType;
    _applyFilterAndSort();
  }

  void filterByCampus(String campus) {
    _selectedCampus = campus;
    _applyFilterAndSort();
  }

  void sortFacilities(String sortBy) {
    _sortBy = sortBy;
    _applyFilterAndSort();
  }

  void resetFilter() {
    _searchQuery = '';
    _selectedSportType = 'Semua';
    _selectedCampus = 'Semua';
    _sortBy = 'Terbaru';
    _applyFilterAndSort();
  }

  void _applyFilterAndSort() {
    List<FacilityModel> result = List.from(_facilities);

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();

      result = result.where((facility) {
        return facility.name.toLowerCase().contains(query) ||
            facility.sportType.toLowerCase().contains(query) ||
            facility.campus.toLowerCase().contains(query) ||
            facility.location.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedSportType != 'Semua') {
      result = result.where((facility) {
        return facility.sportType == _selectedSportType;
      }).toList();
    }

    if (_selectedCampus != 'Semua') {
      result = result.where((facility) {
        return facility.campus == _selectedCampus;
      }).toList();
    }

    switch (_sortBy) {
      case 'Nama A-Z':
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Nama Z-A':
        result.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Terlama':
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Terbaru':
      default:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    _filteredFacilities = result;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _cleanErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}