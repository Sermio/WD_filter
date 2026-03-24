# Actualización de items, loot y orígenes

Este documento describe el proceso para actualizar en la app los datos de items de Worldshift cuando el juego o el mod añadan nuevos items, nuevas mesas de loot, nuevos drops o nuevas recompensas.

La idea es que en el futuro baste con:

1. Reemplazar los archivos fuente en el clon local de `Worldshift`.
2. Ejecutar uno o varios scripts.
3. Abrir la app y verificar que todo aparece actualizado.

Si más adelante quieres pedirme que haga el proceso, puedes decir literalmente:

`Revisa docs/item-data-update-workflow.md y ejecuta la actualización de items.`

## Qué usa hoy la app

La app usa estos datos locales:

- `assets/tsvFiles/items_extra_data_complete.txt`
- `assets/tsvFiles/loot_complete.txt`
- `assets/tsvFiles/drop.tsv`
- `assets/data/item_origin_index.json`
- `assets/data/units.json`
- `lib/data/item_list_generated.dart`
- `lib/data/data.dart`
- `lib/data/item.dart`

Además, se guarda una copia más fiel de las fuentes originales en:

- `assets/loot/source_game/items/`
- `assets/loot/source_game/texts/`
- `assets/loot/source_game/refs/`

## Archivos fuente que hay que actualizar

Dentro del clon local de `Worldshift`, el flujo de items depende de estos archivos:

- `data/db/items/items.tsv`
- `data/db/items/loot.tsv`
- `data/db/items/loot index.tsv`
- `data/db/items/drop.tsv`
- `data/db/items/humansspecs.dt`
- `data/db/items/mutantsspecs.dt`
- `data/db/items/aliensspecs.dt`
- `data/db/units/**/*.dt`
- `data/texts/en/items.tsv`
- `data/texts/en/missions.tsv`

Si además cambian iconos o frames de items, también intervienen:

- `data/db/items/globals.dt`
- `data/db/ui/inventory.lua`
- los atlas DDS que copies dentro del repo:
  - `assets/ddsFiles/items.dds`
  - `assets/ddsFiles/item_frames.dds`

## Script maestro

El script principal para sincronizar datos de items es:

```bash
dart run tool/refresh_worldshift_item_data.dart
```

Opcionalmente acepta la ruta base al clon de `Worldshift`:

```bash
dart run tool/refresh_worldshift_item_data.dart "C:\Users\sergi\Desktop\Proyectos\Worldshift"
```

## Qué hace el script maestro

`tool/refresh_worldshift_item_data.dart` hace esto:

1. Copia desde `Worldshift` los TSV fuente a `assets/loot/source_game/`.
2. Copia también los archivos necesarios a `assets/tsvFiles/` para mantener compatibilidad con el runtime actual de la app.
3. Regenera:
   - `assets/loot/source_game/refs/map_drop_refs.tsv`
   - `assets/loot/source_game/refs/unit_drop_refs.tsv`
4. Ejecuta:
   - `dart run tool/generate_item_origin_index.dart`
   - `dart run tool/generate_item_list.dart`
   - `dart run tool/rebuild_attribute_list.dart`
   - `dart run tool/extract_worldshift_ui_icons.dart`
   - `dart run tool/generate_worldshift_assets.dart`
   - `dart run tool/generate_status_effect_icon_index.dart`
   - `dart run tool/generate_ui_icon_name_indexes.dart`
   - `dart run tool/rebuild_data_dart.dart`

Con eso quedan actualizados:

- el catálogo local de items
- el índice de orígenes por mesa/mapa/modo
- el listado de nombres usado por la búsqueda
- los iconos extraídos de atlas UI (`assets/generated/ui_icons/*`)
- el índice de efectos de estado y resolución de iconos (`assets/generated/ui_icons/buff_icons/status_effect_icon_index.json`)
- `assets/data/units.json`
- las listas derivadas de `lib/data/data.dart` (`attributesList`, `attributeList`, `attributeFilter`, `units`, `races`, `maps`, `lootTable`, `slots`)
- `lib/data/item.dart` para mantener `unitsFlat` sincronizado

## Extracción correcta de buffs/debuffs

Para buffs/debuffs, la referencia visual del juego sale de:

- `data/textures/ui/buff_icons.dds`
- lógica de render en `data/db/ui/selection.lua` (`slot.Icon:Set(v.icon_row, v.icon_col)`).

El flujo de este repo para mantenerlos sincronizados es:

1. Extraer atlas UI con `tool/extract_worldshift_ui_icons.dart`.
2. Regenerar `assets/data/units.json` con `tool/generate_worldshift_assets.dart`.
3. Generar índice de validación desde fuentes originales (`units/*.dt` + `effects/*.dt`) con:
   - `tool/generate_status_effect_icon_index.dart`
4. Regenerar índices de nombres de iconos con:
   - `tool/generate_ui_icon_name_indexes.dart`

`tool/refresh_worldshift_item_data.dart` ya ejecuta esos pasos automáticamente cuando existe `data/textures/ui`.

## Procedimiento normal de actualización

### Caso 1: solo cambian datos de items/loot/drops

Usa este flujo:

1. Actualiza en tu clon de `Worldshift` estos archivos:
   - `data/db/items/items.tsv`
   - `data/db/items/loot.tsv`
   - `data/db/items/loot index.tsv`
   - `data/db/items/drop.tsv`
   - `data/db/items/humansspecs.dt`
   - `data/db/items/mutantsspecs.dt`
   - `data/db/items/aliensspecs.dt`
   - `data/db/units/**/*.dt`
   - `data/texts/en/items.tsv`
   - `data/texts/en/missions.tsv`
2. Desde la raíz del proyecto Flutter, ejecuta:

```bash
dart run tool/refresh_worldshift_item_data.dart
flutter pub get
```

3. Lanza la app.
4. Verifica:
   - que el buscador encuentra nombres nuevos
   - que los items nuevos aparecen en la lista
   - que los items con origen muestran mapa/contexto
   - que los items sin origen siguen apareciendo, pero sin etiqueta de origen
   - que el filtro de atributos muestra stats nuevos con nombre legible
   - que los filtros de unidad, slot y mapa siguen teniendo todas las opciones esperadas

### Caso 2: además cambian iconos, slots o frames de items

Haz primero el flujo normal anterior y luego:

1. Copia los atlas DDS nuevos al repo:
   - `assets/ddsFiles/items.dds`
   - `assets/ddsFiles/item_frames.dds`
2. Comprueba que existen también en el clon de `Worldshift`:
   - `data/db/items/globals.dt`
   - `data/db/ui/inventory.lua`
3. Ejecuta:

```bash
dart run tool/generate_named_item_icons.dart
flutter pub get
```

Esto regenera:

- `assets/generated/item_icons/named/icons/`
- `assets/generated/item_icons/named/frames/`
- `assets/generated/item_icons/named/overlays/`
- `assets/generated/item_icons/named/item_icon_name_index.json`

## Caso opcional: cambian iconos o atlas de unidades

Esto no siempre hace falta. Los datos de unidades ya se regeneran con el script maestro. Solo necesitas estos pasos extra si además cambian atlas DDS o iconos:

```bash
dart run tool/generate_worldshift_assets.dart
dart run tool/generate_named_unit_icons.dart
dart run tool/generate_named_commander_icons.dart
dart run tool/generate_named_environment_unit_icons.dart
dart run tool/rebuild_shared_named_units.dart
flutter pub get
```

Con eso se actualizan:

- `assets/data/units.json`
- iconos nombrados de unidades y officers
- carpeta consolidada `assets/generated/unit_icons/named/units/`

## Archivos que deberías revisar después de cada actualización

Para una comprobación rápida, revisa estos archivos:

- `assets/data/item_origin_index.json`
- `lib/data/item_list_generated.dart`
- `lib/data/data.dart`
- `lib/data/item.dart`
- `assets/generated/item_icons/named/item_icon_name_index.json`
- `assets/data/units.json` si también hubo cambios de unidades

## Qué esperar del índice de orígenes

`assets/data/item_origin_index.json` no significa que todos los items tengan loot.

Es normal que existan items definidos en `items.tsv` que no aparezcan en `loot.tsv`.
La app ya está preparada para mostrarlos igualmente en el listado, simplemente sin etiqueta de origen.

## Validación rápida recomendada

Después de actualizar:

1. Abre la lista de items.
2. Busca un item nuevo que sepas que existe.
3. Comprueba un item con origen conocido.
4. Comprueba un item sin origen directo.
5. Abre el filtro por slot y unidad para ver que siguen funcionando.
6. Prueba algún stat nuevo en el filtro de atributos.

## Comandos de referencia

### Actualización mínima

```bash
dart run tool/refresh_worldshift_item_data.dart
flutter pub get
```

### Actualización de datos + iconos de items

```bash
dart run tool/refresh_worldshift_item_data.dart
dart run tool/generate_named_item_icons.dart
flutter pub get
```

### Actualización completa si también cambian iconos de unidades

```bash
dart run tool/refresh_worldshift_item_data.dart
dart run tool/generate_named_item_icons.dart
dart run tool/generate_named_unit_icons.dart
dart run tool/generate_named_commander_icons.dart
dart run tool/generate_named_environment_unit_icons.dart
dart run tool/rebuild_shared_named_units.dart
flutter pub get
```

### Solo reextraer buffs/debuffs manualmente

```bash
dart run tool/extract_worldshift_ui_icons.dart "C:\Users\sergi\Desktop\Proyectos\Worldshift\data\textures\ui" "C:\Tools\texconv\texconv.exe"
dart run tool/generate_worldshift_assets.dart "C:\Users\sergi\Desktop\Proyectos\Worldshift\data\db\units"
dart run tool/generate_status_effect_icon_index.dart "C:\Users\sergi\Desktop\Proyectos\Worldshift\data\db"
dart run tool/generate_ui_icon_name_indexes.dart
```

## Nota para futuras sesiones

Cuando quieras repetir este proceso en otra conversación, la instrucción útil es:

`Revisa docs/item-data-update-workflow.md, sincroniza los archivos de Worldshift y ejecuta la actualización completa o mínima según haga falta.`
