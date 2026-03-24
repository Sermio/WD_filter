# Workflow de iconos Buff/Debuff

Este documento explica como se extraen y validan los iconos de buffs/debuffs para que coincidan con el juego original.

## Fuente original (juego)

- Atlas: `Worldshift/data/textures/ui/buff_icons.dds`
- Render UI: `Worldshift/data/db/ui/selection.lua`
  - Los slots usan `slot.Icon:Set(v.icon_row, v.icon_col)`.
  - `Set(row, col)` recorta el atlas en base a esos indices.

## Scripts del repo

1. Extraccion de atlas UI:
   - `tool/extract_worldshift_ui_icons.dart`
2. Regeneracion de unidades parseadas:
   - `tool/generate_worldshift_assets.dart`
3. Indice de validacion de efectos de estado:
   - `tool/generate_status_effect_icon_index.dart`
4. Indices de nombres de iconos:
   - `tool/generate_ui_icon_name_indexes.dart`

## Comando recomendado (todo en uno)

```bash
dart run tool/refresh_worldshift_item_data.dart
```

Desde ahora este script ejecuta tambien los pasos de iconos de estado.

## Comandos manuales (solo buffs/debuffs)

```bash
dart run tool/extract_worldshift_ui_icons.dart "C:\Users\sergi\Desktop\Proyectos\Worldshift\data\textures\ui" "C:\Tools\texconv\texconv.exe"
dart run tool/generate_worldshift_assets.dart "C:\Users\sergi\Desktop\Proyectos\Worldshift\data\db\units"
dart run tool/generate_status_effect_icon_index.dart "C:\Users\sergi\Desktop\Proyectos\Worldshift\data\db"
dart run tool/generate_ui_icon_name_indexes.dart
```

## Salidas esperadas

- PNGs del atlas: `assets/generated/ui_icons/buff_icons/r*_c*.png`
- Unidades regeneradas: `assets/data/units.json`
- Indice de estado: `assets/generated/ui_icons/buff_icons/status_effect_icon_index.json`
- Indices de nombres: `assets/generated/ui_icons/*/icon_name_index.json`
