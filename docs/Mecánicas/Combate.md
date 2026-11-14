---
tipo: mecánica
estado: hecho
version: 0.1
hito: 3
---
# Combate

> Swing en arco y dash con invulnerabilidad, portado de BarrenRoots.

## Cómo funciona
- **Vida:** 6 (3 corazones; corazón = 2). +2 por mejora. Dormir y morir la restauran.
- **Ataque:** arco de 120°, alcance 22 px, hacia el mouse (o J hacia donde mirás). Daño = poder de la espada, o 1 con los puños. Cooldown 0.35 s (×2 agotado). Cuesta 0.4 de energía.
- **Dash:** 288 px/s por 0.15 s, i-frames, atraviesa enemigos. Cooldown 1.5 s, cuesta 0.6 de energía.
- **Daño recibido:** 0.6 s de i-frames con parpadeo y knockback.
- **Personaje por partes (hito 10):** la hoja sale de un rig (`tools/art/draw_player.gd`): quieto, caminar,
  ataque (carga, estocada, sigue, vuelve), dash (se agacha y se lanza con los brazos atrás) y muerte
  (golpe, rodillas, queda tendido). Mide ~20 px y se dibuja 1:1. Encima, el código suma un estirón al
  pegar, un aplastado al recibir y siluetas color agua en el dash. El fundido llega 0.9 s después de caer.
- **Feedback (hito 10):** número de daño, destello blanco, freno de golpe de ~3 frames, sacudida de
  cámara, partículas, barra de vida sobre el enemigo herido, astillas al recolectar y sonidos
  ([[Arquitectura]] § servicios globales).

## Se conecta con
- [[Enemigos]]: contra quién.
- [[Herramientas y durabilidad]]: la espada define el daño y se gasta al pegar.
- [[Energía y sueño]]: golpes y dash cuestan energía; agotado, golpes más lentos.
- [[Fin del run]]: vida en 0 = muerte.
- [[Mejoras permanentes]]: +1 corazón.

## Números
[[BALANCE]] § Combate.

## Código
`scenes/player/player.gd` · `scripts/health.gd` · `autoload/fx.gd` · `autoload/audio_manager.gd`.

## Ideas y pendientes
- ✅ **Hito 10:** feedback y animaciones.
- Sonidos reales en vez de los sintetizados: `assets/audio/sfx/<id>.wav` (guía §9.2).
