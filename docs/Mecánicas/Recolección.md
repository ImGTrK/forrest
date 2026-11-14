---
tipo: mecánica
estado: hecho
version: 0.1
hito: 5
---
# Recolección

> Golpear árboles, rocas y vetas hasta romperlos para obtener un recurso con ADN.

## Cómo funciona
- Cada recurso tiene **dureza**; cada golpe le resta el **poder** de la herramienta. A mano el poder es 1.5.
- Árbol (dureza 6, hacha) y roca (5, pico) se pueden romper a mano, lento. La veta de cobre (9) exige **pico nivel 1** y la de hierro (12) **pico nivel 2** (hito 11).
- A veces lo recolectado sale con un [[Rasgos raros|rasgo raro]] (más chance cuanto más profundo).
- Al romperse, el recurso entra a la mochila con stats rolados ([[ADN de recursos]]).
- Si la mochila está llena, no se puede golpear (y no gasta energía).
- Lo recolectado no reaparece si volvés a la zona en el mismo run.

## Se conecta con
- [[Herramientas y durabilidad]]: poder, nivel requerido y desgaste por golpe.
- [[ADN de recursos]]: lo que obtenés.
- [[Inventario y peso]]: tiene que entrar en la mochila.
- [[Energía y sueño]]: cada golpe cuesta 0.4 de energía.
- [[Presupuesto de dificultad]]: decide qué recursos hay.

## Números
[[BALANCE]] § Bosque (dureza, poder a mano).

## Código
`scenes/entities/harvestable.gd` · `data/spawns/tree.tres`, `rock.tres`, `iron_vein.tres`.

## Ideas y pendientes
- ✅ Hito 11: escalera piedra → cobre → hierro.
- Recursos especiales de eventos (árbol antiguo, veta brillante): [[Plantillas de zona y eventos]].
