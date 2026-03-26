/// Repara textos exportados del juego: U+FFFD, mojibake `ï¿½` (UTF-8 leído como Latin-1)
/// y apóstrofos posesivos perdidos (mismo criterio que en *specs.dt).
String repairGameTextEncodingArtifacts(String s) {
  if (s.isEmpty) {
    return s;
  }
  const mojibake = '\u00EF\u00BF\u00BD';
  const replacement = '\uFFFD';
  var o = s;

  // "Achï¿½Lord" / "Ach�Lord" → apóstrofo entre trozos de palabra (típico U+2019 mal codificado).
  final betweenWords = RegExp(
    r'([A-Za-z]+)' + RegExp.escape(mojibake) + r'([A-Za-z]+)',
  );
  o = o.replaceAllMapped(betweenWords, (m) => "${m[1]}'${m[2]}");

  o = o.contains(mojibake) ? o.replaceAll(mojibake, replacement) : o;
  if (!o.contains(replacement)) {
    return o;
  }
  o = o.replaceAllMapped(
    RegExp(r'([A-Za-z]+)' + replacement + r'([A-Za-z]+)'),
    (m) => "${m[1]}'${m[2]}",
  );
  o = o.replaceAllMapped(
    RegExp(r'([A-Za-z]+)' + replacement + r's(?=[\s\.,;:!?\)\]]|$)'),
    (m) => "${m[1]}'s",
  );
  o = o.replaceAllMapped(
    RegExp(r'([A-Za-z]+)' + replacement + r'(?=\s)'),
    (m) => "${m[1]}' ",
  );
  return o;
}
