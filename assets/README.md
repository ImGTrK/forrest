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
| `player.png` | **64×16** | 4 frames de 16×16: 0 mirando abajo · 1 arriba · 2 izquierda · 3 derecha. La colisión es 10×6 a los pies |

## Mundo — `assets/sprites/world/`

| Archivo | Tamaño | Usado en |
|---|---|---|
| `chest.png` | **16×16** | Almacén del pueblo (`scenes/entities/chest.gd`) |
| `tree.png` | **32×32** | Árbol, da Madera (`data/spawns/tree.tres`, ocupa 2×2 tiles) |
| `rock.png` | **16×16** | Roca, da Piedra (`data/spawns/rock.tres`) |
| `iron_vein.png` | **16×16** | Veta, da Hierro (`data/spawns/iron_vein.tres`) |
| `bush.png` | **16×16** | Arbusto decorativo, bloquea el paso (`data/spawns/bush.tres`) |

## Íconos de ítems — `assets/sprites/items/`

| Archivo | Tamaño | Usado en |
|---|---|---|
| `wood.png` | **16×16** | Madera en inventario/almacén (`data/resources/wood.tres`) |
| `stone.png` | **16×16** | Piedra |
| `iron.png` | **16×16** | Hierro |

## Regenerar placeholders
Si borrás un PNG y querés que vuelva el placeholder (nunca pisa archivos existentes):
```bash
GODOT="/d/Desktop/Archivos/Godot/Godot_v4.7.1-stable_win64_console.exe"
"$GODOT" --headless --path . --script res://tools/generate_placeholders.gd
"$GODOT" --headless --path . --import
```
Cada sprite nuevo que agregue un hito se suma a `tools/generate_placeholders.gd` y a esta tabla.
