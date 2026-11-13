---
tipo: mecánica
estado: hecho
version: 0.1
hito: 1
---
# Pueblo

> El hub fijo y persistente: el único lugar seguro, donde se guarda, se fabrica, se duerme y se planea la próxima salida.

## Cómo funciona
- Mapa hecho a mano (hoy en ASCII dentro de `hub.gd`), siempre igual. No hay noche visual: está iluminado.
- Contiene: almacén (cofre), mesa de trabajo, cama, tablón y la salida al bosque.
- **Pisar el pueblo resetea el bosque**: la próxima salida es un bosque nuevo.
- Llegar al pueblo autoguarda.

## Se conecta con
- [[Bosque procedural]]: salir del pueblo arranca un run; volver lo termina y resetea el bosque.
- [[Inventario y peso]]: el almacén vive acá, al lado de la mochila.
- [[Crafting]]: la mesa de trabajo.
- [[Energía y sueño]]: la cama es el único lugar para dormir.
- [[Tablón de misiones]]: cerca de la salida.
- [[Guardado]]: solo se guarda estando acá.

## Código
`scenes/world/hub.gd` · props en `scenes/entities/` (chest, bed, bench, board) · cambio de área en `scenes/main.gd`.

## Ideas y pendientes
- Pintar el pueblo en el editor en vez de ASCII.
- Decoración (cerca, farol, pozo, portón de salida): ver [[GUIA_ARTE_Y_SONIDO]] §2.2.
- Un pueblo que **crece visiblemente** con el progreso: candidato en [[Motor para volver al bosque]].
