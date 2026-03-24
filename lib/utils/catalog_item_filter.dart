import 'package:worldshift_assistant/data/data.dart';
import 'package:worldshift_assistant/data/item.dart';
import 'package:worldshift_assistant/models/item_filters_model.dart';

/// Misma lógica que el listado de ítems; opcionalmente fija el slot (equip Builder).
bool catalogItemMatchesFilters({
  required Item item,
  required FilterProvider filterProvider,
  Map<int, Set<String>> resolvedMapNamesByItem = const {},
  /// Si no es null, solo cuentan ítems de ese slot y se ignora [filterProvider.selectedSlot].
  String? lockedSlotKey,
  /// Si no es null, solo esa raza y se ignora [filterProvider.selectedRaces] (p. ej. picker del Builder).
  String? lockedRaceKey,
}) {
  final itemData = item.toMap();
  final name = item.name;
  final rarity = item.rarity;

  if (lockedSlotKey != null) {
    if (item.slot != lockedSlotKey) {
      return false;
    }
  }

  if (filterProvider.nameFilter.isNotEmpty &&
      !name.toLowerCase().contains(filterProvider.nameFilter.toLowerCase())) {
    return false;
  }

  if (filterProvider.attributeFilter.isNotEmpty) {
    final attributes = itemData['attributes'];
    if (attributes is Map) {
      final hasAttribute = attributes.values.any((unitMap) {
        if (unitMap is Map<String, dynamic>) {
          return unitMap.keys.any((attributeKey) {
            final filterValue = filterProvider.attributeFilter.toLowerCase();
            final attributeMatch = attributeList.firstWhere(
              (attribute) =>
                  attribute['value']?.toLowerCase() == filterValue,
              orElse: () => <String, String>{},
            );
            return attributeMatch.isNotEmpty &&
                attributeMatch['key']?.toLowerCase() ==
                    attributeKey.toLowerCase();
          });
        }
        return false;
      });
      if (!hasAttribute) {
        return false;
      }
    }
  }

  if (filterProvider.unitFilter.isNotEmpty) {
    final normalizedAttributes =
        _normalizeCatalogFilterValue(itemData['attributes'].toString());
    final normalizedUnitFilter =
        _normalizeCatalogFilterValue(filterProvider.unitFilter);
    if (!normalizedAttributes.contains(normalizedUnitFilter)) {
      return false;
    }
  }

  if (filterProvider.selectedMap != null) {
    final selectedMap = filterProvider.selectedMap!;
    final directMap = '${itemData['map'] ?? ''}'.trim();
    final itemId = itemData['id'];
    final resolvedMaps = itemId is int
        ? (resolvedMapNamesByItem[itemId] ?? const <String>{})
        : const <String>{};
    if (directMap != selectedMap && !resolvedMaps.contains(selectedMap)) {
      return false;
    }
  }

  if (lockedRaceKey != null) {
    if (item.race != lockedRaceKey) {
      return false;
    }
  } else if (filterProvider.selectedRaces.isNotEmpty &&
      !filterProvider.selectedRaces.contains(itemData['race'])) {
    return false;
  }

  if (lockedSlotKey == null && filterProvider.selectedSlot != null) {
    if (itemData['slot'] != filterProvider.selectedSlot) {
      return false;
    }
  }

  if (filterProvider.selectedRarity != null &&
      rarity != filterProvider.selectedRarity) {
    return false;
  }

  return true;
}

String _normalizeCatalogFilterValue(String value) {
  return value.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '').toLowerCase();
}
