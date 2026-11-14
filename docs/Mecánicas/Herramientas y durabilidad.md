---
tipo: mecánica
estado: hecho
version: 0.1
hito: 5
---
# Herramientas y durabilidad

> Hachas, picos y espadas fabricados con materiales con ADN, que se gastan y se reparan.

## Cómo funciona
- Tipos: hacha, pico, espada y linterna. Nivel 1 (piedra/madera), nivel 2 (cobre) y nivel 3 (hierro).
- Pueden tener hasta 2 [[Rasgos raros|rasgos]] heredados de los materiales; reparar los conserva.
- **Sin slots:** se usa sola la mejor herramienta de la mochila (mayor nivel, después más poder). Cargarla cuesta lugar y peso.
- **Durabilidad:** 1 por golpe (herramienta) o por golpe que conecta (arma). Buena >60% · Desgastada 20-60% · Rota 0%: rota no sirve (como a mano) hasta repararla.
- **Reparar** en la mesa: queda como nueva y consume 1 material (el peor) de su material principal.
- El HUD muestra hacha, pico, arma y linterna con su durabilidad.

## Se conecta con
- [[Crafting]]: de donde salen y donde se reparan.
- [[Recolección]]: poder y nivel requerido.
- [[Combate]]: la espada define el daño.
- [[Noche y linterna]]: la linterna es equipo.
- [[Inventario y peso]]: ocupan la mochila.
- [[Fin del run]]: el equipo nunca se pierde.

## Código
`data/items/*_axe.tres`, `*_pickaxe.tres`, `*_sword.tres` · `autoload/game_state.gd` (`best_tool`, `wear`) · `scripts/item_instance.gd`.

## Ideas y pendientes
- ✅ Hito 11: el pico de cobre (nivel 2) desbloquea la veta de hierro.
- Herramientas con rasgos heredados: [[Rasgos raros]].
