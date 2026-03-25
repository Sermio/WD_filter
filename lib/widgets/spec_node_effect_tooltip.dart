import 'package:flutter/material.dart';
import 'package:worldshift_assistant/data/spec_tree_node.dart';
import 'package:worldshift_assistant/widgets/game_description_highlights.dart';

/// Replaces `[stats.xxx]` / `[stat.xxx]` / `[stat:xxx]` with values from [SpecTreeNode.rankStatSnippets]:
/// with ranks invested, the current value in **green** and the rest in gray parentheses;
/// with 0 ranks, only the possible values in one parenthesis.
///
/// If linking fails, falls back to [GameDescriptionText] (normalized labels).
class SpecNodeEffectTooltip extends StatelessWidget {
  const SpecNodeEffectTooltip({
    super.key,
    required this.node,
    required this.investedRanks,
    required this.baseStyle,
  });

  final SpecTreeNode node;
  final int investedRanks;
  final TextStyle baseStyle;

  static final _tokenRe = RegExp(
    r'\[stats\.([a-zA-Z0-9_]+)\]|\[stat\.([a-zA-Z0-9_]+)\]|\[stat:([a-zA-Z0-9_]+)\]',
  );

  static String _keyFromTokenMatch(RegExpMatch m) =>
      m.group(1) ?? m.group(2) ?? m.group(3)!;

  static String? _valueForKey(String snippet, String key) {
    if (snippet.isEmpty) {
      return null;
    }
    final escaped = RegExp.escape(key);
    final m = RegExp(
      '$escaped\\s*=\\s*([^,]+)',
      caseSensitive: false,
    ).firstMatch(snippet);
    return m?.group(1)?.trim();
  }

  /// Longitud del prefijo ` %` opcional tras el cierre del token (p. ej. `[stats.x]%`).
  static int _percentSuffixSkipLen(String desc, int tokenEnd) {
    if (tokenEnd > desc.length) {
      return 0;
    }
    final sub = desc.substring(tokenEnd);
    final m = RegExp(r'^\s*%').firstMatch(sub);
    return m?.end ?? 0;
  }

  static void _appendPercentToValuesIfDescHasPercent(
    List<String> values,
    String desc,
    int tokenEnd,
  ) {
    if (_percentSuffixSkipLen(desc, tokenEnd) == 0) {
      return;
    }
    for (var i = 0; i < values.length; i++) {
      if (!values[i].contains('%')) {
        values[i] = '${values[i]}%';
      }
    }
  }

  static _ParsedSingleStat? _tryParseSingleSlot(
    SpecTreeNode node,
    String desc,
    RegExpMatch m,
  ) {
    final key = _keyFromTokenMatch(m);
    final perRank = <String>[];
    for (var i = 0; i < node.maxRanks; i++) {
      final sn =
          i < node.rankStatSnippets.length ? node.rankStatSnippets[i] : '';
      final v = _valueForKey(sn, key);
      if (v == null || v.isEmpty) {
        return null;
      }
      perRank.add(v);
    }
    _appendPercentToValuesIfDescHasPercent(perRank, desc, m.end);
    final skip = _percentSuffixSkipLen(desc, m.end);
    final after = desc.substring(m.end + skip);
    return _ParsedSingleStat(
      before: desc.substring(0, m.start),
      after: after,
      values: perRank,
    );
  }

  static _ParsedMultiStat? _tryParseMulti(
    SpecTreeNode node,
    String desc,
    List<RegExpMatch> matches,
  ) {
    final valuesPerSlot = <List<String>>[];
    for (final m in matches) {
      final key = _keyFromTokenMatch(m);
      final perRank = <String>[];
      for (var i = 0; i < node.maxRanks; i++) {
        final sn =
            i < node.rankStatSnippets.length ? node.rankStatSnippets[i] : '';
        final v = _valueForKey(sn, key);
        if (v == null || v.isEmpty) {
          return null;
        }
        perRank.add(v);
      }
      _appendPercentToValuesIfDescHasPercent(perRank, desc, m.end);
      valuesPerSlot.add(perRank);
    }
    return _ParsedMultiStat(desc: desc, matches: matches, values: valuesPerSlot);
  }

  static const Color _activeStatGreen = Color(0xFF00C853);
  static const Color _inactiveStatGray = Color(0xFF9CA3AF);
  static const Color _inactiveStatGrayEmphasis = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final desc = GameDescriptionText.stripGameUiMarkup(node.description);
    final matches = _tokenRe.allMatches(desc).toList();
    if (matches.isEmpty) {
      return GameDescriptionText(desc, baseStyle: baseStyle);
    }

    final cur = investedRanks.clamp(0, node.maxRanks);

    if (matches.length == 1) {
      final parsed = _tryParseSingleSlot(node, desc, matches.first);
      if (parsed != null) {
        return _buildSingle(parsed, cur);
      }
      return GameDescriptionText(desc, baseStyle: baseStyle);
    }

    final multi = _tryParseMulti(node, desc, matches);
    if (multi != null) {
      return _buildMulti(multi, cur);
    }
    return GameDescriptionText(desc, baseStyle: baseStyle);
  }

  Widget _buildSingle(_ParsedSingleStat parsed, int cur) {
    final paren = '(${parsed.values.join('/')})';
    final parenAlongsideActive = baseStyle.copyWith(
      color: _inactiveStatGray,
      fontWeight: FontWeight.w600,
    );
    final parenOnly = baseStyle.copyWith(
      color: _inactiveStatGrayEmphasis,
      fontWeight: FontWeight.w600,
    );

    final children = <InlineSpan>[TextSpan(text: parsed.before)];

    if (cur > 0) {
      children.add(
        TextSpan(
          text: parsed.values[cur - 1],
          style: baseStyle.copyWith(
            color: _activeStatGreen,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      children.add(TextSpan(text: ' $paren', style: parenAlongsideActive));
    } else {
      final needsSpaceBeforeParen = parsed.before.isNotEmpty &&
          !RegExp(r'\s$').hasMatch(parsed.before);
      children.add(
        TextSpan(
          text: '${needsSpaceBeforeParen ? ' ' : ''}$paren',
          style: parenOnly,
        ),
      );
    }

    children.add(TextSpan(text: parsed.after));

    return Text.rich(TextSpan(style: baseStyle, children: children));
  }

  Widget _buildMulti(_ParsedMultiStat multi, int cur) {
    final parenAlongsideActive = baseStyle.copyWith(
      color: _inactiveStatGray,
      fontWeight: FontWeight.w600,
    );
    final parenOnly = baseStyle.copyWith(
      color: _inactiveStatGrayEmphasis,
      fontWeight: FontWeight.w600,
    );

    final children = <InlineSpan>[];
    var cursor = 0;
    for (var i = 0; i < multi.matches.length; i++) {
      final m = multi.matches[i];
      if (m.start > cursor) {
        children.add(TextSpan(text: multi.desc.substring(cursor, m.start)));
      }
      final vals = multi.values[i];
      final paren = '(${vals.join('/')})';

      if (cur > 0) {
        children.add(
          TextSpan(
            text: vals[cur - 1],
            style: baseStyle.copyWith(
              color: _activeStatGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
        children.add(TextSpan(text: ' $paren', style: parenAlongsideActive));
      } else {
        final beforeThis = multi.desc.substring(0, m.start);
        final needsSpaceBeforeParen = beforeThis.isNotEmpty &&
            !RegExp(r'\s$').hasMatch(beforeThis);
        children.add(
          TextSpan(
            text: '${needsSpaceBeforeParen ? ' ' : ''}$paren',
            style: parenOnly,
          ),
        );
      }

      cursor = m.end + _percentSuffixSkipLen(multi.desc, m.end);
    }
    if (cursor < multi.desc.length) {
      children.add(TextSpan(text: multi.desc.substring(cursor)));
    }

    return Text.rich(TextSpan(style: baseStyle, children: children));
  }
}

class _ParsedSingleStat {
  _ParsedSingleStat({
    required this.before,
    required this.after,
    required this.values,
  });

  final String before;
  final String after;
  final List<String> values;
}

class _ParsedMultiStat {
  _ParsedMultiStat({
    required this.desc,
    required this.matches,
    required this.values,
  });

  final String desc;
  final List<RegExpMatch> matches;
  final List<List<String>> values;
}
