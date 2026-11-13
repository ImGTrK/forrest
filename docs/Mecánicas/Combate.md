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

## Se conecta con
- [[Enemigos]]: contra quién.
- [[Herramientas y durabilidad]]: la espada define el daño y se gasta al pegar.
- [[Energía y sueño]]: golpes y dash cuestan energía; agotado, golpes más lentos.
- [[Fin del run]]: vida en 0 = muerte.
- [[Mejoras permanentes]]: +1 corazón.

## Números
[[BALANCE]] § Combate.

## Código
`scenes/player/player.gd` · `scripts/health.gd`.

## Ideas y pendientes
- **0.2 (hito 10):** feedback (números de daño, flash, sacudida de cámara, barra de vida del enemigo, sonidos) y animaciones de ataque y dash.
