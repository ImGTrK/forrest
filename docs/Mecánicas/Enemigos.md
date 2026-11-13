---
tipo: mecánica
estado: hecho
version: 0.1
hito: 3
---
# Enemigos

> Criaturas del bosque que hacen que explorar tenga riesgo.

## Cómo funciona
- **Enemigo básico:** idle → persigue al verte (80 px) → **amago de 0.35 s** → muerde → retrocede.
  El amago hace el ataque legible y esquivable con dash.
- Medio corazón de daño, 3 de vida (+1 cada 3 de profundidad efectiva).
- Cuesta 3 de presupuesto y aparece desde profundidad 1: de día la primera zona es segura; de noche, no.
- Muerto, no reaparece en esa zona durante el run.

## Se conecta con
- [[Combate]]: cómo se los enfrenta.
- [[Presupuesto de dificultad]]: cuántos y dónde.
- [[Reloj]]: de noche hay más y antes.
- [[Tablón de misiones]]: misiones de cazar N enemigos.

## Números
[[BALANCE]] § Combate.

## Código
`scenes/entities/enemies/enemy.gd` (base) · `enemy_basic.gd` · `data/spawns/enemy_basic.tres`. Cómo sumar uno: [[Arquitectura]].

## Ideas y pendientes
- ✅ **Hito 8:** clase base `Enemy`; `EnemyBasic` es su primer hijo. El tipo sale de `SpawnEntry.enemy_script`.
- **0.2 (hito 10):** **Lanzador** (quieto, dispara esporas a distancia) y **Embestidor** (raspa el piso, embiste en línea recta, se aturde si choca).
- Campamento enemigo como evento: [[Plantillas de zona y eventos]].
- Jefes y voladores: [[Ideas para la 0.3]].
