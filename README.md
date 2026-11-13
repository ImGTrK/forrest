# Forrest (nombre provisional)

Roguelite top-down de exploración con hub persistente y bosque procedural. Godot 4.7.1 / GDScript.
Diseño completo en [docs/GDD.md](docs/GDD.md) · plan de hitos en [docs/ROADMAP.md](docs/ROADMAP.md) ·
números para balancear en [docs/BALANCE.md](docs/BALANCE.md) ·
lista de sprites y medidas en [assets/README.md](assets/README.md).

## Cómo correrlo
Abrí `project.godot` con Godot 4.7.1 y apretá F5. Arranca en el menú principal.

La partida se guarda sola en el pueblo (`%APPDATA%/Godot/app_userdata/Forrest/save.json`).
Si cerrás estando en el bosque, volvés al último guardado.

**Controles:** WASD/flechas mover · clic izquierdo o J atacar · Espacio/Shift dash · E interactuar · L linterna · Tab/I inventario · Esc pausa / cerrar menús.

**Inventario:** clic agarrar/soltar (sobre otro ítem: intercambia) · R o clic derecho rotar · Supr/X tirar · Shift+clic pasar entre mochila y almacén · botón "Ordenar" compacta.

## Estructura
| Carpeta | Qué hay |
|---|---|
| `autoload/` | Singletons globales: `GameState` (persistente), `ForestSession` (cache del bosque), `InputSetup` |
| `data/` | Definiciones (`ItemData`, `SpawnEntry`, `RecipeData`) y sus `.tres` en `data/items/`, `data/spawns/` y `data/recipes/`: acá se ajustan stats, tamaños, pesos, costos y recetas sin tocar código |
| `scripts/` | Lógica pura: `ZoneGenerator` (presupuesto + tabla ponderada), `DNA`, `ItemInstance`, `GridInventory`, `Crafting`, `Health`, `ZoneData`, `TerrainTiles` |
| `scenes/` | `Main`, jugador, hub, zona del bosque, entidades y UI |
| `tests/` | Tests headless |
| `assets/` | Sprites y tilesets (placeholders con medidas exactas, reemplazables) |
| `tools/` | Scripts de utilidad (generador de placeholders) |

## Tests
```bash
GODOT="/d/Desktop/Archivos/Godot/Godot_v4.7.1-stable_win64_console.exe"
"$GODOT" --headless --path . --script res://tests/test_generation.gd   # reglas del generador, 200 runs
"$GODOT" --headless --path . res://tests/TestLoop.tscn                 # loop completo con el juego real
```
