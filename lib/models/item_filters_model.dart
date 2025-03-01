import 'package:flutter/material.dart';

class FilterProvider with ChangeNotifier {
  String _nameFilter = '';
  String _attributeFilter = '';
  String _unitFilter = '';
  String? _selectedMap;
  String? _selectedSlot;
  String? _selectedRarity;
  List<String> _selectedRaces = [];
  List<String> _selectedAttributes = [];
  List<String> _selectedUnits = [];

  String get nameFilter => _nameFilter;
  String get attributeFilter => _attributeFilter;
  String get unitFilter => _unitFilter;
  String? get selectedMap => _selectedMap;
  String? get selectedSlot => _selectedSlot;
  String? get selectedRarity => _selectedRarity;
  List<String> get selectedRaces => _selectedRaces;
  List<String> get selectedAttributes => _selectedAttributes;
  List<String> get selectedUnits => _selectedUnits;

  void setNameFilter(String name) {
    _nameFilter = name;
    notifyListeners();
  }

  void setAttributeFilter(String attribute) {
    _attributeFilter = attribute;
    notifyListeners();
  }

  void setUnitFilter(String unit) {
    _unitFilter = unit;
    notifyListeners();
  }

  void addSelectedAttribute(String attribute) {
    if (!_selectedAttributes.contains(attribute)) {
      _selectedAttributes.add(attribute);
      notifyListeners();
    }
  }

  void removeSelectedAttribute(String attribute) {
    _selectedAttributes.remove(attribute);
    notifyListeners();
  }

  void addSelectedUnit(String unit) {
    if (!_selectedUnits.contains(unit)) {
      _selectedUnits.add(unit);
      notifyListeners();
    }
  }

  void removeSelectedUnit(String unit) {
    _selectedUnits.remove(unit);
    notifyListeners();
  }

  void setSelectedMap(String? map) {
    _selectedMap = map;
    notifyListeners();
  }

  void setSelectedSlot(String? slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  void setSelectedRarity(String? rarity) {
    _selectedRarity = rarity;
    notifyListeners();
  }

  void setSelectedRaces(List<String> races) {
    _selectedRaces = races;
    notifyListeners();
  }

  void resetAttributeFilter() {
    _attributeFilter = '';
    notifyListeners();
  }

  void resetUnitFilter() {
    _unitFilter = '';
    notifyListeners();
  }

  void clearFilters() {
    _nameFilter = '';
    _attributeFilter = '';
    _unitFilter = '';
    _selectedMap = null;
    _selectedSlot = null;
    _selectedRarity = null;
    _selectedRaces = [];
    _selectedAttributes = [];
    _selectedUnits = [];
    notifyListeners();
  }

  bool applyFilters(
      String name,
      String attribute,
      String unit,
      String map,
      String slot,
      String rarity,
      List<String> races,
      List<String> attributes,
      List<String> units) {
    bool matches = true;

    // Filtros de texto
    if (_nameFilter.isNotEmpty &&
        !name.toLowerCase().contains(_nameFilter.toLowerCase())) {
      matches = false;
    }

    // Filtros de atributo y unidad
    if (_attributeFilter.isNotEmpty &&
        !attribute.toLowerCase().contains(_attributeFilter.toLowerCase())) {
      matches = false;
    }

    if (_unitFilter.isNotEmpty &&
        !unit.toLowerCase().contains(_unitFilter.toLowerCase())) {
      matches = false;
    }

    // Filtros de opciones seleccionadas
    if (_selectedMap != null && _selectedMap != map) {
      matches = false;
    }

    if (_selectedSlot != null && _selectedSlot != slot) {
      matches = false;
    }

    if (_selectedRarity != null && _selectedRarity != rarity) {
      matches = false;
    }

    // Filtros por lista de razas, atributos y unidades seleccionadas
    if (_selectedRaces.isNotEmpty &&
        !_selectedRaces.any((race) => races.contains(race))) {
      matches = false;
    }

    if (_selectedAttributes.isNotEmpty &&
        !_selectedAttributes
            .any((attribute) => attributes.contains(attribute))) {
      matches = false;
    }

    if (_selectedUnits.isNotEmpty &&
        !_selectedUnits.any((unit) => units.contains(unit))) {
      matches = false;
    }

    return matches;
  }
}
