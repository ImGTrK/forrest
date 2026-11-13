---
tipo: mecánica
estado: hecho
version: 0.1
hito: 6
---
# Noche y linterna

> De noche el bosque se cierra a tu alrededor; la linterna devuelve visión a cambio de aceite.

## Cómo funciona
- Solo en el bosque. Se cierra de 18 a 21 h, noche cerrada hasta las 3, se abre hasta las 5.
- Sin luz se ve un círculo de ~2 tiles.
- **Linterna** (equipo, nunca se pierde): 2 piedra + 1 madera. Radio 80-130 px según la pureza de la piedra. L prende/apaga; se apaga sola en el pueblo.
- **Aceite** (consumible, sí se pierde): 2 madera. 90-180 min de juego según la densidad de la madera. Se gasta primero el frasco más vacío.

## Se conecta con
- [[Reloj]]: la hora define la oscuridad.
- [[Crafting]]: linterna y aceite se fabrican.
- [[Herramientas y durabilidad]]: la linterna es equipo.
- [[Enemigos]]: de noche hay más y son más duros.
- [[Fin del run]]: el aceite se pierde como cualquier recurso.

## Pilar que refuerza
- Decidir cuándo volver: la noche hace visible la dificultad.

## Código
`scenes/main.gd` (`vision_radius`) · `scenes/world/night.gdshader` · `autoload/game_state.gd` (linterna y aceite).

## Ideas y pendientes
- Efecto de noche lindo: luz con degradé, parpadeo de la linterna.
