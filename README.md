# Forrest (nombre provisional)

Roguelite top-down de exploración con hub persistente y bosque procedural. Godot 4.7.1 / GDScript.
Diseño completo en [docs/GDD.md](docs/GDD.md).

## Cómo correrlo
Abrí `project.godot` con Godot 4.7.1 y apretá F5.

**Controles:** WASD/flechas para moverte · E/Espacio para interactuar o golpear · Tab/I para el inventario · Esc para cerrar menús.

## Estructura
| Carpeta | Qué hay |
|---|---|
| `autoload/` | Singletons globales: `GameState` (persistente), `ForestSession` (cache del bosque), `InputSetup` |
| `data/` | Definiciones (`ResourceType`, `SpawnEntry`) y sus `.tres`: acá se ajustan stats, costos y pesos sin tocar código |
| `scripts/` | Lógica pura: `ZoneGenerator` (presupuesto + tabla ponderada), `DNA`, `ZoneData`, `PlaceholderTiles` |
| `scenes/` | `Main`, jugador, hub, zona del bosque, entidades y UI |
| `tests/` | Tests headless |
| `assets/` | Arte (pendiente de integrar) |

## Tests
```bash
GODOT="/d/Desktop/Archivos/Godot/Godot_v4.7.1-stable_win64_console.exe"
"$GODOT" --headless --path . --script res://tests/test_generation.gd   # reglas del generador, 200 runs
"$GODOT" --headless --path . res://tests/TestLoop.tscn                 # loop completo con el juego real
```
