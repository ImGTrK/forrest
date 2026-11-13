---
tipo: referencia
---
# Arquitectura del código

> Cómo está armado el código para sumar contenido sin duplicar lógica (hito 8).
> Equivalencias con Unity entre paréntesis.

## Herencia: clases base con métodos virtuales
Como una clase abstracta de C#: la base hace todo lo común y el hijo sobrescribe solo lo que cambia
(en GDScript no hace falta `override`: alcanza con definir el método con el mismo nombre).

### `Interactable` — `scenes/entities/interactable.gd`
Todo lo que se usa con E. La base pone colisión, sprite, cartel, contorno de foco, el grupo
`"interactable"` (lo que busca el jugador) y la señal `used`.

| Hijo | Qué sobrescribe |
|---|---|
| `Chest`, `Bed`, `Bench` | Nada: solo tamaño, textura y cartel en `_init()` |
| `Board` | `_collision_rect()` (solo las patas) y `_draw_overlay()` (el "!" de misión lista) |
| `Harvestable` | `_on_interact()` (golpear), `_collision_rect()`, `is_interactive()` (la decoración no se usa) |

Métodos virtuales: `_on_interact(by)`, `_collision_rect()`, `is_interactive()`, `_draw_overlay()`.

### `Enemy` — `scenes/entities/enemies/enemy.gd`
Máquina de estados común: `IDLE → CHASE → WINDUP (amago) → ATTACK → RECOVER`, más
`KNOCKBACK`, `STUNNED` y `DEAD`. Vida, destello, knockback y muerte (marca la zona,
avisa a [[Tablón de misiones|Missions]], llama a `_drop()`) están en la base.

| Método virtual | Por defecto | Para qué lo cambiaría un hijo |
|---|---|---|
| `_chase_velocity()` | derecho al jugador | mantener distancia (lanzador), volar |
| `_wants_attack()` | a distancia de ataque | atacar de lejos |
| `_on_windup_start()` | nada | fijar dirección de embestida o de disparo |
| `_attack()` | mordida cuerpo a cuerpo | disparar un proyectil, pasar a `ATTACK` para embestir |
| `_attack_velocity()` | termina enseguida | moverse durante la embestida; terminar con `end_attack()` |
| `_on_moved()` | nada | detectar choque contra una pared → `stun()` |
| `_knockback_scale()` | 1 | enemigos pesados que no se empujan |
| `_animate()` | nada | elegir el frame de la hoja |
| `_drop()` | nada | soltar algo al morir |

Hijos: `EnemyBasic` (hito 8). Planeados: lanzador y embestidor ([[Enemigos]], hito 10).

**Sumar un enemigo nuevo:** crear `enemy_x.gd` con `extends Enemy`, setear stats en `_init()`,
sobrescribir lo necesario, y crear su `data/spawns/enemy_x.tres` con `is_enemy = true` y
`enemy_script` apuntando al script. El generador no se toca.

## Composición: componentes como nodos hijos
Como agregar un `MonoBehaviour` a un GameObject: se suma con `add_child(...)` y cualquiera lo puede usar.

| Componente | Archivo | Lo usan |
|---|---|---|
| `Health` | `scripts/health.gd` | jugador, enemigos |
| `HitFlash` | `scripts/components/hit_flash.gd` | recursos (destello + sacudida), enemigos (destello rojo) |

**Regla:** si es "un tipo de cosa" (un enemigo, algo usable) → herencia. Si es "una capacidad"
que pueden tener cosas distintas (vida, destello, más adelante soltar loot) → componente.

## Datos (Resources ≈ ScriptableObjects)
`ItemData`, `SpawnEntry`, `RecipeData` en `data/`. Los números se cambian en los `.tres` desde el
Inspector, sin tocar código. Ver [[BALANCE]].

## Guardado versionado
Ver [[Guardado]]. Cambiar el formato = subir `VERSION` y agregar una migración.

## Tests
`tests/RunTests.tscn` corre 8 suites (una por sistema), cada una con partida nueva.
Para sumar una: `tests/suites/test_x.gd` con `extends TestSuite` y agregarla a `SUITES`.
