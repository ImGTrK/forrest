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
- Árbol (dureza 6, hacha) y roca (5, pico) se pueden romper a mano, lento. La veta de hierro (12) exige **pico nivel 1**.
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
- Hoy el pico de hierro (nivel 2) no desbloquea nada: [[Tercer escalón - cristal]].
- Recursos especiales de eventos (árbol antiguo, veta brillante): [[Plantillas de zona y eventos]].
