import 'package:flutter/material.dart';

class FilterProvider with ChangeNotifier {
  String _nameFilter = '';
  String _attributeFilter = '';
  String _unitFilter = ''; // Filtro para "unit"
  String? _selectedMap;
  String? _selectedSlot;
  String? _selectedRarity;
  List<String> _selectedRaces = [];
  List<String> _selectedAttributes =
      []; // Nueva lista para atributos seleccionados
  List<String> _selectedUnits = []; // Nueva lista para unidades seleccionadas

  String get nameFilter => _nameFilter;
  String get attributeFilter => _attributeFilter;
  String get unitFilter => _unitFilter; // Getter para "unitFilter"
  String? get selectedMap => _selectedMap;
  String? get selectedSlot => _selectedSlot;
  String? get selectedRarity => _selectedRarity;
  List<String> get selectedRaces => _selectedRaces;
  List<String> get selectedAttributes =>
      _selectedAttributes; // Getter para atributos seleccionados
  List<String> get selectedUnits =>
      _selectedUnits; // Getter para unidades seleccionadas

  void setNameFilter(String name) {
    if (_nameFilter != name) {
      _nameFilter = name;
      notifyListeners();
    }
  }

  void setAttributeFilter(String attribute) {
    if (_attributeFilter != attribute) {
      _attributeFilter = attribute;
      notifyListeners();
    }
  }

  void setUnitFilter(String unit) {
    if (_unitFilter != unit) {
      _unitFilter = unit;
      notifyListeners();
    }
  }

  // Método para agregar un atributo seleccionado
  void addSelectedAttribute(String attribute) {
    if (!_selectedAttributes.contains(attribute)) {
      _selectedAttributes.add(attribute);
      notifyListeners();
    }
  }

  // Método para eliminar un atributo seleccionado
  void removeSelectedAttribute(String attribute) {
    _selectedAttributes.remove(attribute);
    notifyListeners();
  }

  // Método para agregar una unidad seleccionada
  void addSelectedUnit(String unit) {
    if (!_selectedUnits.contains(unit)) {
      _selectedUnits.add(unit);
      notifyListeners();
    }
  }

  // Método para eliminar una unidad seleccionada
  void removeSelectedUnit(String unit) {
    _selectedUnits.remove(unit);
    notifyListeners();
  }

  void setSelectedMap(String? map) {
    if (_selectedMap != map) {
      _selectedMap = map;
      notifyListeners();
    }
  }

  void setSelectedSlot(String? slot) {
    if (_selectedSlot != slot) {
      _selectedSlot = slot;
      notifyListeners();
    }
  }

  void setSelectedRarity(String? rarity) {
    if (_selectedRarity != rarity) {
      _selectedRarity = rarity;
      notifyListeners();
    }
  }

  void setSelectedRaces(List<String> races) {
    _selectedRaces = races;
    notifyListeners();
  }

  void resetAttributeFilter() {
    _attributeFilter = ''; // Resetea el valor específico
    notifyListeners(); // Notifica para actualizar la UI
  }

  void resetUnitFilter() {
    _unitFilter = ''; // Resetea el valor específico
    notifyListeners(); // Notifica para actualizar la UI
  }

  void clearFilters() {
    _nameFilter = '';
    _attributeFilter = '';
    _unitFilter = '';
    _selectedMap = null;
    _selectedSlot = null;
    _selectedRarity = null;
    _selectedRaces = [];
    _selectedAttributes = []; // Limpiar atributos seleccionados
    _selectedUnits = []; // Limpiar unidades seleccionadas
    notifyListeners();
  }
}
