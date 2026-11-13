# Números de balance

Todos los valores para ajustar jugando, con el archivo donde se cambian.
Los `.tres` se editan desde el Inspector de Godot; las constantes, en el script.

## Tiempo y energía
| Qué | Valor | Dónde |
|---|---|---|
| Segundos reales por hora de juego | 30 | `autoload/clock.gd` → `REAL_SECONDS_PER_HOUR` |
| Hora de inicio | 06:00 | `clock.gd` → `START_HOUR` |
| Horas al dormir (al azar) | 5-9 | `clock.gd` → `SLEEP_HOURS` |
| Curva de dificultad/rareza por hora | ×1 → ×2, +0 → +3 | `clock.gd` → `DIFFICULTY_KEYS` |
| Visión nocturna (horas) | se cierra 18-21, abre 03-05 | `clock.gd` → `night_factor()` |
| Energía máxima | 100 (+10 por mejora) | `autoload/energy.gd` → `MAX`; mejora en `game_state.gd` → `UPGRADE_ENERGY` |
| Drenaje por hora | 5 | `energy.gd` → `DRAIN_PER_HOUR` |
| Costo por golpe / dash | 0.4 / 0.6 | `energy.gd` → `ACTION_COST`; `player.gd` → `DASH_ENERGY` |
| Recarga por hora dormida | 12 | `energy.gd` → `RECHARGE_PER_SLEEP_HOUR` |
| Umbrales aviso / debuff | 50% / 20% | `energy.gd` → `TIRED_RATIO`, `EXHAUSTED_RATIO` |
| Debuff agotado | velocidad ×0.7, golpes ×2 más lentos | `energy.gd` → `EXHAUSTED_*` |

## Pérdidas y mochila
| Qué | Valor | Dónde |
|---|---|---|
| Pérdida al colapsar / morir | 25% / 50% de lo cargado (sin equipo) | `autoload/game_state.gd` → `COLLAPSE_LOSS`, `DEATH_LOSS` |
| Mochila | 6×4 celdas | `game_state.gd` → `BAG_SIZE` |
| Peso máximo | 18 kg (+2 por mejora) | `game_state.gd` → `MAX_WEIGHT`, `UPGRADE_WEIGHT` |
| Debuff de sobrepeso | velocidad ×0.5 | `game_state.gd` → `OVERWEIGHT_SPEED_MULT` |
| Rangos de ADN y peso de cada recurso | — | `data/items/wood.tres`, `stone.tres`, `iron.tres` |
| Tamaño en grilla | madera 1×2, resto 1×1 | `grid_size` en cada `data/items/*.tres` |

## Bosque
| Qué | Valor | Dónde |
|---|---|---|
| Tamaño de zona | 40×40 tiles | `scripts/zone_generator.gd` → `ZONE_TILES` |
| Presupuesto | 6 + 3 × profundidad (× hora) | `zone_generator.gd` → `BASE_BUDGET`, `BUDGET_PER_DEPTH` |
| Probabilidad de puerta | 45% | `zone_generator.gd` → `DOOR_CHANCE` |
| Decoración por zona | 6-11 arbustos | `zone_generator.gd` → `DECORATION_RANGE` |
| Costo, peso en la tabla, profundidad mínima | — | `data/spawns/*.tres` (`cost`, `weight`, `weight_per_depth`, `min_depth`) |
| Dureza y herramienta requerida | árbol 6, roca 5, veta 12 (pico 1) | `data/spawns/*.tres` (`hardness`, `tool_type`, `min_tool_level`) |
| Poder a mano | 1.5 | `scenes/entities/harvestable.gd` → `HAND_POWER` |

## Combate
| Qué | Valor | Dónde |
|---|---|---|
| Vida del jugador | 6 = 3 corazones (+2 por mejora) | `scenes/player/player.gd` → `MAX_HEALTH`; `game_state.gd` → `UPGRADE_HEALTH` |
| Ataque | arco 120°, alcance 22 px, cooldown 0.35 s, puños 1 de daño | `player.gd` → `ATTACK_*`, `FIST_DAMAGE` |
| Dash | 288 px/s, 0.15 s, cooldown 1.5 s | `player.gd` → `DASH_*` |
| I-frames al recibir daño | 0.6 s | `player.gd` → `HURT_IFRAMES` |
| Enemigo básico | 48 px/s, percepción 80 px, amago 0.35 s, 1 de daño, vida 3 (+1 c/3 de profundidad) | `scenes/entities/enemies/enemy_basic.gd` (valores por defecto y knockback en `enemy.gd`) |

## Crafting y herramientas
| Qué | Dónde |
|---|---|
| Ingredientes, fórmulas (base, min, max, stat de origen), material de reparación | `data/recipes/*.tres` |
| Nivel y tipo de cada herramienta | `data/items/stone_axe.tres`, etc. (`tool_level`, `tool_type`) |
| Radio de la linterna / minutos de aceite | `data/recipes/lantern.tres`, `oil.tres` |
| Visión sin luz / oscuridad máxima | `scenes/main.gd` → `VISION_NO_LIGHT`, `NIGHT_DARKNESS` |

## Misiones
| Qué | Valor | Dónde |
|---|---|---|
| Misiones activas | 3 | `autoload/missions.gd` → `ACTIVE_COUNT` |
| Escalado | entregar 3+n (calidad 30+5n, máx 70), profundidad 2+n, cazar 2+n | `missions.gd` → `generate()` |
| Recompensas | +2 kg / +10 energía / +1 corazón | `game_state.gd` → `UPGRADE_*` |
