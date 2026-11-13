# Arte — lista de sprites

Todos los PNG de esta carpeta empiezan como **placeholders con las medidas exactas** que espera el código.
Para reemplazar uno: **pisá el archivo con el mismo nombre y el mismo tamaño**. Godot lo reimporta
solo al abrir el editor y el código no cambia.

- Resolución base: tiles de **16×16 px**. Filtro Nearest (pixel art nítido) ya configurado.
- Fondo transparente donde corresponda (todo menos el tileset).
- Origen: los sprites del mundo se dibujan desde la **esquina superior izquierda** de su celda;
  el jugador va **centrado** (con un ajuste de 2 px hacia arriba).
- Si un sprite necesita otro tamaño, avisá: hay que cambiar también la colisión/tamaño en el código o en el `.tres`.

## Tilesets — `assets/tilesets/`

| Archivo | Tamaño | Contenido |
|---|---|---|
| `terrain.png` | **64×16** | Tira de 4 tiles de 16×16, **en este orden**: 0 pasto · 1 pared (tiene colisión) · 2 piso del pueblo · 3 camino |

## Personaje — `assets/sprites/player/`

| Archivo | Tamaño | Contenido |
|---|---|---|
| `player.png` | **128×128** | Hoja de BarrenRoots: 8×8 frames de 16×16. **Filas** = dirección: 0 S · 1 SW · 2 W · 3 NW · 4 N · 5 NE · 6 E · 7 SE. **Columnas** 0-3 idle, 4-7 caminar (4 fps). La colisión es 10×6 a los pies |
| `sword.png` | **16×16** | Espada del swing, dibujada **apuntando hacia arriba** (el código la rota) |

## Enemigos — `assets/sprites/enemies/`

| Archivo | Tamaño | Contenido |
|---|---|---|
| `enemy_basic.png` | **32×16** | 2 frames de 16×16 (de `EnemyTemp.ase`): frame 0 parpadeo (0.1 s), frame 1 normal (2 s). Mira a la derecha; el código lo espeja |

## Mundo — `assets/sprites/world/`

| Archivo | Tamaño | Usado en |
|---|---|---|
| `chest.png` | **16×16** | Almacén del pueblo (`scenes/entities/chest.gd`) |
| `tree.png` | **32×32** | Árbol, da Madera (`data/spawns/tree.tres`, ocupa 2×2 tiles) |
| `rock.png` | **16×16** | Roca, da Piedra (`data/spawns/rock.tres`) |
| `iron_vein.png` | **16×16** | Veta, da Hierro (`data/spawns/iron_vein.tres`) |
| `bush.png` | **16×16** | Arbusto decorativo, bloquea el paso (`data/spawns/bush.tres`) |
| `bed.png` | **16×32** | Cama del pueblo, vertical, ocupa 1×2 tiles (`scenes/entities/bed.gd`) |

## Íconos de ítems — `assets/sprites/items/`

El ícono mide **`grid_size` × 16 px** del ítem (lo que ocupa en la mochila). En el almacén se achica a una celda.

| Archivo | Tamaño | Usado en |
|---|---|---|
| `wood.png` | **16×32** | Madera: ocupa **1×2 celdas** en la mochila (`data/items/wood.tres`) |
| `stone.png` | **16×16** | Piedra |
| `iron.png` | **16×16** | Hierro |

## UI / HUD — `assets/sprites/ui/`

La UI se ve al doble (viewport 640×360 escalado a 1280×720), así que 8 px de ícono ≈ alto de una línea de texto.

| Archivo | Tamaño | Contenido |
|---|---|---|
| `hearts/heart_full.png` | **16×16** | Corazón lleno (= 2 de vida) — de BarrenRoots |
| `hearts/heart_half.png` | **16×16** | Medio corazón |
| `hearts/heart_empty.png` | **16×16** | Corazón vacío |
| `slot.png` | **18×18** | Celda vacía de la grilla de inventario (16 px de ícono + 1 px de borde por lado) |
| `icon_weight.png` | **8×8** | Ícono junto a la barra de peso (la barra reusa `energy_bar_*`, teñida azul/rojo) |
| `icon_clock.png` | **8×8** | Ícono junto a la hora |
| `icon_energy.png` | **8×8** | Ícono junto a la barra de energía |
| `energy_bar_under.png` | **64×8** | Fondo/marco de la barra de energía |
| `energy_bar_fill.png` | **64×8** | Relleno de la barra. **Dibujalo en blanco/grises**: el HUD lo tiñe verde → amarillo → rojo según el cansancio |

## Fuente — `assets/fonts/`
`BoldPixels.ttf` (de BarrenRoots), configurada sin suavizado. Se usa como fuente por defecto en `scenes/ui/theme.tres` a 16 px.
⚠️ No es arte propio: revisá su licencia antes de publicar.

## Fuentes de Aseprite — `assets/source/`
Los `.ase` originales de BarrenRoots (`EnemyTemp`, `PlayerDash`, `temp_Sword`). Godot no los lee: hay que exportarlos a PNG.
Sin Aseprite instalado se puede usar el conversor incluido:
```bash
python tools/ase2png.py <carpeta_destino> assets/source/EnemyTemp.ase
```
`PlayerDash.ase` (4 frames, solo mirando abajo) todavía no se usa: el dash por ahora es el sprite semitransparente.

## Regenerar placeholders
Si borrás un PNG y querés que vuelva el placeholder (nunca pisa archivos existentes):
```bash
GODOT="/d/Desktop/Archivos/Godot/Godot_v4.7.1-stable_win64_console.exe"
"$GODOT" --headless --path . --script res://tools/generate_placeholders.gd
"$GODOT" --headless --path . --import
```
Cada sprite nuevo que agregue un hito se suma a `tools/generate_placeholders.gd` y a esta tabla.
