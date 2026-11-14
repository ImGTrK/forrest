---
tipo: mecánica
estado: hecho
version: 0.1
hito: 10
---
# Enemigos

> Criaturas del bosque que hacen que explorar tenga riesgo.

## Cómo funciona
- **Enemigo básico:** idle → persigue al verte (80 px) → **amago de 0.35 s** → muerde → retrocede.
  El amago hace el ataque legible y esquivable con dash.
- Medio corazón de daño, 3 de vida (+1 cada 3 de profundidad efectiva).
- Cuesta 3 de presupuesto y aparece desde profundidad 1: de día la primera zona es segura; de noche, no.
- **Lanzador** (hongo de sombrero ciruela, prof. 2+): se queda a ~64 px, apunta con una **mira de puntos**
  (0.6 s) y escupe una espora que vuela recto. Si te acercás huye; entre disparos te rodea de costado.
  Frágil (2 golpes). Se le gana cerrando distancia o esquivando la espora con dash (la atraviesa).
- **Embestidor** (jabalí-escarabajo, prof. 3+): lento y pesado. **Raspa el piso** 0.75 s (tiembla, levanta
  polvo, flecha de aviso) y embiste recto a 210 px/s. Pega un corazón entero. Si choca contra un árbol,
  roca o el cerco queda **aturdido 1.6 s** con estrellitas: la ventana para pegarle. En plena embestida los
  golpes no lo frenan y el knockback le hace poco.
- Todos usan la **hoja estándar** de 4 filas y el feedback común (destello, número, barra de vida, muerte animada).
- Muerto, no reaparece en esa zona durante el run.

## Se conecta con
- [[Combate]]: cómo se los enfrenta.
- [[Presupuesto de dificultad]]: cuántos y dónde.
- [[Reloj]]: de noche hay más y antes.
- [[Tablón de misiones]]: misiones de cazar N enemigos.

## Números
[[BALANCE]] § Combate.

## Código
`scenes/entities/enemies/enemy.gd` (base) · `enemy_basic.gd` · `enemy_spitter.gd` · `enemy_charger.gd` ·
`scenes/entities/projectile.gd` · `data/spawns/enemy_*.tres`. Cómo sumar uno: [[Arquitectura]].

## Ideas y pendientes
- ✅ **Hito 8:** clase base `Enemy`; `EnemyBasic` es su primer hijo. El tipo sale de `SpawnEntry.enemy_script`.
- ✅ **Hito 10:** Lanzador y Embestidor, proyectil reutilizable, hoja estándar de enemigo.
- Campamento enemigo como evento: [[Plantillas de zona y eventos]].
- Jefes y voladores: [[Ideas para la 0.3]].
