---
tipo: mecánica
estado: hecho
version: 0.1
hito: 5
---
# Crafting

> En la mesa del pueblo, elegís qué ejemplares de material usar y eso define los stats de lo que fabricás.

## Cómo funciona
- 11 recetas: hacha, pico y espada de piedra/madera, de cobre y de hierro, linterna y aceite.
- **Hito 11:** la herramienta hereda los [[Rasgos raros|rasgos]] de los materiales elegidos (tope 2; los
  malos entran primero). La vista previa muestra cuáles entran y cuáles quedan afuera.
- Usa materiales de la mochila **y** del almacén. Auto-elige los mejores; clic para cambiar.
- Fórmula: `stat = base × lerp(min, max, t)`, con `t` = promedio normalizado de un stat del material (ej. poder del hacha ← dureza de la piedra).
- Vista previa comparada con la mejor herramienta del mismo tipo que ya tenés.
- También repara (ver [[Herramientas y durabilidad]]).

## Se conecta con
- [[ADN de recursos]]: los stats de entrada.
- [[Herramientas y durabilidad]]: lo que sale.
- [[Noche y linterna]]: linterna y aceite.
- [[Inventario y peso]]: toma de las dos grillas.
- [[Pueblo]]: la mesa vive ahí.

## Pilar que refuerza
- Orgullo por el botín: lo raro que encontrás se convierte en *tu* herramienta.

## Código
`scripts/crafting.gd` · `data/recipe_data.gd` · `data/recipes/` · `scenes/ui/crafting_ui.gd`.

## Ideas y pendientes
- **Se siente básico** (playtest). Propuesta 0.2: [[Rasgos raros]] que se heredan al fabricar.
- Más adelante, si hace falta: minijuego de forja que suba la calidad.
