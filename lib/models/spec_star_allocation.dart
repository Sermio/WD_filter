/// En WorldShift hay **10 estrellas de especialización** por raza; se reparten entre los
/// nodos del árbol sin requisitos de orden (la app no modela prerequisitos del juego).
const int kSpecStarBudgetPerRace = 10;

int clampSpecStarsForNode(int value, int maxRanks) {
  if (maxRanks <= 0) {
    return 0;
  }
  if (value < 0) {
    return 0;
  }
  if (value > maxRanks) {
    return maxRanks;
  }
  return value;
}

int totalSpecStarsAllocated(Map<String, int> byRepo) {
  var t = 0;
  for (final v in byRepo.values) {
    t += v;
  }
  return t;
}

/// Ajusta [repo] a [newValue] respetando [maxRanks] del nodo y el cupo global [budget].
/// Devuelve el mapa mutado (misma instancia que [current]).
Map<String, int> applySpecStarChange({
  required Map<String, int> current,
  required String repo,
  required int newValue,
  required int maxRanks,
  int budget = kSpecStarBudgetPerRace,
}) {
  final clampedNode = clampSpecStarsForNode(newValue, maxRanks);
  final prev = current[repo] ?? 0;
  final other = totalSpecStarsAllocated(current) - prev;
  final maxAllowed = (budget - other).clamp(0, maxRanks);
  final next = clampedNode > maxAllowed ? maxAllowed : clampedNode;
  if (next == 0) {
    current.remove(repo);
  } else {
    current[repo] = next;
  }
  return current;
}
