/// Repara textos exportados del juego: U+FFFD, mojibake `ï¿½` (UTF-8 leído como Latin-1)
/// y apóstrofos posesivos perdidos (mismo criterio que en *specs.dt).
String repairGameTextEncodingArtifacts(String s) {
  if (s.isEmpty) {
    return s;
  }
  const mojibake = '\u00EF\u00BF\u00BD';
  var o = s.contains(mojibake) ? s.replaceAll(mojibake, '\uFFFD') : s;
  if (!o.contains('\uFFFD')) {
    return o;
  }
  o = o.replaceAllMapped(
    RegExp(r'([A-Za-z]+)\uFFFDs(?=[\s\.,;:!?\)\]]|$)'),
    (m) => "${m[1]}'s",
  );
  o = o.replaceAllMapped(
    RegExp(r'([A-Za-z]+)\uFFFD(?=\s)'),
    (m) => "${m[1]}' ",
  );
  return o;
}
