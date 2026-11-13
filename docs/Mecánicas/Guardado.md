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
- ✅ **Hito 8:** versionado. Formato 2 (`version` + `game_version`); los guardados de la 0.1 se migran solos;
  uno de una versión más nueva no se carga y el menú explica por qué. Cambiar el formato = subir `VERSION` y
  agregar `_migrate_N` en `autoload/save_system.gd`.
