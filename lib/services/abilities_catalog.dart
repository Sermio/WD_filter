import 'package:worldshift_assistant/models/catalog_ability.dart';
import 'package:worldshift_assistant/models/game_unit.dart';

class _AggBucket {
  _AggBucket({
    required this.name,
    required this.isActive,
    this.isStatusEffect = false,
    this.isDebuff,
  });

  final String name;
  final bool isActive;
  final bool isStatusEffect;
  final bool? isDebuff;
  final Set<String> seenUnitIds = {};
  final List<AbilityUnitRef> usedByUnits = [];
  String? description;
  String? iconAtlas;
  int? iconCol;
  int? iconRow;
  String? iconAssetPathOverride;

  void addUnit(GameUnit unit) {
    if (!seenUnitIds.add(unit.id)) {
      return;
    }
    usedByUnits.add(
      AbilityUnitRef(
        unitId: unit.id,
        displayName: unit.displayName ?? unit.id,
        raceFolder: unit.raceFolder,
        race: unit.race,
        mainIconRow: unit.mainIconRow,
        mainIconCol: unit.mainIconCol,
        conversationIconRow: unit.conversationIconRow,
        conversationIconCol: unit.conversationIconCol,
        unitIconClass: unit.unitIconClass,
      ),
    );
  }

  bool get _hasAnyIcon =>
      (iconAssetPathOverride != null && iconAssetPathOverride!.isNotEmpty) ||
      (iconAtlas != null && iconCol != null && iconRow != null);

  void mergeFromAbility(GameUnitAbility a) {
    final d = a.description?.trim();
    if (d != null && d.isNotEmpty) {
      if (description == null || d.length > description!.length) {
        description = d;
      }
    }
    if (!_hasAnyIcon) {
      if (a.iconAssetPathOverride != null &&
          a.iconAssetPathOverride!.isNotEmpty) {
        iconAssetPathOverride = a.iconAssetPathOverride;
      }
      if (a.hasIcon) {
        iconAtlas = a.iconAtlas;
        iconCol = a.iconCol;
        iconRow = a.iconRow;
      }
    }
  }

  void mergeFromStatusEffect(GameUnitStatusEffect effect) {
    final d = effect.description?.trim();
    if (d != null && d.isNotEmpty) {
      if (description == null || d.length > description!.length) {
        description = d;
      }
    }
    if (!_hasAnyIcon) {
      if (effect.iconAssetPathOverride != null &&
          effect.iconAssetPathOverride!.isNotEmpty) {
        iconAssetPathOverride = effect.iconAssetPathOverride;
      }
      if (effect.hasIcon) {
        iconAtlas = effect.iconAtlas;
        iconCol = effect.iconCol;
        iconRow = effect.iconRow;
      }
    }
  }

  CatalogAbility toCatalogAbility() {
    usedByUnits.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
    );
    return CatalogAbility(
      name: name,
      isActive: isActive,
      isStatusEffect: isStatusEffect,
      isDebuff: isDebuff,
      description: description,
      iconAtlas: iconAtlas,
      iconCol: iconCol,
      iconRow: iconRow,
      iconAssetPathOverride: iconAssetPathOverride,
      usedByUnits: List.unmodifiable(usedByUnits),
    );
  }
}

class AbilitiesCatalog {
  AbilitiesCatalog._(this.entries);

  final List<CatalogAbility> entries;

  static AbilitiesCatalog fromUnits(List<GameUnit> units) {
    final buckets = <String, _AggBucket>{};

    for (final unit in units) {
      for (final a in unit.passiveAbilities) {
        if (a.name.trim().isEmpty || !a.isListableAbility) continue;
        final key = 'p::${a.name.trim().toLowerCase()}';
        final b = buckets.putIfAbsent(
          key,
          () => _AggBucket(name: a.name.trim(), isActive: false),
        );
        b.addUnit(unit);
        b.mergeFromAbility(a);
      }
      for (final a in unit.activeAbilities) {
        if (a.name.trim().isEmpty || !a.isListableAbility) continue;
        final key = 'a::${a.name.trim().toLowerCase()}';
        final b = buckets.putIfAbsent(
          key,
          () => _AggBucket(name: a.name.trim(), isActive: true),
        );
        b.addUnit(unit);
        b.mergeFromAbility(a);
      }
      for (final effect in unit.statusEffects) {
        final name = effect.name.trim();
        if (name.isEmpty) continue;
        final debuffKey = effect.isDebuff == true ? 'debuff' : 'buff';
        final key = 's::$debuffKey::${name.toLowerCase()}';
        final b = buckets.putIfAbsent(
          key,
          () => _AggBucket(
            name: name,
            isActive: false,
            isStatusEffect: true,
            isDebuff: effect.isDebuff,
          ),
        );
        b.addUnit(unit);
        b.mergeFromStatusEffect(effect);
      }
    }

    final list = buckets.values.map((b) => b.toCatalogAbility()).toList();
    list.sort((x, y) {
      int rank(CatalogAbility a) {
        if (a.isStatusEffect) return 2;
        if (a.isActive) return 1;
        return 0;
      }

      final kindCompare = rank(x).compareTo(rank(y));
      if (kindCompare != 0) {
        return kindCompare;
      }
      return x.name.toLowerCase().compareTo(y.name.toLowerCase());
    });
    return AbilitiesCatalog._(list);
  }

  List<CatalogAbility> filter({
    List<String>? kinds, // any of: 'passive' | 'active' | 'buff' | 'debuff'
    List<String>? raceFolders,
    String? search,
  }) {
    var result = entries;
    if (kinds != null && kinds.isNotEmpty) {
      final selected = kinds.toSet();
      result = result.where((e) {
        if (selected.contains('passive') && e.typeKey == 'passive') {
          return true;
        }
        if (selected.contains('active') && e.typeKey == 'active') {
          return true;
        }
        if (selected.contains('buff') &&
            e.typeKey == 'status' &&
            e.isDebuff != true) {
          return true;
        }
        if (selected.contains('debuff') &&
            e.typeKey == 'status' &&
            e.isDebuff == true) {
          return true;
        }
        return false;
      }).toList();
    }
    if (raceFolders != null && raceFolders.isNotEmpty) {
      final folders = raceFolders;
      result = result
          .where(
            (e) => e.usedByUnits.any(
              (u) => folders.contains(u.raceFolder),
            ),
          )
          .toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      result = result.where((e) {
        if (e.name.toLowerCase().contains(q)) {
          return true;
        }
        if ((e.description ?? '').toLowerCase().contains(q)) {
          return true;
        }
        return e.usedByUnits.any(
          (u) =>
              u.displayName.toLowerCase().contains(q) ||
              u.unitId.toLowerCase().contains(q),
        );
      }).toList();
    }
    return result;
  }
}
