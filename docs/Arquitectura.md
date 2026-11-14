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
| `_interruptible()` | sí | que un golpe no corte la embestida |
| `_draw_telegraph()` | nada | dibujar el aviso del amago (mira, flecha) |
| `_animate()` | hoja estándar de 4 filas según el estado | efectos extra (temblar al raspar) |
| `_drop()` | nada | soltar algo al morir |

Hijos: `EnemyBasic` (erizo), `EnemySpitter` (Lanzador) y `EnemyCharger` (Embestidor). Ver [[Enemigos]].

**Hoja estándar de enemigo:** 64×64 = 4×4 frames de 16×16, mirando a la derecha. Filas:
0 quieto · 1 moverse · 2 amago (cols 0-1) + golpe (cols 2-3) · 3 muerte (se reproduce una vez).
La base elige el frame sola; el hijo solo pone `hframes = 4` y `vframes = 4`.
La base también pone el feedback: destello blanco, número de daño, partículas, freno de golpe,
sonido, barra de vida (herido) y estrellitas (aturdido).

### `Projectile` — `scenes/entities/projectile.gd`
Proyectil genérico (Area2D): vuela recto, se rompe contra el mundo, daña al jugador, el dash lo
atraviesa. No se hereda: se configura (`velocity`, `damage`, `texture`, `lifetime`…). La colisión va a
ras del piso y el sprite se dibuja `height` px más arriba. `Projectile.spawn(padre, pos, vel, daño)`.

**Sumar un enemigo nuevo:** crear `enemy_x.gd` con `extends Enemy`, setear stats en `_init()`,
sobrescribir lo necesario, y crear su `data/spawns/enemy_x.tres` con `is_enemy = true` y
`enemy_script` apuntando al script. El generador no se toca.

## Composición: componentes como nodos hijos
Como agregar un `MonoBehaviour` a un GameObject: se suma con `add_child(...)` y cualquiera lo puede usar.

| Componente | Archivo | Lo usan |
|---|---|---|
| `Health` | `scripts/health.gd` | jugador, enemigos |
| `HitFlash` | `scripts/components/hit_flash.gd` | recursos (destello + sacudida), enemigos (destello blanco) |

**Regla:** si es "un tipo de cosa" (un enemigo, algo usable) → herencia. Si es "una capacidad"
que pueden tener cosas distintas (vida, destello, más adelante soltar loot) → componente.

## Servicios globales del hito 10 (autoloads)
| Autoload | Para qué | Uso |
|---|---|---|
| `Fx` | "juice": freno de golpe (baja `Engine.time_scale` un instante), sacudida de cámara por trauma, números de daño, partículas | `Fx.hitstop()`, `Fx.shake(0.3)`, `Fx.number(nodo, 2)`, `Fx.burst(nodo, colores)` |
| `AudioManager` | buses Music/SFX/UI, pool de reproductores, variantes al azar | `AudioManager.play(&"hit")` |

Sonidos: si existe `assets/audio/sfx/<id>.wav` (o `<id>_1.wav`, `<id>_2.wav`…) se usa ese archivo;
si no, `SfxSynth` (`scripts/sfx_synth.gd`) sintetiza un placeholder. Ids actuales: ver `SfxSynth.RECIPES`.

## Rasgos raros (hito 11)
- `TraitData` (`data/trait_data.gd`): un `.tres` por rasgo en `data/traits/` con material, si es malo,
  peso de aparición y `effects` (stat → multiplicador).
- `Traits` (`scripts/traits.gd`): `roll()` al recolectar (lo llama `DNA.generar_recurso`), `apply()`
  sobre los stats, `inherit()` al fabricar (lo usa `Crafting.preview`). `ItemInstance.traits` los guarda.
- Sumar un rasgo: crear el `.tres` y agregarlo a `Traits.ALL`.

## Datos (Resources ≈ ScriptableObjects)
`ItemData`, `SpawnEntry`, `RecipeData` en `data/`. Los números se cambian en los `.tres` desde el
Inspector, sin tocar código. Ver [[BALANCE]].

## Guardado versionado
Ver [[Guardado]]. Cambiar el formato = subir `VERSION` y agregar una migración.

## Tests
`tests/RunTests.tscn` corre 11 suites (una por sistema), cada una con partida nueva.
Para sumar una: `tests/suites/test_x.gd` con `extends TestSuite` y agregarla a `SUITES`.
