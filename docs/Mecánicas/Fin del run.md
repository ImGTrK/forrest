---
tipo: mecánica
estado: hecho
version: 0.1
hito: 3
---
# Fin del run

> Tres formas de volver al pueblo, con castigos escalonados.

## Cómo funciona
| Forma | Consecuencia |
|---|---|
| Volver por decisión propia | Sin pérdida |
| **Colapso** (energía 0) | Pierde 25% de lo cargado, vuelve al pueblo y **duerme a la fuerza** |
| **Muerte** (vida 0) | Pierde 50% de lo cargado, vuelve con vida llena. No duerme |

- El **equipo nunca se pierde** (herramientas, armas, linterna). El aceite sí, es consumible.
- Lo que no se pierde queda en la mochila: guardarlo en el almacén es decisión del jugador.

## Se conecta con
- [[Energía y sueño]]: colapso.
- [[Combate]]: muerte.
- [[Inventario y peso]]: qué se pierde.
- [[Pueblo]]: siempre se vuelve ahí.
- [[Guardado]]: se autoguarda al terminar.

## Pilar que refuerza
- Decidir cuándo volver: el riesgo tiene dientes, pero el colapso es una "muerte suave".

## Números
[[BALANCE]] § Pérdidas y mochila.

## Código
`scenes/main.gd` (`_return_to_hub`, `_on_collapsed`, `_on_player_died`) · `autoload/game_state.gd` (`lose_run_fraction`).
