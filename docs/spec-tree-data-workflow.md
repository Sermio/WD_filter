# Árbol de especialización (skill tree): fuentes y generación

Este documento describe cómo se obtienen los datos del árbol de specs (Humans, Tribes/Mutants, Aliens) a partir del juego original y cómo mantenerlos actualizados con scripts.

## Fuentes en Worldshift

| Uso | Ruta en el clon del juego |
|-----|---------------------------|
| Definición de cada spec (stats, `repo`, `name`, etc.) | `data/db/items/humansspecs.dt`, `mutantsspecs.dt`, `aliensspecs.dt` |
| Posición de icono en el atlas (`row`/`col` 1-based) | `data/db/ui/techgrid.lua` (`SpecSlot_*` → `DefSpecSlot { row, col, repo }`) |
| Texturas del atlas | `data/textures/ui/` (pipeline `extract_worldshift_ui_icons` → `spec_tree_icons`) |

El script maestro copia además los tres `*specs.dt` y `techgrid.lua` a `assets/loot/source_game/` para poder regenerar sin tener el clon en la misma ruta que el desarrollador.

## Qué genera la app

- **Tipos**: `lib/data/spec_tree_node.dart` — clase compartida `SpecTreeNode`.
- **Humans** (UI actual): `lib/data/human_skill_tree_data.dart` + `lib/data/generated/skill_tree_humans.g.dart`.
- **Mutants / Aliens** (datos listos, sin panel aún): `mutant_skill_tree_data.dart`, `alien_skill_tree_data.dart` y sus `.g.dart`.

Los `.g.dart` **no se editan a mano**; se regeneran con el tool descrito abajo.

## Overrides (`tool/skill_tree_overrides.json`)

El `.dt` no incluye textos de UI listos para la app (p. ej. `rankBonuses` en lenguaje natural, listas de unidades afectadas). Tampoco el layout visual 2-3-2-3 coincide siempre con el emparejamiento “literal” A/B y C/D del nombre del slot.

Por eso el JSON de overrides aporta, por raza:

- **`visualRowRepos`**: orden de filas visuales (listas de `repo`). Si es `null`, el generador ordena los repos por `(row, col)` del `techgrid` y parte en grupos 2+3+2+3.
- **`iconColOverride` / `iconRowOverride`**: correcciones cuando el atlas no coincide con la etiqueta del índice (caso documentado: Humans `SPECC2` / `SPECD2`).
- **`nodes.<REPO>.targets`** y **`nodes.<REPO>.rankBonuses`**: textos y unidades objetivo. Si faltan, `targets` queda vacío y `rankBonuses` se rellena con los snippets de stats del `.dt` (o un placeholder).

Tras un cambio en el juego, suele bastar con **ajustar solo el JSON** si cambian textos o layout; si cambian stats o nombres en el `.dt`, el generador los tomará al volver a ejecutar.

## Script de generación

Desde la raíz del repo Flutter:

```bash
dart run tool/generate_skill_tree_data.dart
dart run tool/generate_skill_tree_data.dart "C:\ruta\al\clon\Worldshift"
```

Resolución de rutas (en orden): argumento → ruta por defecto del desarrollador → `assets/loot/source_game/items` y `assets/loot/source_game/refs/techgrid.lua`.

Salida: `lib/data/generated/skill_tree_humans.g.dart`, `skill_tree_mutants.g.dart`, `skill_tree_aliens.g.dart`.

## Integración con el refresh maestro

`tool/refresh_worldshift_item_data.dart` ahora:

1. Copia los `*specs.dt` y `techgrid.lua` a `assets/loot/source_game/`.
2. Ejecuta `generate_ui_icon_name_indexes.dart` pasando la ruta de Worldshift (misma base que `data/db`).
3. Ejecuta `generate_skill_tree_data.dart` con esa ruta.
4. Sigue con `rebuild_data_dart.dart`, etc.

## Comprobación de rangos

Para validar el número de rangos inferido del bloque `stats` (segmentos `/` y `levels`):

```bash
dart run tool/verify_spec_dt.dart
```

(Ajusta la ruta dentro del script si tu clon no está en la ruta por defecto.)

## Resumen operativo

1. Actualizar el clon de Worldshift.
2. `dart run tool/refresh_worldshift_item_data.dart [ruta_Worldshift]`.
3. Si el layout o los textos de bonus/targets cambian, editar `tool/skill_tree_overrides.json`.
4. Revisar diff en `lib/data/generated/skill_tree_*.g.dart` y probar la pantalla del árbol (Humans).

Cuando exista UI para Tribes/Aliens, enlazar los mismos mapas/grid que ya genera el tool.
