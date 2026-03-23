import 'package:flutter/material.dart';
import 'package:worldshift_assistant/data/data.dart';

/// Resalta tokens `[stat:…]`, `[stats.…]`, etc. y los sustituye por etiquetas legibles.
class GameDescriptionText extends StatelessWidget {
  const GameDescriptionText(
    this.text, {
    super.key,
    required this.baseStyle,
    this.compact = false,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  final String text;
  final TextStyle baseStyle;

  /// Si es true, usa solo [TextSpan] (sin [WidgetSpan]) para que funcionen
  /// `maxLines` y `ellipsis` en listas; el aspecto es similar (fondo en el token).
  final bool compact;
  final int? maxLines;
  final TextOverflow overflow;

  /// Quita marcas Unity/TextMeshPro/HTML que a veces vienen literales en los `.dt`
  /// (`<color=tooltip.lite>`, `</>`, `<b>`, etc.).
  static String stripGameUiMarkup(String raw) {
    if (raw.isEmpty) {
      return raw;
    }
    var s = raw;
    s = s.replaceAll(RegExp(r'</>'), '');
    s = s.replaceAll(RegExp(r'</color>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<color[^>]*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<material[^>]*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'</material>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<link[^>]*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'</link>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<mark[^>]*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'</mark>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<b>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'</b>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<i>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'</i>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<size[^>]*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'</size>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<nobr>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'</nobr>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<[^>]{1,200}>'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s.trim();
  }

  static String statLabel(String key) {
    const labelOverrides = <String, String>{
      'hp': 'Hit Points',
      'hit_points': 'Hit Points',
      'psi': 'Power',
      'power': 'Power',
    };
    final override = labelOverrides[key];
    if (override != null) {
      return override;
    }
    for (final m in attributeList) {
      if (m['key'] == key) return m['value'] ?? key;
    }
    return key.replaceAll('_', ' ');
  }

  static String humanizeDynamicToken(String token) {
    if (token.length < 3 || !token.startsWith('[') || !token.endsWith(']')) {
      return token;
    }
    final inner = token.substring(1, token.length - 1).trim();
    if (inner.isEmpty) {
      return token;
    }

    String? rawKey;
    if (inner.startsWith('stat:')) {
      rawKey = inner.substring(5);
    } else if (inner.startsWith('stats.')) {
      rawKey = inner.substring(6);
    } else if (inner.startsWith('var:')) {
      rawKey = inner.substring(4);
    }

    if (rawKey != null && rawKey.isNotEmpty) {
      final translated = statLabel(rawKey);
      final cleaned = translated.trim();
      if (cleaned.isEmpty || cleaned == rawKey) {
        return token;
      }
      return '[$cleaned]';
    }

    // [Confuse Duration], [FooBar] — legible sin prefijo stat:/var:
    if (RegExp(r'^[A-Za-z0-9_ ]+$').hasMatch(inner)) {
      var readable = inner.replaceAll('_', ' ');
      readable = readable.replaceAllMapped(
        RegExp(r'(?<=[a-z0-9])(?=[A-Z])'),
        (_) => ' ',
      );
      readable = readable.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (readable.isNotEmpty) {
        return '[$readable]';
      }
    }

    return token;
  }

  @override
  Widget build(BuildContext context) {
    final cleaned = stripGameUiMarkup(text);
    if (compact) {
      return _buildCompact(context, cleaned);
    }
    return _buildRichWithWidgets(context, cleaned);
  }

  Widget _buildCompact(BuildContext context, String cleaned) {
    final pattern = RegExp(r'\[[^\]]+\]');
    final matches = pattern.allMatches(cleaned).toList();
    if (matches.isEmpty) {
      return Text(
        cleaned,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final tokenStyle = baseStyle.copyWith(
      color: const Color(0xFF3949AB),
      fontWeight: FontWeight.w700,
      backgroundColor: const Color(0xFFE3E8FF),
    );

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(
          TextSpan(
            text: cleaned.substring(cursor, m.start),
            style: baseStyle,
          ),
        );
      }
      spans.add(
        TextSpan(
          text: humanizeDynamicToken(cleaned.substring(m.start, m.end)),
          style: tokenStyle,
        ),
      );
      cursor = m.end;
    }
    if (cursor < cleaned.length) {
      spans.add(
        TextSpan(
          text: cleaned.substring(cursor),
          style: baseStyle,
        ),
      );
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  Widget _buildRichWithWidgets(BuildContext context, String cleaned) {
    final pattern = RegExp(r'\[[^\]]+\]');
    final matches = pattern.allMatches(cleaned).toList();
    if (matches.isEmpty) {
      return Text(cleaned, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(
          TextSpan(
            text: cleaned.substring(cursor, m.start),
            style: baseStyle,
          ),
        );
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFE3E8FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              humanizeDynamicToken(cleaned.substring(m.start, m.end)),
              style: baseStyle.copyWith(
                color: const Color(0xFF3949AB),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
      cursor = m.end;
    }
    if (cursor < cleaned.length) {
      spans.add(
        TextSpan(
          text: cleaned.substring(cursor),
          style: baseStyle,
        ),
      );
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}
