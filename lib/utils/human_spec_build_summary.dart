import 'package:worldshift_assistant/data/human_skill_tree_data.dart';
import 'package:worldshift_assistant/data/spec_tree_node.dart';

final _snippetPairRe =
    RegExp(r'([A-Za-z0-9_]+)\s*=\s*([^,]+)', caseSensitive: false);

/// Valor numérico parseado y si el texto fuente iba en **porcentaje** (`%`).
class NumericAttrValue {
  const NumericAttrValue({required this.value, required this.isPercent});

  final double value;
  final bool isPercent;
}

/// Pares `clave = valor` de un tramo de [SpecTreeNode.rankStatSnippets].
/// Claves en minúsculas; [NumericAttrValue.isPercent] si el fragmento de valor contiene `%`.
Map<String, NumericAttrValue> parseHumanSpecRankSnippet(String snippet) {
  final out = <String, NumericAttrValue>{};
  if (snippet.isEmpty) {
    return out;
  }
  for (final m in _snippetPairRe.allMatches(snippet)) {
    final key = m.group(1)!.trim().toLowerCase();
    final rawVal = m.group(2)!.trim();
    final n = _firstNumberInString(rawVal);
    if (n != null) {
      out[key] = NumericAttrValue(
        value: n,
        isPercent: rawVal.contains('%'),
      );
    }
  }
  return out;
}

double? _firstNumberInString(String s) {
  final m = RegExp(r'-?\d+(?:[.,]\d+)?').firstMatch(s);
  if (m == null) {
    return null;
  }
  return double.tryParse(m.group(0)!.replaceAll(',', '.'));
}

/// Una fila por nodo invertido con bonos numéricos del **rango actual**, por unidad objetivo.
class HumanSpecUnitContribution {
  const HumanSpecUnitContribution({
    required this.repo,
    required this.nodeTitle,
    required this.attrs,
    required this.investedRanks,
    required this.maxRanks,
  });

  final String repo;
  final String nodeTitle;
  final Map<String, NumericAttrValue> attrs;
  /// Estrellas invertidas en este nodo (1..maxRanks).
  final int investedRanks;
  final int maxRanks;
}

/// Lista de nodos que aportan stats a cada unidad (misma entrada repetida en cada [SpecTreeNode.targets]).
Map<String, List<HumanSpecUnitContribution>> specTreeContributionsDetailed(
  Map<String, int> specByRepo,
  SpecTreeNode? Function(String repo) nodeForRepo,
) {
  final out = <String, List<HumanSpecUnitContribution>>{};
  for (final e in specByRepo.entries) {
    final invested = e.value;
    if (invested <= 0) {
      continue;
    }
    final node = nodeForRepo(e.key);
    if (node == null) {
      continue;
    }
    final idx = invested - 1;
    if (idx < 0 || idx >= node.rankStatSnippets.length) {
      continue;
    }
    final deltas = parseHumanSpecRankSnippet(node.rankStatSnippets[idx]);
    if (deltas.isEmpty) {
      continue;
    }
    final row = HumanSpecUnitContribution(
      repo: node.repo,
      nodeTitle: node.title,
      attrs: Map<String, NumericAttrValue>.from(deltas),
      investedRanks: invested,
      maxRanks: node.maxRanks,
    );
    for (final unit in node.targets) {
      out.putIfAbsent(unit, () => []).add(row);
    }
  }
  return out;
}

Map<String, List<HumanSpecUnitContribution>> humanSpecContributionsDetailed(
  Map<String, int> specByRepo,
) {
  return specTreeContributionsDetailed(
    specByRepo,
    (repo) => humanSpecTreeByRepo[repo],
  );
}
