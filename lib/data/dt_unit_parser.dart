import 'package:worldshift_assistant/models/game_unit.dart';

/// Parser mínimo para ficheros `.dt` de unidades (Worldshift / WorldShift).
class DtUnitParser {
  static GameUnit? parse(String fileId, String raceFolder, String source) {
    final race = _matchRace(source);
    final displayName = _matchDisplayName(source);
    final tags = _matchLineValue(source, r'tags\s*=\s*([^\n]+)');
    final movement =
        _matchLineValue(source, r'movement_type\s*=\s*(\w+)');
    final unitIconClass = _matchUnitIconClass(source);
    final mainIcon = _matchIconPair(source);
    final convRow = _matchIntValue(source, r'conv_icon_row\s*=\s*(\d+)');
    final convCol = _matchIntValue(source, r'conv_icon_col\s*=\s*(\d+)');
    final stats = _extractStatsBlock(source);
    final auras = _extractTakeAuras(source);

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
    );
  }

  static String? _matchRace(String s) {
    final m = RegExp(r'race\s*=\s*(humans|mutants|aliens)\b').firstMatch(s);
    return m?.group(1);
  }

  static String? _matchDisplayName(String s) {
    final nameQuoted =
        RegExp(r'^\s*name\s*=\s*"([^"]*)"', multiLine: true).firstMatch(s);
    if (nameQuoted != null) return nameQuoted.group(1);

    final anyName = RegExp(r'(\w+)_name\s*=\s*"([^"]*)"').firstMatch(s);
    return anyName?.group(2);
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
}
