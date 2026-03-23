import 'package:worldshift_assistant/models/game_unit.dart';

/// Parser mínimo para ficheros `.dt` de unidades (Worldshift / WorldShift).
class DtUnitParser {
  static GameUnit? parse(String fileId, String raceFolder, String source) {
    final race = _matchRace(source);
    final displayName = _matchDisplayName(fileId, source);
    final tags = _matchLineValue(source, r'tags\s*=\s*([^\n]+)');
    final movement = _matchLineValue(source, r'movement_type\s*=\s*(\w+)');
    final unitIconClass = _matchUnitIconClass(source);
    final mainIcon = _matchIconPair(source);
    final convRow = _matchIntValue(source, r'conv_icon_row\s*=\s*(\d+)');
    final convCol = _matchIntValue(source, r'conv_icon_col\s*=\s*(\d+)');
    final stats = _extractStatsBlock(source);
    final auras = _extractTakeAuras(source);
    final abilities = _extractAbilities(source);
    final statusEffects = _extractStatusEffects(source);

    if (race == null && stats.isEmpty && displayName == null) {
      return null;
    }

    return GameUnit(
      id: fileId,
      raceFolder: raceFolder,
      displayName: displayName ?? fileId,
      race: race,
      movementType: movement,
      tags: tags,
      unitIconClass: unitIconClass,
      mainIconCol: mainIcon?.$1,
      mainIconRow: mainIcon?.$2,
      conversationIconCol: convCol,
      conversationIconRow: convRow,
      stats: stats,
      auraNames: auras,
      passiveAbilities: abilities.$1,
      activeAbilities: abilities.$2,
      statusEffects: statusEffects,
    );
  }

  static String? _matchRace(String s) {
    final m = RegExp(r'race\s*=\s*(humans|mutants|aliens)\b').firstMatch(s);
    return m?.group(1);
  }

  static String? _matchDisplayName(String fileId, String s) {
    final header = s.split('\n').take(24).join('\n');

    final directHeaderName = RegExp(
      r'^\s*name\s*=\s*(?:"([^"]*)"|([^\n]+))',
      multiLine: true,
    ).firstMatch(header);
    final directHeaderValue = _cleanNameValue(
      directHeaderName?.group(1) ?? directHeaderName?.group(2),
    );
    if (directHeaderValue != null) {
      return directHeaderValue;
    }

    final specificNameKey = RegExp(
      '^\\s*${RegExp.escape(fileId)}_name\\s*=\\s*(?:"([^"]*)"|([^\\n]+))',
      multiLine: true,
    ).firstMatch(header);
    final specificNameValue = _cleanNameValue(
      specificNameKey?.group(1) ?? specificNameKey?.group(2),
    );
    if (specificNameValue != null) {
      return specificNameValue;
    }

    final topLevelAlias = RegExp(
      r'^\s*(?!name_var\b)(?!.*\bbeam_name\b)(\w+_name)\s*=\s*(?:"([^"]*)"|([^\n]+))',
      multiLine: true,
    ).firstMatch(header);
    return _cleanNameValue(topLevelAlias?.group(2) ?? topLevelAlias?.group(3));
  }

  static String? _cleanNameValue(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value.replaceAll(RegExp(r'\s+$'), '');
  }

  static String? _matchLineValue(String s, String pattern) {
    final m = RegExp(pattern, multiLine: true).firstMatch(s);
    return m?.group(1)?.trim();
  }

  static String _matchUnitIconClass(String s) {
    if (RegExp(r'^\s*commander\s*=\s*1\b', multiLine: true).hasMatch(s)) {
      return 'commander';
    }
    if (RegExp(r'^\s*officer\s*=\s*1\b', multiLine: true).hasMatch(s)) {
      return 'officer';
    }
    return 'unit';
  }

  static int? _matchIntValue(String s, String pattern) {
    final m = RegExp(pattern, multiLine: true).firstMatch(s);
    return int.tryParse(m?.group(1) ?? '');
  }

  static (int, int)? _matchIconPair(String s) {
    final m = RegExp(r'^\s*icon\s*=\s*(\d+)\s*,\s*(\d+)', multiLine: true)
        .firstMatch(s);
    if (m == null) return null;
    final col = int.tryParse(m.group(1) ?? '');
    final row = int.tryParse(m.group(2) ?? '');
    if (col == null || row == null) return null;
    return (col, row);
  }

  static Map<String, String> _extractStatsBlock(String s) {
    final start = RegExp(r'stats\s*:\s*\{').firstMatch(s);
    if (start == null) return {};

    var i = start.end;
    var depth = 1;
    final startContent = i;
    String inner = '';
    for (; i < s.length; i++) {
      final c = s[i];
      if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0) {
          inner = s.substring(startContent, i);
          break;
        }
      }
    }
    if (inner.isEmpty) return {};
    final map = <String, String>{};
    for (final line in inner.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('//')) continue;
      final kv = RegExp(r'^(\w+)\s*=\s*(.+)$').firstMatch(trimmed);
      if (kv != null) {
        map[kv.group(1)!] = kv.group(2)!.trim();
      }
    }
    return map;
  }

  static List<String> _extractTakeAuras(String s) {
    final m = RegExp(
      r'take_auras\s*:\s*\{\s*([^}]*)\}',
      multiLine: true,
    ).firstMatch(s);
    if (m == null) return [];
    final inner = m.group(1) ?? '';
    return inner
        .split(RegExp(r'\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static (List<GameUnitAbility>, List<GameUnitAbility>) _extractAbilities(
    String source,
  ) {
    final passive = <GameUnitAbility>[];
    final active = <GameUnitAbility>[];
    final seenPassive = <String>{};
    final seenActive = <String>{};

    for (final block in _extractBlocks(source)) {
      if (_isAbilitiesContainer(block.header)) {
        for (final child in _extractBlocks(block.body)) {
          final ability = _buildAbility(
            child.body,
            iconAtlas: 'passive_abilities',
          );
          if (ability == null || !_shouldKeepAbility(ability.name)) {
            continue;
          }
          if (seenPassive.add(ability.name)) {
            passive.add(ability);
          }
        }
        continue;
      }

      final ability = _buildAbility(
        block.body,
        iconAtlas: _isActiveAbilityBlock(block) ? 'buttons' : 'passive_abilities',
      );
      if (ability == null || !_shouldKeepAbility(ability.name)) {
        continue;
      }

      if (_isActiveAbilityBlock(block)) {
        if (seenActive.add(ability.name)) {
          active.add(ability);
        }
      } else if (_isPassiveAbilityBlock(block)) {
        if (seenPassive.add(ability.name)) {
          passive.add(ability);
        }
      }
    }

    return (passive, active);
  }

  static bool _isAbilitiesContainer(String header) {
    return header.trim().endsWith('Abilities');
  }

  static bool _isActiveAbilityBlock(_DtBlock block) {
    final header = block.header.trim();
    final body = block.body;
    return header.startsWith('CSpellAction ') ||
        header.startsWith('CEffectAction ') ||
        header.startsWith('action ') ||
        header.endsWith('Action') ||
        RegExp(r'^\s*visible\s*=\s*1\b', multiLine: true).hasMatch(body) ||
        RegExp(r'^\s*cooldown\s*=\s*', multiLine: true).hasMatch(body);
  }

  static bool _isPassiveAbilityBlock(_DtBlock block) {
    final header = block.header.trim();
    final body = block.body;
    return header.endsWith('Abi') ||
        RegExp(r'^\s*when\s*:\s*abi\.', multiLine: true).hasMatch(body);
  }

  static GameUnitAbility? _buildAbility(
    String body, {
    required String iconAtlas,
  }) {
    final nameMatch = RegExp(
      r'^\s*name\s*=\s*(?:"([^"]*)"|([^\n]+))',
      multiLine: true,
    ).firstMatch(body);
    final descriptionMatch = RegExp(
      r'^\s*(?:text|descr)\s*=\s*"([^"]*)"',
      multiLine: true,
    ).firstMatch(body);
    final name = _cleanNameValue(nameMatch?.group(1) ?? nameMatch?.group(2));
    if (name == null || name.isEmpty) {
      return null;
    }
    final description = _cleanNameValue(descriptionMatch?.group(1));
    final icon = _matchIconPair(body);
    String? resolvedAtlas;
    int? resolvedCol;
    int? resolvedRow;
    if (icon != null) {
      final normalizedAtlas = _normalizeAbilityAtlas(
        preferredAtlas: iconAtlas,
        col: icon.$1,
        row: icon.$2,
      );
      final normalizedCoords = _normalizeAbilityCoords(
        atlas: normalizedAtlas,
        col: icon.$1,
        row: icon.$2,
      );
      if (_isValidAbilityIconCoord(
        atlas: normalizedAtlas,
        col: normalizedCoords.$1,
        row: normalizedCoords.$2,
      )) {
        resolvedAtlas = normalizedAtlas;
        resolvedCol = normalizedCoords.$1;
        resolvedRow = normalizedCoords.$2;
      }
    }
    return GameUnitAbility(
      name: name,
      description: description,
      iconAtlas: resolvedAtlas,
      iconCol: resolvedCol,
      iconRow: resolvedRow,
    );
  }

  static String _normalizeAbilityAtlas({
    required String preferredAtlas,
    required int col,
    required int row,
  }) {
    // passive_abilities atlas is 16x16 over 256x64 => row 0..3.
    // If parsed coords are outside that range, they belong to action buttons.
    if (preferredAtlas == 'passive_abilities' && row > 3) {
      return 'buttons';
    }
    return preferredAtlas;
  }

  static bool _isValidAbilityIconCoord({
    required String atlas,
    required int col,
    required int row,
  }) {
    if (col < 0 || row < 0) {
      return false;
    }
    if (atlas == 'passive_abilities') {
      return col <= 15 && row <= 3;
    }
    if (atlas == 'buttons') {
      return col <= 13 && row <= 13;
    }
    return true;
  }

  static (int, int) _normalizeAbilityCoords({
    required String atlas,
    required int col,
    required int row,
  }) {
    if (atlas == 'buttons') {
      // Action icons in .dt are stored 1-based, exported atlas uses 0-based.
      final normalizedCol = col > 0 ? col - 1 : col;
      final normalizedRow = row > 0 ? row - 1 : row;
      return (normalizedCol, normalizedRow);
    }
    return (col, row);
  }

  static bool _shouldKeepAbility(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    return normalized != 'description';
  }

  static List<GameUnitStatusEffect> _extractStatusEffects(String source) {
    final effects = <GameUnitStatusEffect>[];
    final seen = <String>{};

    void visit(String text) {
      for (final block in _extractBlocks(text)) {
        if (_isStatusEffectBlock(block)) {
          final effect = _buildStatusEffect(block.body);
          if (effect != null && seen.add(effect.name)) {
            effects.add(effect);
          }
        }
        final children = _extractBlocks(block.body);
        if (children.isNotEmpty) {
          visit(block.body);
        }
      }
    }

    visit(source);
    return effects;
  }

  static bool _isStatusEffectBlock(_DtBlock block) {
    final header = block.header.trim();
    final body = block.body;
    return header.startsWith('CBuffEffect ') ||
        header.startsWith('E_debuff ') ||
        header.startsWith('E_multidebuff ') ||
        header.startsWith('S_stun ') ||
        header.startsWith('S_multistun ') ||
        RegExp(r'^\s*debuff\s*=\s*1\b', multiLine: true).hasMatch(body);
  }

  static GameUnitStatusEffect? _buildStatusEffect(String body) {
    final nameMatch = RegExp(
      r'^\s*name\s*=\s*(?:"([^"]*)"|([^\n]+))',
      multiLine: true,
    ).firstMatch(body);
    final descMatch = RegExp(
      r'^\s*(?:text|descr)\s*=\s*"([^"]*)"',
      multiLine: true,
    ).firstMatch(body);
    final name = _cleanNameValue(nameMatch?.group(1) ?? nameMatch?.group(2));
    if (name == null || name.isEmpty || !_shouldKeepAbility(name)) {
      return null;
    }
    final description = _cleanNameValue(descMatch?.group(1));
    final icon = _matchIconPair(body);
    final iconAtlas = icon == null ? null : _guessStatusEffectAtlas(icon.$1, icon.$2);
    final isDebuff =
        RegExp(r'^\s*debuff\s*=\s*1\b', multiLine: true).hasMatch(body) ? true : null;
    return GameUnitStatusEffect(
      name: name,
      description: description,
      isDebuff: isDebuff,
      iconAtlas: iconAtlas,
      iconCol: icon?.$1,
      iconRow: icon?.$2,
    );
  }

  static String? _guessStatusEffectAtlas(int col, int row) {
    if (row >= 0 && row <= 3 && col >= 0 && col <= 15) {
      return 'buff_icons';
    }
    return null;
  }

  static List<_DtBlock> _extractBlocks(String source) {
    final blocks = <_DtBlock>[];
    final lines = source.split('\n');
    var depth = 0;
    String? currentHeader;
    final currentBody = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      final opens = '{'.allMatches(line).length;
      final closes = '}'.allMatches(line).length;

      if (depth == 0 && trimmed.endsWith('{')) {
        currentHeader = trimmed.substring(0, trimmed.length - 1).trim();
        currentBody.clear();
        depth += opens - closes;
        continue;
      }

      if (currentHeader != null) {
        currentBody.add(line);
      }

      depth += opens - closes;

      if (currentHeader != null && depth == 0) {
        if (currentBody.isNotEmpty && currentBody.last.trim() == '}') {
          currentBody.removeLast();
        }
        blocks.add(
          _DtBlock(
            header: currentHeader,
            body: currentBody.join('\n'),
          ),
        );
        currentHeader = null;
        currentBody.clear();
      }
    }

    return blocks;
  }
}

class _DtBlock {
  const _DtBlock({
    required this.header,
    required this.body,
  });

  final String header;
  final String body;
}
