---
tipo: mecánica
estado: hecho
version: 0.1
hito: 7
---
# Guardado

> La partida se guarda sola en el pueblo; el bosque nunca se guarda.

## Cómo funciona
- JSON en `user://save.json` (Windows: `%APPDATA%/Godot/app_userdata/Forrest/`).
- Guarda: mochila y almacén (posición, rotación, ADN, calidad, durabilidad), mejoras, runs, misiones, hora, energía y vida.
- **Cuándo:** al llegar al pueblo, al terminar de dormir/colapsar/morir, al cerrar o salir al menú **estando en el pueblo**.
- Cerrar en el bosque = volver al último guardado (el run se pierde). Evita usar "salir" para zafar de un peligro.
- Menú principal: Continuar / Nueva partida (con confirmación) / Salir. Pausa con Esc.

## Se conecta con
- [[Pueblo]]: solo se guarda ahí.
- [[Fin del run]]: autoguardado al terminar.

## Código
`autoload/save_system.gd` · `scenes/ui/main_menu.gd`, `pause_menu.gd`.

## Ideas y pendientes
- **0.2 (hito 8):** versionar el guardado para que una actualización no rompa partidas viejas (importante al pasarle el `.exe` a amigos).
