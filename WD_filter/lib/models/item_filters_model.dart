import 'package:flutter/material.dart';

class FilterProvider extends ChangeNotifier {
  String _nameFilter = '';
  String _attributeFilter = '';
  String? _selectedMap;
  List<String> _selectedRaces = [];
  String? _selectedSlot;
  String? _selectedRarity;

  String get nameFilter => _nameFilter;
  String get attributeFilter => _attributeFilter;
  String? get selectedMap => _selectedMap;
  List<String> get selectedRaces => _selectedRaces;
  String? get selectedSlot => _selectedSlot;
  String? get selectedRarity => _selectedRarity;

  void setNameFilter(String value) {
    _nameFilter = value;
    notifyListeners();
  }

  void setAttributeFilter(String value) {
    _attributeFilter = value;
    notifyListeners();
  }

  void setSelectedMap(String? value) {
    _selectedMap = value;
    notifyListeners();
  }

  void setSelectedRaces(List<String> value) {
    _selectedRaces = value;
    notifyListeners();
  }

  void setSelectedSlot(String? value) {
    _selectedSlot = value;
    notifyListeners();
  }

  void setSelectedRarity(String? value) {
    _selectedRarity = value;
    notifyListeners();
  }

  void clearFilters() {
    _nameFilter = '';
    _attributeFilter = '';
    _selectedMap = null;
    _selectedRaces = [];
    _selectedSlot = null;
    _selectedRarity = null;
    notifyListeners();
  }
}
