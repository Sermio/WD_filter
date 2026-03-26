# Iconos de unidades desde atlas DDS

Este proyecto obtiene los iconos de unidades leyendo dos piezas de información del juego:

1. La clase de icono de la unidad: `commander`, `officer` o `unit`.
2. La coordenada del icono dentro del atlas: `icon = col,row`.

## De dónde sale cada dato

### 1. Qué atlas usa cada clase

La fuente de verdad está en `Worldshift/data/db/ui/consts.lua`:

- `officer` usa `data/textures/ui/officer_icons.dds` con celdas `38x48`
- `officer_sel` usa `data/textures/ui/officers_icons_small.dds` con celdas `38x38`
- `officer_70` usa `data/textures/ui/officers-70x70.dds` con celdas `70x70`
- `unit` usa `data/textures/ui/units.dds` con celdas `38x38`
- `unit_70` usa `data/textures/ui/units-70x70.dds` con celdas `70x70`
- `commander` usa `data/textures/ui/faction_leaders.dds` con celdas `77x98`

Para la ficha de detalle de `WD_filter` se usa el atlas `*_70` (officers → `officers-70x70.dds`, units → `units-70x70.dds`), por tamaño visual en la app.

### 2. Qué celda corresponde a cada unidad

Cada `.dt` define algo como:

```dts
officer = 1
icon = 1,4
```

o bien:

```dts
commander = 1
icon = 2,1
conv_icon_row = 4
conv_icon_col = 3
```

La app parsea esos campos en:

- `unitIconClass`
- `mainIconCol`, `mainIconRow`
- `conversationIconCol`, `conversationIconRow`

## Regla aplicada en WD_filter

Para la pantalla de detalle:

- Si `unitIconClass == officer` -> `assets/generated/unit_icons/officers_70/r{row}_c{col}.png` (desde `officers-70x70.dds`)
- Si `unitIconClass == unit` -> `assets/generated/unit_icons/units_70/r{row}_c{col}.png`
- Si `unitIconClass == commander` -> fallback actual a `conversation_icons.dds` si se extrae en el futuro

## Cómo se extrae un atlas DDS

Se usa `texconv` para convertir el `.dds` a `.png`, y después se divide en una rejilla fija.

Script genérico:

```powershell
cd "c:\Users\sergi\Desktop\Proyectos\WD_filter"
dart run tool/extract_fixed_ui_atlas.dart "assets\ddsFiles\officers-70x70.dds" "assets\generated\unit_icons\officers_70" 70 70 "C:\Tools\texconv\texconv.exe"
dart run tool/extract_fixed_ui_atlas.dart "assets\ddsFiles\units-70x70.dds" "assets\generated\unit_icons\units_70" 70 70 "C:\Tools\texconv\texconv.exe"
```

El script:

1. Convierte el `.dds` con `texconv`.
2. Recorre el atlas con una rejilla fija `cellWidth x cellHeight`.
3. Guarda cada recorte como `r{row}_c{col}.png`.
4. Genera `atlas_index.json` con la metadata.
5. Descarta celdas vacías usando detección simple de fondo.

## Cómo obtener iconos con nombre de unidad

Una vez extraídos los atlas 70×70, se puede generar una copia nombrada por unidad
leyendo `assets/data/units.json`, que ya contiene:

- `unitIconClass`
- `mainIconRow`
- `mainIconCol`

Comando:

```powershell
cd "c:\Users\sergi\Desktop\Proyectos\WD_filter"
dart run tool/generate_named_unit_icons.dart
```

Salida:

- `assets/generated/unit_icons/named/units/<unitId>.png`
- `assets/generated/unit_icons/named/officers/<unitId>.png`
- `assets/generated/unit_icons/named/unit_icon_name_index.json`

Ejemplos:

- `assets/generated/unit_icons/named/officers/arbiter.png`
- `assets/generated/unit_icons/named/units/trooper.png`
- `assets/generated/unit_icons/named/officers/surgeon.png`

Esto permite reutilizar iconos directamente por nombre sin recalcular `row/col`
en otras pantallas, exports o utilidades.

## Cómo reutilizar esta lógica para otros atlas

La lógica funciona siempre que conozcas:

1. El archivo DDS correcto.
2. El tamaño de cada celda.
3. Si el índice del juego es `icon = col,row` o `row,col`.

Ejemplos:

- `conversation_icons.dds` -> `49x49`
- `officers_icons_small.dds` -> `38x38`
- `officer_icons.dds` -> `38x48`
- `officers-70x70.dds` -> `70x70`
- `units.dds` -> `38x38`
- `units-70x70.dds` -> `70x70`

Si en Lua aparece una lógica como:

```lua
local x = (icon[1]-1) * t.size[1]
local y = (icon[2]-1) * t.size[2]
```

entonces el atlas se puede reconstruir exactamente con este mismo enfoque.
