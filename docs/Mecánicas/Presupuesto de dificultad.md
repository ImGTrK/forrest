---
tipo: mecánica
estado: hecho
version: 0.1
hito: 1
---
# Presupuesto de dificultad

> En vez de tablas fijas, cada zona recibe "puntos" y los gasta tirando entidades de una tabla ponderada.

## Cómo funciona
- `presupuesto = (6 + 3 × profundidad) × multiplicador de la hora`.
- Mientras quede presupuesto, se tira una entidad de la tabla (árbol, roca, veta, enemigo…) según su peso; si su costo entra, aparece.
- Cada entrada tiene `cost`, `weight`, `weight_per_depth` (lo raro se vuelve más común al profundizar) y `min_depth`.
- La **rareza** de la hora se suma a la profundidad: de madrugada puede salir hierro al lado del pueblo.
- La decoración (arbustos) va aparte y no gasta presupuesto.

## Se conecta con
- [[Bosque procedural]]: lo usa para llenar cada zona.
- [[Reloj]]: multiplicador ×1 → ×2 y rareza +0 → +3 según la hora.
- [[Recolección]]: árboles, rocas y vetas salen de acá.
- [[Enemigos]]: cuestan 3 de presupuesto.
- [[ADN de recursos]]: la profundidad efectiva mejora los rolls.

## Pilar que refuerza
- Nada es 100% predecible, y escala sin escribir tablas por nivel.

## Números
[[BALANCE]] § Bosque. Las entradas se editan en `data/spawns/*.tres`.

## Código
`scripts/zone_generator.gd` · `data/spawn_entry.gd` · `data/spawns/`.

## Ideas y pendientes
- Plantillas que cambian la tabla según el tipo de zona: [[Plantillas de zona y eventos]].
