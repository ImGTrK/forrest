---
tipo: idea
estado: hecho
version: 0.2
hito: 11
---
# Rasgos raros

> Que encontrar algo raro se sienta especial y que fabricar con eso dé *tu* herramienta.

## La idea
- Al recolectar, a veces (poco) el recurso sale con un **rasgo con nombre**, además de sus stats:
  - *Madera de corazón*: +durabilidad.
  - *Piedra veteada*: +poder.
  - *Hierro templado*: −peso.
  - (lista a definir; 2-3 por material)
- La chance sube con la profundidad, la hora (madrugada) y en eventos ([[Plantillas de zona y eventos]]).
- Al fabricar, la herramienta **hereda los rasgos** de los ingredientes elegidos. Una herramienta puede juntar varios.
- Los ítems con rasgo llevan una marca (estrellita) y un borde de color por rareza.

## Por qué
- Pilar **orgullo por el botín**: hoy un recurso bueno es solo un número más alto.
- Hace más interesante el [[Crafting]] sin volverlo tedioso: la decisión es *qué* ingrediente usar.

## Afecta a
- [[ADN de recursos]] · [[Crafting]] · [[Herramientas y durabilidad]] · [[Tablón de misiones]] (misión "traé un ítem con rasgo").

## Cómo quedó (hito 11)
- 3 rasgos por material, uno malo. Lista y efectos en `data/traits/*.tres`:
  - Madera: *Corazón de roble* (+25 % durabilidad), *Madera liviana* (−30 % peso), *Carcomida* (−25 % durabilidad).
  - Piedra: *Piedra veteada* (+20 % poder), *Piedra de río* (+20 % durabilidad), *Agrietada* (−15 % poder).
  - Cobre: *Cobre rojo* (+15 % poder, +10 % durabilidad), *Cobre nativo* (+30 % durabilidad), *Oxidado* (−20 % durabilidad).
  - Hierro: *Hierro templado* (−30 % peso, +5 % poder), *Hierro estelar* (+30 % poder, más raro), *Quebradizo* (−30 % durabilidad).
- Chance 5 % + 2 % por profundidad (tope 35 %). Árbol antiguo y veta brillante: uno bueno seguro.
- Tope de **2** por herramienta; los malos entran primero (no se tapan sumando buenos). Repetidos no suman.
- Reparar **conserva** los rasgos.
- El peso del rasgo ya se nota en el recurso; en la herramienta llega a través del peso de los materiales.
- Código: `data/trait_data.gd`, `scripts/traits.gd` ([[Arquitectura]]).
