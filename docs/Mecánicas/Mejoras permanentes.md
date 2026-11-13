---
tipo: mecánica
estado: hecho
version: 0.1
hito: 6
---
# Mejoras permanentes

> La meta-progresión actual: cada misión cumplida te hace un poco más capaz para siempre.

## Cómo funciona
- Al reclamar una misión se aplica una mejora al azar:
  - **+2 kg** de capacidad.
  - **+10** de energía máxima.
  - **+1 corazón** (+2 de vida).
- Se guardan con la partida.

## Se conecta con
- [[Tablón de misiones]]: de donde salen.
- [[Inventario y peso]], [[Energía y sueño]], [[Combate]]: lo que mejoran.

## Pilar que refuerza
- Ganas de volver ya · la fantasía de que el bosque se vuelve manejable **por tu mejora**.

## Números
[[BALANCE]] § Misiones.

## Código
`autoload/game_state.gd` (`apply_upgrade`).

## Ideas y pendientes
- Son pocas y al azar: probablemente parte del problema de [[Motor para volver al bosque]].
- Ramas de experiencia como progresión elegida: [[Ideas para la 0.3]].
